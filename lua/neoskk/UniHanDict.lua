local CompletionItem = require "neoskk.CompletionItem"
local util = require "neoskk.util"
local kana_util = require "neoskk.kana_util"
local pinyin = require "neoskk.pinyin"
local GuangYun = require "neoskk.GuangYun"
local NUM_BASE = tonumber("2460", 16) - 1
local utf8 = require "neoskk.utf8"
local ZhuyinMachine = require "neoskk.ZhuyinMachine"

--- 読
---@class UniHanReading
---@field pinyin string pinyin
---@field zhuyin string? 注音符号
---@field diao integer? 四声

--- 反切
---@class Fanqie
---@field koe string 聲紐
---@field moku string 韻目
---@field roma string Polyhedron擬羅馬字

--- 支那漢
---@class ChinaKan
---@field kana string[] よみかな

--- 學生字典
---@class XueShengSection
---@field header string
---@field body string

---@class Yin
---@field fanqie string? 反切
---@field zhi string? 直音
---@field roma string? roma
---@field deng string? 声調

--- 単漢字
---@class UniHanChar
---@field annotation string?
---@field goma string? 四角号碼
---@field xszd XueShengSection[]? 學生字典
---@field readings UniHanReading[] 読み
---@field yin Yin[] 反切と声調
---@field kana string[] よみかな
---@field flag "joyo" | nil
---@field indices string? 康煕字典
---@field ref string[]? 異字体

-- # SKK https://github.com/skk-dev/dict
--   UniHanDict:load_skk
-- # Unicode Han Database
--   https://www.unicode.org/reports/tr38/
--   https://github.com/unicode-org/unihan-database
-- # 學生字典
--   UniHanDict:load_xszd
-- # 康煕字典
--   UniHanDict:load_kangxi
-- # 支那漢
--   UniHanDict:load_chinadat
-- # 廣韻
--   UniHanDict:load_quangyun
---@class UniHanDict
---@field map table<string, UniHanChar> 単漢字辞書
---@field jisyo table<string, CompletionItem[]> SKK辞書
---@field simple_map table<string, string> 簡体字マップ
---@field zhuyin_map table<string, string[]> 注音辞書
---@field guangyun GuangYun 廣韻
---@field unihan_like_file string?
---@field unihan_reading_file string?
---@field unihan_variants_file string?
---@field uangyun_file string?
---@field chinadat_file string?
---@field kyu_file string?
---@field xszd_file string?
---@field skk_L string?
local UniHanDict = {}
UniHanDict.__index = UniHanDict

---@return UniHanDict
function UniHanDict.new()
  local self = setmetatable({
    map = {},
    jisyo = {},
    simple_map = {},
    zhuyin_map = {},
    guangyun = GuangYun.new(),
  }, UniHanDict)
  return self
end

function UniHanDict.resetmetatable(self)
  setmetatable(self, UniHanDict)
  GuangYun.resetmetatable(self.guangyun)
end

---単漢字登録
---@param char string 漢字
---@return UniHanChar
function UniHanDict:get_or_create(char)
  local i
  for _i in utf8.codes(char) do
    i = _i
  end
  assert(i == 1, "multiple codepoint :" .. char)

  ---@type UniHanChar?
  local item = self.map[char]
  if not item then
    -- if utf8.len ~= 1 then
    --   return
    -- end
    item = {
      yin = {},
      kana = {},
      readings = {},
    }
    self.map[char] = item
  end
  return item
end

--- completion item の menu 文字列を作る
---@param ch string
---@param item UniHanChar
---@return string
function UniHanDict:get_label(ch, item)
  local label = ""
  local traditional = self.simple_map[ch]
  assert(traditional ~= ch)
  if traditional then
    label = ">" .. traditional
    local ref = self.map[traditional]
    if ref and ref.goma then
      label = label .. ":" .. ref.goma
    end
  elseif item.ref then
    label = ">" .. util.join(item.ref)
    local ref = self.map[item.ref]
    if ref and ref.goma then
      label = label .. ":" .. ref.goma
    end
  elseif item.indices then
    label = "[康煕]"
  end
  if item.xszd then
    label = label .. "+"
  end
  return label
end

---@class UserDictItem
---@field kana string[]
---@field annotation string?

---User辞書
---@param json table<string, UserDictItem>
function UniHanDict:load_user(json)
  for word, v in pairs(json) do
    local last_pos = 1
    for i in utf8.codes(word) do
      last_pos = i
    end
    if last_pos == 1 then
      assert(false, "todo")
    else
      for _, kana in ipairs(v.kana) do
        self:add_word(word, kana, "[USER]", v.annotation)
      end
    end
  end
end

local function code_count(body)
  local n = 0
  for _ in utf8.codes(body) do
    n = n + 1
  end
  return n
end

-- 學生字典(XueShengZiDian)
-- **一
-- -衣悉切(I)入聲
-- --數之始也。凡物單個皆曰一。
-- --同也。（中庸）及其成功一也。
-- --統括之詞。如一切、一概。
-- --或然之詞。如萬一、一旦。
-- --專也。如一味、一意。
-- **些
-- -西遮切(Sieh)平聲或讀若徙
-- --少也。俗亦謂之些須。
-- -四餓切(So)去聲
-- --語助詞。楚辭招魂末多用之。故曰楚些。哀輓語也。
---@param data string xszd.txt
---@param path string?
function UniHanDict:load_xszd(data, path)
  self.xszd_file = path
  ---@type {item: UniHanChar?, i: integer}
  local current = {
    item = nil,
    i = 0,
  }
  ---@param yin Yin
  local function add_yin(yin)
    local item = current.item
    assert(item)
    table.insert(item.yin, current.i, yin)
    current.i = current.i + 1
  end

  for l in string.gmatch(data, "[^\n]+") do
    local header, body = l:match "^([%*-]+)(.*)"
    if header == "*" then
      -- skip
    elseif header == "**" then
      current.item = nil
      current.i = 1

      local n = code_count(body)
      if n == 1 then
        local item = self:get_or_create(body)
        item.xszd = {}
        current.item = item
      end
    elseif header == "***" then
      -- skip
    elseif header == "-" then
      if current.item then
        -- TODO
        table.insert(current.item.xszd, { header = body, body = "" })

        if body:match "^［解字］" then
        else
          local list = {}
          for _, ch in utf8.codes(body) do
            table.insert(list, ch)
          end
          if list[1] == "讀" and list[2] == "如" then
            -- 讀如音(Yin)上聲
            add_yin { zhi = list[3] }
          elseif list[1] == "音" then
            -- 音菊(Chu)入聲
            add_yin { zhi = list[2] }
          elseif list[3] == "切" then
            -- 則思切(Tzu)平聲
            add_yin { fanqie = list[1] .. list[2] }
          elseif list[1] == "讀" and list[2] == "若" then
            -- 讀若如(Ju)上聲
            add_yin { zhi = list[3] }
          elseif list[1] == "與" and list[3] == "同" then
            -- 與阨同
            add_yin { zhi = list[2] }
          elseif list[1] == "古" then
            -- 古原字
          elseif list[1] == "俗" then
            -- 俗效字
          elseif list[1] == "本" then
            -- 本音覃
          else
            -- print(l)
          end
        end
      end
    elseif header == "--" then
      if current.item then
        if #current.item.xszd == 0 then
          table.insert(current.item.xszd, { header = body, body = "" })
        else
          current.item.xszd[#current.item.xszd].body = current.item.xszd[#current.item.xszd].body .. body
        end
      end
    else
      assert(false, l)
    end
  end
end

---SKK辞書
---@param data string
---@param path string?
function UniHanDict:load_skk(data, path)
  if path and not self.skk_L then
    self.skk_L = path
  end
  ---@param l string
  ---@return string? key
  ---@return string? body
  local function parse_line(l)
    if vim.startswith(l, ";") then
      return
    end

    local s, e = l:find "%s+/"
    if s and e then
      return l:sub(1, s - 1), l:sub(e)
    end
  end

  for _, l in ipairs(vim.split(data, "\n")) do
    local kana, values = parse_line(l)

    if kana and values then
      for word in values:gmatch "[^/]+" do
        if word:match "^[a-zA-Z][a-zA-Z]" and word:sub(1, 1) == word:sub(2, 2) then
          --skip
        else
          -- annotation を 分離
          local annotation_index = word:find(";", nil, true)
          local annotation = ""
          if annotation_index then
            annotation = word:sub(annotation_index + 1)
            word = word:sub(1, annotation_index - 1)
          end

          -- 文字数判定
          local last_pos = 0
          for i in utf8.codes(word) do
            last_pos = i
          end

          if last_pos == 1 then
            -- 単漢字
            local item = self.map[word]
            if item then
              item.annotation = annotation
              table.insert(item.kana, kana)
            end
          else
            if word:match "^%w+$" then
              -- skip
            else
              -- 単語
              self:add_word(word, kana, "[単語]", annotation)
            end
          end
        end
      end
    end
  end
end

---単語登録
---@param kana string
---@param word string
---@param menu string?
---@param annotation string?
function UniHanDict:add_word(word, kana, menu, annotation)
  local items = self.jisyo[kana]
  if not items then
    items = {}
    self.jisyo[kana] = items
  end
  for _, item in ipairs(items) do
    if item.word == word then
      -- 重複
      return
    end
  end

  local new_item = CompletionItem.from_word(word, nil, self)
  if menu then
    new_item.menu = menu
  end
  if annotation then
    new_item.abbr = new_item.abbr .. " " .. annotation
  end
  table.insert(items, new_item)
end

---康煕字典
---含まれていない字は新しい字である可能性。
---新字体、簡体字 etc
---@param data string kx2ucs.txt
function UniHanDict:load_kangxi(data)
  -- KX0075.001	一
  for kx, chs in string.gmatch(data, "(KX%d%d%d%d%.%d%d%d)\t([^%*%s]+)") do
    for _, ch in utf8.codes(chs) do
      local item = self:get_or_create(ch)
      assert(item)
      item.indices = kx

      -- 簡体字
      local t = self.simple_map[ch]
      if t then
        -- print(t, ch)
        ch = t
      end
      item = self:get_or_create(ch)
      assert(item)
      item.indices = kx

      -- use only first codepoint
      break
    end
  end
end

-- unicode
--
-- https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
-- Unihan_DictionaryIndices.txt
-- Unihan_IRGSources.txt
-- Unihan_NumericValues.txt
-- Unihan_RadicalStrokeCounts.txt
-- local data = readFileSync(path)
-- local data = readFileSync(path)

UniHanDict.UNIHAN_PATTERN = "U%+([A-F0-9]+)\t(k%w+)\t([^\n]+)\n"

---@param data string Unihan_DictionaryLikeData.txt
---@param path string?
function UniHanDict:load_unihan_likedata(data, path)
  self.unihan_like_file = path
  -- U+5650	kFourCornerCode	6666.1
  for unicode, k, v in string.gmatch(data, UniHanDict.UNIHAN_PATTERN) do
    local codepoint = tonumber(unicode, 16)
    local ch = utf8.char(codepoint)
    local item = self:get_or_create(ch)
    -- assert(item)
    if k == "kFourCornerCode" then
      item.goma = v
    end
  end
end

---@param data string Unihan_Readings.txt
---@param path string?
function UniHanDict:load_unihan_readings(data, path)
  self.unihan_reading_file = path
  -- U+3401	kFanqie	他紺 他念
  -- U+6570	kJapanese	スウ ス ショ サク ソク ショク シュク かず かぞえる しばしば せめる
  -- U+6570	kJapaneseKun	KAZOERU KAZU SEMERU
  -- U+6570	kJapaneseOn	SUU SHU SU
  -- U+6570	kMandarin	shù
  --通用规范汉字字典
  -- U+6570	kTGHZ2013	342.010:shǔ 342.160:shù 345.150:shuò
  --现代汉语词典
  -- U+6570	kXHC1983	1066.040:shǔ 1069.050:shù 1083.010:shuò
  for unicode, k, v in string.gmatch(data, UniHanDict.UNIHAN_PATTERN) do
    local codepoint = tonumber(unicode, 16)
    local ch = utf8.char(codepoint)
    local item = self:get_or_create(ch)
    if k == "kMandarin" then
      for _, r in util.split, { v, "%s+" } do
        local zhuyin, diao = pinyin:to_zhuyin(r)
        if zhuyin then
          local list = self.zhuyin_map[zhuyin]
          if not list then
            list = {}
            self.zhuyin_map[zhuyin] = list
          end
          table.insert(list, ch)
        else
          -- print("no zhuyin", r)
        end
        table.insert(item.readings, {
          pinyin = r,
          zhuyin = zhuyin,
          diao = diao,
        })
      end
    elseif k == "kFanqie" then
      for s in util.split, { v, "%s" } do
        table.insert(item.yin, {
          fanqie = s,
        })
      end
    elseif k == "kJapanese" then
      item.kana = util.splited(v)
    end
  end
end

-- function UniHanDict:load_unihan_indices(path)
--   local data = readFileSync(path)
--   if data then
--     -- 新字体とか最近の文字も含まれてたー
--     -- U+3400	kKangXi	0078.010
--     for unicode, k, v in string.gmatch(data, UniHanDict.UNIHAN_PATTERN) do
--       local codepoint = tonumber(unicode, 16)
--       local ch = utf8.char(codepoint)
--       local item = self:get_or_create(ch)
--       assert(item)
--       if k == "kKangXi" then
--         print(v)
--         item.indices = v
--         break
--       end
--     end
--   end
-- end

---@param data string Unihan_Variants.txt
---@param path string?
function UniHanDict:load_unihan_variants(data, path)
  self.unihan_variants_file = path
  -- U+346E	kSimplifiedVariant	U+2B748
  for unicode, k, v in string.gmatch(data, UniHanDict.UNIHAN_PATTERN) do
    local codepoint = tonumber(unicode, 16)
    local ch = utf8.char(codepoint)
    if k == "kSimplifiedVariant" then
      local v_codepoint = tonumber(v, 16)
      local v_ch = utf8.char(v_codepoint)
      -- local s_codepoint = tonumber(src, 16)
      -- local s_ch = utf8.char(s_codepoint)
      if ch ~= v_ch then
        self.simple_map[v_ch] = ch
      end
    end
  end
end

-- Unihan_OtherMappings.txt
-- # This file contains data on the following fields from the Unihan database:
-- #	kBigFive
-- #	kCCCII
-- #	kCNS1986
-- #	kCNS1992
-- #	kEACC
-- #	kGB0
-- #	kGB1
-- #	kGB3
-- #	kGB5
-- #	kGB7
-- #	kGB8
-- #	kIBMJapan
-- #	kJa
-- #	kJinmeiyoKanji
-- #	kJis0
-- #	kJis1
-- #	kJIS0213
-- #	kJoyoKanji
-- #	kKoreanEducationHanja
-- #	kKoreanName
-- #	kMainlandTelegraph
-- #	kPseudoGB1
-- #	kTaiwanTelegraph
-- #	kTGH
-- #	kXerox
---@param data string Unihan_OtherMappings.txt
function UniHanDict:load_unihan_othermappings(data)
  for unicode, k, _ in string.gmatch(data, UniHanDict.UNIHAN_PATTERN) do
    local codepoint = tonumber(unicode, 16)
    local ch = utf8.char(codepoint)
    local item = self:get_or_create(ch)
    assert(item)
    if k == "kJoyoKanji" then
      item.flag = "joyo"
    end
  end
end

--- filter
--- - 常用漢字
--- - 學生字典
--- - not 英単語
---@param key string
---@return CompletionItem[]
function UniHanDict:filter_jisyo(key)
  local items = {}
  -- 単語
  for k, v in pairs(self.jisyo) do
    if k == key then
      for _, item in ipairs(v) do
        local new_item = CompletionItem.copy(item)
        table.insert(items, new_item)
      end
    end
  end

  -- 単漢字
  key = kana_util.str_to_hirakana(key)
  for k, item in pairs(self.map) do
    if item.flag == "joyo" or item.xszd then
      if item.indices or item.yin or item.xszd or item.annotation then
        for _, kana in ipairs(item.kana) do
          if kana_util.str_to_hirakana(kana) == key then
            local new_item = CompletionItem.from_word(k, item, self)

            -- debug
            -- new_item.abbr = ("%d:").format(utf8.codepoint(new_item.word)) .. new_item.abbr

            table.insert(items, new_item)
            break
          end
        end
      end
    end
  end

  -- TODO 韻、聲
  -- TODO 韻目
  table.sort(items, function(a, b)
    return utf8.codepoint(a.word) < utf8.codepoint(b.word)
  end)

  return items
end

---支那漢
--01: 文字……Unicodeに存在しないものは大漢和辞典コードを5桁(5桁に満たないものは頭に0をつけて必ず5桁にしています)で記しています。(1)、(2)などの印がある場合は区切り文字なしにそのまま後につけています。
--02: 参照文字……簡体字や日本新字の元の字、支那漢本文で参照されている字など、青矢印()で表示されるリンクの字です。Unicodeにないものの扱いは上記「文字」同様です。複数ある場合は区切り文字なしに列挙しています。
--03: 支那漢のページ
--04: 参照文字のページ……上記「参照文字」のページです。ページ数は必ず3桁であり、3桁に満たない場合は頭に0をつけています。また前々項の参照文字が複数ある場合は参照文字の順にページを区切りなしに列挙しています。
--05: 部首コード……部首をコードであらわしています。そのコードの意味は下の「部首コード表ダウンロード」で部首コード表ファイルをダウンロードして参照ください。
-- 部首コード表ファイルはUnicodeのCSVファイルで、書式は「部首コード, 部首文字, 画数, 元部首コード,」です。行末にもカンマがついていることに注意してください。「元部首」というのはたとえば「氵」に対する「水」のようなものです。
--06: 部首内画数
--07: 総画数
--08: 四角号碼……先頭と末尾に区切り文字としての'+'をつけています。コード化の変種がある場合は「+コード1+コード2」のように間に'+'をはさみながら列挙していますが、一番左のものが当サイトで正式と認めているものです。各コードは必ず5桁です。
-- ※四角号碼の変種の入力は現在進行中です。 よってこの記述が消えるまでは、変種の入力は完全ではありません。
--09: ピンイン……先頭に区切り文字としての'/'をつけています(末尾にはついていません)。複数の音がある場合は、「/音1/音2/音3」のように間に'/'をはさみながら列挙しています。また新華字典に存在する発音はおしまいに'*'をつけています。
-- ※新華字典による校正は現在進行中です。 よってこの記述が消えるまでは、上記'*'印の入力は完全ではありません。
--10: 日本語音訓……音はカタカナ、訓はひらがなであり、前後に区切り文字としての'1'をつけてあります。旧仮名・新仮名の関係は「1ケフ1(1キョウ1)」などのように記しています。
---@param data string chinadat.csv
---@param path string?
function UniHanDict:load_chinadat(data, path)
  self.chinadat_file = path
  -- 亜,亞,,009,7,5,7,+10106+,/ya3/ya4*,1ア1つぐ1,
  -- 伝(1),傳,,026,9,4,6,+21231+,/chuan2,1テン1デン1つたふ1(1つたう1)1つたへる1(1つたえる1)1つたはる1(1つたわる1)1つて1,
  -- 余(1),,017,,9,5,7,+80904+,/yu2,1ヨ1われ1,
  -- 余(2),餘,017,621,9,5,7,+80904+,/yu2,1ヨ1あまる1あます1われ1あまり1のこる1,
  for line in string.gmatch(data, "([^\n]+)\r\n") do
    local cols = util.splited(line, ",")

    -- TODO
    local ch = cols[1]
    local s, e = ch:find "%(%d+%)"
    if s then
      if ch:sub(s + 1, e - 1) == "1" then
        ch = ch:sub(1, s - 1)
      else
        ch = nil
      end
    end

    if ch and not ch:find "^%w+$" then
      if #cols[2] > 0 then
        self:add_ref(ch, cols[2])
      end

      local item = self:get_or_create(ch)
      assert(item)
      if #cols[10] > 0 then
        local _kana = util.splited(cols[10], "1")
        item.kana = {}
        for i = #_kana, 1, -1 do
          local kana = _kana[i]
          if #kana == 0 then
          elseif kana == "(" then
          elseif kana == ")" then
          else
            table.insert(item.kana, 1, kana)
          end
        end
      end
    end
  end
end

function UniHanDict:add_ref(ch, ref)
  local item = self:get_or_create(ch)
  assert(item)
  local list = item.ref
  if not list then
    list = {}
    item.ref = list
  end
  table.insert(list, ref)
end

---廣韻
---@param data string Kuankhiunn0704-semicolon.txt
---@param path string?
function UniHanDict:load_quangyun(data, path)
  self.guangyun_file = path
  self.guangyun:load(data)
end

---@param ch string
---@return XiaoYun[]
function UniHanDict:get_xiaoyun(ch)
  local list = {}
  local item = self.map[ch]
  if item and item.yin then
    for _, yin in ipairs(item.yin) do
      local fanqie = yin.fanqie
      if fanqie then
        local xiao = self.guangyun:xiaoyun_from_fanqie(fanqie)
        if xiao then
          table.insert(list, xiao)
        end
      end
    end
  end
  if #list > 0 then
    return list
  end

  local xiao = self.guangyun:xiaoyun_from_char(ch)
  if xiao then
    return { xiao }
  end

  return {}
end

---@param ch string
---@return string[]?
function UniHanDict:hover(ch)
  local item = self.map[ch]
  if item then
    local cp = utf8.codepoint(ch)
    local lines = { "# " .. ch }
    if item.ref then
      table.insert(lines, "参照 => " .. util.join(item.ref, ","))
    end
    if item.goma then
      table.insert(lines, ("UNICODE: U+%X, 四角号碼: %s"):format(cp, item.goma))
    end
    if item.annotation and #item.annotation > 0 then
      table.insert(lines, "備考: " .. item.annotation)
    end
    table.insert(lines, "")

    table.insert(lines, "# 読み")
    if #item.kana > 0 then
      -- table.insert(lines, util.join(item.kana, ","))
      table.insert(lines, item.kana[1])
    end
    for _, r in ipairs(item.readings) do
      table.insert(lines, r.zhuyin .. (r.diao and ("%d"):format(r.diao) or ""))
    end
    table.insert(lines, "")

    local xiaoyuns = self:get_xiaoyun(ch)
    local xiaoyun_hover
    local xiaoyun
    if #xiaoyuns > 0 then
      xiaoyun_hover, xiaoyun = self.guangyun:hover(xiaoyuns)
    end

    if xiaoyun_hover and xiaoyun then
      table.insert(
        lines,
        ("# 廣韻 %s, 小韻 %s, %s切%s声 %s口%s等 %s"):format(
          xiaoyun.name,
          xiaoyun.chars[1],
          xiaoyun.fanqie,
          xiaoyun.diao,
          xiaoyun.huo,
          xiaoyun.deng,
          xiaoyun.roma
        )
      )
      table.insert(lines, "")

      util.insert_all(lines, xiaoyun_hover)

      local function make_x(i)
        local x = xiaoyun.chars[i]
        if x then
          local n = utf8.char(NUM_BASE + i) .. " "
          local y = self.map[x]
          if y and #y.readings > 0 then
            local r = y.readings[1]
            return ("%s%s %s%s %s"):format(n, x, r.zhuyin, r.diao or "", y.kana[1])
          else
            return n .. x
          end
        end
      end

      -- 字例
      table.insert(lines, ("## %d字"):format(#xiaoyun.chars))
      for i = 1, #xiaoyun.chars, 4 do
        local x1 = make_x(i)
        local x2 = make_x(i + 1)
        local x3 = make_x(i + 2)
        local x4 = make_x(i + 3)
        if x1 and x2 and x3 and x4 then
          table.insert(lines, "|" .. x1 .. "|" .. x2 .. "|" .. x3 .. "|" .. x4)
        elseif x1 and x2 and x3 then
          table.insert(lines, "|" .. x1 .. "|" .. x2 .. "|" .. x3)
        elseif x1 and x2 then
          table.insert(lines, "|" .. x1 .. "|" .. x2)
        elseif x1 then
          table.insert(lines, "|" .. x1)
        end
      end
      table.insert(lines, "")
    else
      if #xiaoyuns > 0 then
        for _, x in ipairs(xiaoyuns) do
          table.insert(lines, "小韻: " .. x.name .. ", 聲紐:" .. x.shengniu)
        end
      else
        table.insert(lines, ("xiaoyun for %s not found"):format(ch))
      end
      local line = ""
      for _, yin in ipairs(item.yin) do
        local f = yin.fanqie
        if #line > 0 then
          line = line .. ","
        end
        line = line .. f .. "切"
      end
      table.insert(lines, line)
      table.insert(lines, "")
    end

    if item.xszd then
      table.insert(lines, "# 學生字典")
      for _, x in ipairs(item.xszd) do
        table.insert(lines, "## " .. x.header)
        for _, l in util.split, { x.body, "\n" } do
          table.insert(lines, l)
        end
      end
    end
    return lines
  end
end

---旧字体
-- # 常用漢字表-旧字体
-- # 汉字共366组
-- # （〔〕/［］内为旧字体或异体字）
--
-- 亜〔亞〕
-- 悪〔惡〕
function UniHanDict:load_kyu(data, path)
  self.kyu_file = path
  for l in string.gmatch(data, "[^\n]*\n") do
    local list = {}
    for _, ch in utf8.codes(l) do
      table.insert(list, ch)
    end
    if #list == 4 then
      if list[2] == "〔" and list[4] == "〕" then
        self:add_ref(list[1], list[3])
      end
    end
  end
end

---@param key string
---@param range lsp.Range?
---@return lsp.CompletionItem[]
function UniHanDict:get_cmp_entries(key, range)
  if key:match "^(%d+)$" then
    return self:_get_cmp_entries_goma(key, range)
  else
    return self:_get_cmp_entries_kana(key, range)
  end
end

---四角号碼
---@param key string
---@param range lsp.Range?
---@return lsp.CompletionItem[]
function UniHanDict:_get_cmp_entries_goma(key, range)
  ---@type lsp.CompletionItem[]
  local items = {}

  for ch, item in pairs(self.map) do
    if item.goma and item.goma:match(key) then
      local lsp_item = {
        label = ch .. " " .. item.goma,
        -- documentation = item.info,
        filterText = "▽" .. key,
        textEdit = {
          newText = ch,
          range = range,
        },
      }
      table.insert(items, lsp_item)
    end
  end

  if #items == 0 then
    table.insert(items, {
      label = "[no entry]",
      filterText = "▽" .. key,
      text = "",
    })
  else
    table.sort(items, function(l, r)
      return l.label < r.label
    end)
  end

  return items
end

local okuri_map = {
  ["い"] = "i",
  ["う"] = "i",
  ["え"] = "i",
  ["か"] = "k",
  ["き"] = "k",
  ["く"] = "k",
  ["け"] = "k",
  ["こ"] = "k",
  ["げ"] = "g",
  ["さ"] = "s",
  ["し"] = "s",
  ["す"] = "s",
  ["せ"] = "s",
  ["そ"] = "s",
  ["た"] = "s",
  ["ち"] = "s",
  ["つ"] = "s",
  ["て"] = "s",
  ["と"] = "s",
  ["な"] = "n",
  ["に"] = "n",
  ["ぬ"] = "n",
  ["ね"] = "n",
  ["の"] = "n",
  ["べ"] = "b",
}

---@return string
---@return string? okuri
---@return string? alpha
local function split_okuri(src)
  local key = ""
  local suffix
  for _, ch in utf8.codes(src) do
    if suffix then
      suffix = suffix .. ch
    else
      if ch == "▽" then
        suffix = ""
      else
        key = key .. ch
      end
    end
  end

  if not suffix then
    return key
  end

  local hira = kana_util.kata_to_hira[suffix]
  if hira then
    suffix = hira
  end

  return key, suffix, okuri_map[suffix] or suffix
end

---@param _key string
---@param range lsp.Range?
---@return lsp.CompletionItem[]
function UniHanDict:_get_cmp_entries_kana(_key, range)
  local key, suffix, okuri = split_okuri(_key)
  local words = self:filter_jisyo(key .. (okuri and okuri or ""))

  ---@type lsp.CompletionItem[]
  local items = {}
  for _, word in ipairs(words) do
    ---@type lsp.CompletionItem
    local lsp_item = {
      label = word.abbr,
      documentation = word.info,
    }

    local text = word.word .. (suffix or "")
    if range then
      lsp_item.textEdit = {
        newText = text,
        range = range,
      }
    else
      lsp_item.insertText = text
    end

    -- nvim-cmp/lua/cmp/entry.lua:443
    -- acdept
    -- textEdit と がうまく動かない
    lsp_item.filterText = "▽" .. _key
    table.insert(items, lsp_item)
  end

  return items
end

---@param params lsp.HoverParams request params.
---@return lsp.ResponseError? err
---@return lsp.Hover? result
function UniHanDict:lsp_hover(params)
  -- 常に0でいいかも。
  local bufnr = params.textDocument.uri == "file://" and 0 or vim.uri_to_bufnr(params.textDocument.uri)
  local row = params.position.line
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, true)[1]
  if not line or #line == 0 then
    return
  end

  local character = 0
  for _, code in utf8.codes(line) do
    if character == params.position.character then
      local hover = self:hover(code)
      if hover then
        return nil, {
          contents = util.join(hover, "\n"),
        }
      else
        return nil, {
          contents = ("not found for [%s]"):format(code),
        }
      end
    end
    character = character + 1
  end

  return nil, {
    contents = ("not found for row=%d, character=%d"):format(row, params.position.character),
  }
end

---@param params lsp.CompletionParams
---@return lsp.ResponseError? err
---@return lsp.CompletionItem[]? result
function UniHanDict:lsp_completion(params)
  -- 常に0でいいかも。
  local bufnr = params.textDocument.uri == "file://" and 0 or vim.uri_to_bufnr(params.textDocument.uri)
  local row = params.position.line
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, true)[1]
  if not line then
    return
  end

  local character = 0
  -- abcdef▽****Idef
  -- marker^    ^cursor
  local after_marker_before_cursor = ""
  local mark = -1
  local zhuyin
  local first_zh
  for _, code in utf8.codes(line) do
    if character == params.position.character then
      break
    end
    if mark == -1 then
      -- user first mark
      if code == "▽" then
        mark = character
      end
    else
      after_marker_before_cursor = after_marker_before_cursor .. code
    end

    if first_zh then
      if ZhuyinMachine.map[code] then
        zhuyin = zhuyin .. code
      else
        first_zh = nil
      end
    else
      if ZhuyinMachine.map[code] then
        first_zh = character
        zhuyin = code
      end
    end

    character = character + 1
  end
  print(first_zh, zhuyin)

  if mark >= 0 then
    ---@type lsp.Range
    local range = {
      start = {
        line = row,
        character = mark,
      },
      ["end"] = {
        line = row,
        character = params.position.character,
      },
    }

    local items = self:get_cmp_entries(after_marker_before_cursor, range)
    -- print(vim.inspect(params), ("[%s]"):format(cursor_before_line), vim.inspect(items))
    if #items > 0 then
      return nil, items
    end
  elseif first_zh then
    local range = {
      start = {
        line = row,
        character = first_zh,
      },
      ["end"] = {
        line = row,
        character = params.position.character,
      },
    }

    ---@type lsp.CompletionItem[]
    local items = {}
    for k, v in pairs(self.zhuyin_map) do
      if k == zhuyin then
        for _, ch in ipairs(v) do
          local word = self:get_or_create(ch)
          local item = CompletionItem.from_word(ch, word, self)
          assert(item)
          -- local new_item = CompletionItem.from_word(ch, item, dict)
          -- new_item.word = zhuyin
          -- new_item.dup = true
          -- new_item.user_data = {
          --   replace = ch,
          -- }
          -- if item.tiao then
          --   new_item.word = new_item.word .. ("%d").format(item.tiao)
          -- end
          local lsp_item = {
            label = ch,
            documentation = item.info,
            filterText = zhuyin,
            textEdit = {
              newText = ch,
              range = range,
            },
          }
          table.insert(items, lsp_item)
        end
      end
    end

    if #items == 0 then
      table.insert(items, {
        label = "[no entry]",
        filterText = zhuyin,
        text = "",
      })
    end

    -- print(vim.inspect(params), ("[%s]"):format(cursor_before_line), vim.inspect(items))
    if #items > 0 then
      return nil, items
    end
  end
end

return UniHanDict
