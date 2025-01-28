local utf8 = require "neoskk.utf8"
local Completion = require "neoskk.Completion"
local CompletionItem = require "neoskk.CompletionItem"
local util = require "neoskk.util"
local pinyin = require "neoskk.pinyin"
local yun = require "neoskk.yun"

--- 読
---@class UniHanReading
---@field pinyin string pinyin
---@field zhuyin string? 注音符号
---@field tiao integer? 四声

--- 反切
---@class Fanqie
---@field koe string 聲紐
---@field moku string 韻目
---@field roma string Polyhedron擬羅馬字

--- 支那漢
---@class ChinaKan
---@field kana string[] よみかな

--- 単漢字
---@class UniHanChar
---@field annotation string?
---@field goma string? 四角号碼
---@field xszd string? 學生字典
---@field readings UniHanReading[] 読み
---@field fanqie [Fanqie, string][] 反切と声調
---@field kana string[] よみかな
---@field flag "joyo" | nil
---@field indices string? 康煕字典
---@field ref string? 別字参照

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
---@field fanqie_map table<string, Fanqie> 反切マップ
---@field zhuyin_map table<string, string[]> 注音辞書
local UniHanDict = {}
UniHanDict.__index = UniHanDict
---@return UniHanDict
function UniHanDict.new()
  local self = setmetatable({
    map = {},
    jisyo = {},
    simple_map = {},
    fanqie_map = {},
    zhuyin_map = {},
  }, UniHanDict)
  return self
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
      fanqie = {},
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
    label = ">" .. item.ref
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
      for i, kana in ipairs(v.kana) do
        self:add_word(word, kana, "[USER]", v.annotation)
      end
    end
  end
end

-- 學生字典(XueShengZiDian)
-- **一
-- -衣悉切(I)入聲
-- --數之始也。凡物單個皆曰一。
-- --同也。（中庸）及其成功一也。
-- --統括之詞。如一切、一概。
-- --或然之詞。如萬一、一旦。
-- --專也。如一味、一意。
---@param data string xszd.txt
function UniHanDict:load_xszd(data)
  local last_s = 0
  while last_s <= #data do
    local s = data:find("%*%*", last_s + 1)
    if s then
      if last_s > 0 then
        local codepoint = utf8.codepoint(data, last_s + 2)
        local char = utf8.char(codepoint)
        local item = self:get_or_create(char)
        if item then
          item.xszd = util.strip(data:sub(last_s, s - 1))
        end
      end
      last_s = s
    else
      -- last one
      if last_s > 0 then
        local codepoint = utf8.codepoint(data, last_s + 2)
        local char = utf8.char(codepoint)
        local item = self:get_or_create(char)
        if item then
          item.xszd = util.strip(data:sub(last_s))
        end
      end
      break
    end
  end
end

---SKK辞書
---@param data string
function UniHanDict:load_skk(data)
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
      local item = self:get_or_create(ch)
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

local UNIHAN_PATTERN = "U%+([A-F0-9]+)\t(k%w+)\t([^\n]+)\n"

---@param data string Unihan_DictionaryLikeData.txt
function UniHanDict:load_unihan_likedata(data)
  -- U+5650	kFourCornerCode	6666.1
  for unicode, k, v in string.gmatch(data, UNIHAN_PATTERN) do
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
function UniHanDict:load_unihan_readings(data)
  -- U+3401	kFanqie	他紺 他念
  -- U+6570	kJapanese	スウ ス ショ サク ソク ショク シュク かず かぞえる しばしば せめる
  -- U+6570	kJapaneseKun	KAZOERU KAZU SEMERU
  -- U+6570	kJapaneseOn	SUU SHU SU
  -- U+6570	kMandarin	shù
  --通用规范汉字字典
  -- U+6570	kTGHZ2013	342.010:shǔ 342.160:shù 345.150:shuò
  --现代汉语词典
  -- U+6570	kXHC1983	1066.040:shǔ 1069.050:shù 1083.010:shuò
  for unicode, k, v in string.gmatch(data, UNIHAN_PATTERN) do
    local codepoint = tonumber(unicode, 16)
    local ch = utf8.char(codepoint)
    local item = self:get_or_create(ch)
    if k == "kMandarin" then
      for _, r in util.split, { v, "%s+" } do
        local zhuyin, tiao = pinyin:to_zhuyin(v)
        if zhuyin then
          local list = self.zhuyin_map[zhuyin]
          if not list then
            list = {}
            self.zhuyin_map[zhuyin] = list
          end
          table.insert(list, ch)
        end
        ---@type UniHanReading
        table.insert(item.readings, {
          pinyin = r,
          zhuyin = zhuyin,
          tiao = tiao,
        })
      end
    elseif k == "kFanqie" then
      item.fanqie = util.splited(v)
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
--     for unicode, k, v in string.gmatch(data, UNIHAN_PATTERN) do
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
function UniHanDict:load_unihan_variants(data)
  -- U+346E	kSimplifiedVariant	U+2B748
  for unicode, k, v in string.gmatch(data, UNIHAN_PATTERN) do
    local codepoint = tonumber(unicode, 16)
    local ch = utf8.char(codepoint)
    local item = self:get_or_create(ch)
    -- assert(item)
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
  for unicode, k, v in string.gmatch(data, UNIHAN_PATTERN) do
    local codepoint = tonumber(unicode, 16)
    local ch = utf8.char(codepoint)
    local item = self:get_or_create(ch)
    assert(item)
    if k == "kJoyoKanji" then
      item.flag = "joyo"
    end
  end
end

---四角号碼
---@param n string %d
---@return Completion
function UniHanDict:filter_goma(n)
  --@type CompletionItem[]
  local items = {}
  for ch, item in pairs(self.map) do
    if item.goma and item.goma:match(n) then
      local new_item = CompletionItem.from_word(ch, item, self)
      new_item.word = "g" .. item.goma
      new_item.user_data = {
        replace = ch,
      }
      table.insert(items, new_item)
    end
  end
  return Completion.new(items, Completion.FUZZY_OPTS)
end

--- filter
--- - 常用漢字
--- - 學生字典
--- - not 英単語
---@param key string
---@param okuri string?
---@return CompletionItem[]
function UniHanDict:filter_jisyo(key, okuri)
  local items = {}
  -- 単語
  for k, v in pairs(self.jisyo) do
    if k == key then
      for _, item in ipairs(v) do
        local new_item = CompletionItem.copy(item)
        if okuri then
          new_item.word = new_item.word .. okuri
          new_item.menu = "[送り]"
        end
        table.insert(items, new_item)
      end
    end
  end

  -- 単漢字
  key = util.str_to_hirakana(key)
  for k, item in pairs(self.map) do
    if item.flag == "joyo" or item.xszd then
      if item.indices or item.fanqie or item.xszd or item.annotation then
        for _, kana in ipairs(item.kana) do
          if util.str_to_hirakana(kana) == key then
            local new_item = CompletionItem.from_word(k, item, self)
            if okuri then
              new_item.word = new_item.word .. okuri
              new_item.menu = "[送り]"
            end

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
function UniHanDict:load_chinadat(data)
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
      local item = self:get_or_create(ch)
      assert(item)
      if #cols[2] > 0 then
        local ref = cols[2]
        if ref:find "%d+" then
          -- 漢,18153
        else
          item.ref = cols[2]
        end
        -- print(vim.inspect(cols))
        -- break
      end
      if #cols[10] > 0 then
        local _kana = util.splited(cols[10], "1")
        item.kana = {}
        for i = #_kana, 1, -1 do
          local kana = _kana[i]
          if #kana > 0 and kana ~= "(" and kana ~= ")" then
            table.insert(item.kana, 1, kana)
          end
        end
      end
    end
  end
end

---廣韻
-- 字段(fields)由「;」分隔，内容由左至右依次爲
-- 1、舊版(unicode3.1字符集第一版)小韻總序號。缺錄:丑戾切、no=2381，烏懈切、no=2455，他德切、no=3728，盧合、no=3784四小韻。
-- 2、刊正小韻總序號
-- 3、反切
-- 4、小韻内辭目（headwords）
-- 5、小韻所收辭目數
-- 6、校驗表記
-- 7、韻目。阿拉伯數碼「X.XX」，小數點前一位爲卷號，小數點後兩位爲韻目。如「4.11暮」意爲「第四卷去聲、十一暮韻」。
-- 8、小韻在韻中的序號。如「『德紅切』『東』爲『東』韻第一小韻，『薄紅切』『蓬』爲『東』韻第三十一小韻。」古書向無頁碼，兼且版本紛紜卷帙雜沓難於取捨，故此僅錄標目序號不記頁碼。
-- 9、聲紐
-- 10、呼（開合口）
-- 11、等
-- 12、韻部（四聲劃一）
-- 13、聲調
-- 14、Polyhedron擬羅馬字
-- 15、有女同車擬羅馬字
-- 16、舊版備註
-- 17、本次復校備註
-- 18、特殊小韻韻目歸屬說明
-- 19、見於廣韻辭條中的辭目重文、取自集韻的增補和異體字、等價異形字、備考新字等
-- 20、unicode3.1未收字的準IDS（Ideographic Desciption Characters）描述：H=⿰、Z=⿱、P=⿸、E=⿳、V=某字unicode缺載之變體
-- 1;1;德紅;東菄鶇䍶𠍀倲𩜍𢘐涷蝀凍鯟𢔅崠埬𧓕䰤;17;.;1.01東;1;端;開;一;東;平;tung;tung;;;;;
---@param data string Kuankhiunn0704-semicolon.txt
function UniHanDict:load_quangyun(data)
  for line in string.gmatch(data, "([^\n]+)\n") do
    local cols = util.splited(line, ";")
    if #cols > 5 then
      self.fanqie_map[cols[3]] = {
        moku = cols[12],
        koe = cols[9],
        roma = cols[14],
        -- roma = cols[15],
      }
    end
  end
end

--- 士
---@param ch string
---@return string[]?
function UniHanDict:hover(ch)
  local item = self.map[ch]
  if item then
    local cp = utf8.codepoint(ch)
    local lines = {}
    if item.ref then
      table.insert(lines, "参照 => " .. item.ref)
    end
    if item.goma then
      table.insert(lines, ("UNICODE:U+%X 四角号碼:%s"):format(cp, item.goma))
    end
    if item.annotation and #item.annotation > 0 then
      table.insert(lines, item.annotation)
    end
    table.insert(lines, "")

    table.insert(lines, "# 読み")
    if #item.kana > 0 then
      table.insert(lines, util.join(item.kana, ","))
    end
    for _, r in ipairs(item.readings) do
      table.insert(lines, r.zhuyin .. (r.tiao and ("%d"):format(r.tiao) or ""))
    end
    table.insert(lines, "")

    if #item.fanqie > 0 then
      table.insert(lines, "# 半切")
      for _, f in ipairs(item.fanqie) do
        local line = f .. "切"
        local fanqie = self.fanqie_map[f]
        if fanqie then
          local heisui, heisui_hei = yun.get_heisui(fanqie.moku)
          if heisui_hei then
            line = line .. (" %s(平水%s)韻: %s"):format(fanqie.moku, heisui, fanqie.roma)
          else
            line = line .. (" %s韻: %s"):format(fanqie.moku, fanqie.roma)
          end
        end
        table.insert(lines, line)
      end
    end
    table.insert(lines, "")

    if item.xszd then
      table.insert(lines, "# 學生字典")
      for i, l in util.split, { item.xszd, "\n" } do
        table.insert(lines, l)
      end
    end
    return lines
  end
end

return UniHanDict
