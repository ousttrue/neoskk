local utf8 = require "neoskk.utf8"
local Completion = require "neoskk.Completion"
local util = require "neoskk.util"

--- 単漢字
---@class UniHanChar
---@field goma string? 四角号碼
---@field xszd string? 學生字典
---@field qieyun string? 切韻 TODO
---@field pinyin string? pinyin
---@field fanqie string[] 反切
---@field kana string[] よみかな
---@field chuon string? 注音符号 TODO
---@field flag integer TODO 新字体 簡体字 国字 常用漢字
---@field indices string 康煕字典
---@field ref string?
local UniHanChar = {}

---@param item UniHanChar
---@return string
local function get_prefix(item)
  local prefix = ""
  if item.indices then
    prefix = "康煕"
  else
    prefix = "    "
  end
  prefix = "[" .. prefix .. "]"
  if item.xszd then
    prefix = prefix .. "+"
  end
  return prefix
end

---@param path string
---@param from string?
---@param to string?
---@param opts table? vim.iconv opts
---@return string?
local function readFileSync(path, from, to, opts)
  if not vim.uv.fs_stat(path) then
    return
  end
  local fd = assert(vim.uv.fs_open(path, "r", 438))
  local stat = assert(vim.uv.fs_fstat(fd))
  local data = assert(vim.uv.fs_read(fd, stat.size, 0))
  assert(vim.uv.fs_close(fd))
  if from and to then
    data = assert(vim.iconv(data, from, to, opts))
  end
  return data
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

---@class UniHanDict
---@field map table<string, UniHanChar>
---@field jisyo table<string, CompletionItem[]>
---@field simple_map table<string, string>
local UniHanDict = {}
UniHanDict.__index = UniHanDict
---@return UniHanDict
function UniHanDict.new()
  local self = setmetatable({
    map = {},
    jisyo = {},
    simple_map = {},
  }, UniHanDict)
  return self
end

---@param char string 漢字
---@return UniHanChar?
function UniHanDict:get(char)
  ---@type UniHanChar?
  local item = self.map[char]
  if not item then
    -- if utf8.len ~= 1 then
    --   return
    -- end
    item = {
      fanqie = {},
      kana = {},
    }
    self.map[char] = item
  end
  return item
end

--- 學生字典(XueShengZiDian)
---@param path string
function UniHanDict:load_xszd(path)
  local data = readFileSync(path)
  if not data then
    return
  end
  -- **一
  -- -衣悉切(I)入聲
  -- --數之始也。凡物單個皆曰一。
  -- --同也。（中庸）及其成功一也。
  -- --統括之詞。如一切、一概。
  -- --或然之詞。如萬一、一旦。
  -- --專也。如一味、一意。

  local pos = 1
  local char
  local last_char
  while pos do
    local s, e = data:find("\n%*%*[^\n]+\n", pos)
    if s then
      if char and last_char then
        local item = self:get(char)
        if item then
          item.xszd = data:sub(last_char, s)
        end
      end
      char = data:sub(s + 3, e - 1)
      last_char = e + 1
    else
      -- last one
      if char and last_char then
        local item = self:get(char)
        if item then
          item.xszd = data:sub(last_char)
        end
      end
      break
    end
    pos = e + 1
  end
end

---@param path string
function UniHanDict:load_skk(path)
  local data = readFileSync(path, "euc-jp", "utf-8", {})
  if not data then
    return
  end
  for _, l in ipairs(vim.split(data, "\n")) do
    local word, values = parse_line(l)
    if word and values then
      -- print(("[%s][%s]"):format(word, values))
      local items = self.jisyo[word]
      if not items then
        items = {}
        self.jisyo[word] = items
      end
      for w in values:gmatch "[^/]+" do
        local annotation_index = w:find(";", nil, true)
        local annotation = ""
        if annotation_index then
          annotation = w:sub(annotation_index + 1)
          w = w:sub(1, annotation_index - 1)
        end
        local item = self:get(w)
        local prefix = " "
        if item then
          prefix = get_prefix(item)
        end
        local new_item = {
          word = w,
          abbr = w,
          menu = prefix,
        }
        if item then
          new_item.info = item.xszd
          if item.goma then
            new_item.abbr = new_item.abbr .. " " .. item.goma
          end
          if #item.kana > 0 then
            new_item.abbr = new_item.abbr .. " " .. item.kana[1]
          end
          if #item.fanqie > 0 then
            new_item.abbr = new_item.abbr .. " " .. item.fanqie[1]
          else
            new_item.abbr = new_item.abbr .. " " .. "    "
            if item.ref then
              new_item.menu = "[=>" .. item.ref .. "]"
            end
          end
          if item.pinyin then
            new_item.abbr = new_item.abbr .. " " .. item.pinyin
          end
        end
        if annotation then
          new_item.abbr = new_item.abbr .. " " .. annotation
        end

        table.insert(items, new_item)
      end
      -- break
    end
  end
end

function UniHanDict:load_kangxi(path)
  local data = readFileSync(path)
  if data then
    -- KX0075.001	一
    for kx, ch in string.gmatch(data, "(KX%d%d%d%d%.%d%d%d)\t([^\n]+)\n") do
      local t = self.simple_map[ch]
      if t then
        -- print(t, ch)
        ch = t
      end
      local item = self:get(ch)
      assert(item)
      item.indices = kx
    end
  end
end

---@param dir string
function UniHanDict:load_unihan(dir)
  self:load_unihan_likedata(dir .. "/Unihan_DictionaryLikeData.txt")
  self:load_unihan_readings(dir .. "/Unihan_Readings.txt")
  -- self:load_unihan_indices(dir .. "/Unihan_DictionaryIndices.txt")
  self:load_unihan_variants(dir .. "/Unihan_Variants.txt")
end

function UniHanDict:load_unihan_likedata(path)
  local data = readFileSync(path)
  if data then
    -- U+5650	kFourCornerCode	6666.1
    for unicode, goma in string.gmatch(data, "U%+([A-F0-9]+)\tkFourCornerCode\t([%d%.]+)") do
      local codepoint = tonumber(unicode, 16)
      local ch = utf8.char(codepoint)
      local item = self:get(ch)
      assert(item)
      item.goma = goma
    end
  end
end

function UniHanDict:load_unihan_readings(path)
  local data = readFileSync(path)
  if data then
    -- U+3400	kMandarin	qiū
    -- U+3401	kFanqie	他紺 他念
    -- U+3400	kJapanese	キュウ おか
    for unicode, k, value in string.gmatch(data, "U%+([A-F0-9]+)\t(k%w+)\t([^\n]+)") do
      local codepoint = tonumber(unicode, 16)
      local ch = utf8.char(codepoint)
      local item = self:get(ch)
      assert(item)
      if k == "kMandarin" then
        item.pinyin = value
      elseif k == "kFanqie" then
        item.fanqie = util.split(value)
      elseif k == "kJapanese" then
        item.kana = util.split(value)
      end
    end
  end
end

-- 新字体とか最近の文字も含まれてたー
function UniHanDict:load_unihan_indices(path)
  local data = readFileSync(path)
  if data then
    -- U+3400	kKangXi	0078.010
    for unicode, kangxi in string.gmatch(data, "U%+([A-F0-9]+)\tkIRGKangXi\t([%S%.]+)") do
      local codepoint = tonumber(unicode, 16)
      local ch = utf8.char(codepoint)
      local item = self:get(ch)
      assert(item)
      item.indices = kangxi
    end
  end
end

function UniHanDict:load_unihan_variants(path)
  local data = readFileSync(path)
  if data then
    -- U+346E	kSimplifiedVariant	U+2B748
    for traditional, simple in string.gmatch(data, "U%+([A-F0-9]+)\tkSimplifiedVariant\tU%+([A-F0-9]+)") do
      local s_codepoint = tonumber(simple, 16)
      local s_ch = utf8.char(s_codepoint)
      local t_codepoint = tonumber(traditional, 16)
      local t_ch = utf8.char(t_codepoint)
      self.simple_map[s_ch] = t_ch
    end
  end
end

---@param ch string
---@param item UniHanChar
---@return CompletionItem
local function to_completion(ch, item)
  local prefix = get_prefix(item)
  local new_item = {
    word = "g" .. item.goma,
    abbr = ch .. " " .. item.goma,
    menu = prefix,
    dup = true,
    user_data = {
      replace = ch,
    },
    info = item.xszd,
  }
  if #item.kana > 0 then
    new_item.abbr = new_item.abbr .. " " .. item.kana[1]
  end
  if #item.fanqie > 0 then
    new_item.abbr = new_item.abbr .. " " .. item.fanqie[1]
  else
    new_item.abbr = new_item.abbr .. " " .. "    "
    if item.ref then
      new_item.menu = "[=>" .. item.ref .. "]"
    end
  end
  if item.pinyin then
    new_item.abbr = new_item.abbr .. " " .. item.pinyin
  end

  return new_item
end

---@param n string %d
---@return Completion
function UniHanDict:filter_goma(n)
  --@type CompletionItem[]
  local items = {}
  for ch, item in pairs(self.map) do
    if item.goma and item.goma:match(n) then
      table.insert(items, to_completion(ch, item))
    end
  end
  return Completion.new(items, Completion.FUZZY_OPTS)
end

---支那漢
---@param path string
function UniHanDict:load_chinadat(path)
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
  local data = readFileSync(path)
  if data then
    -- 亜,亞,,009,7,5,7,+10106+,/ya3/ya4*,1ア1つぐ1,
    local i = 1
    for line in string.gmatch(data, "([^\n]+)\r") do
      local cols = util.split(line, ",")
      -- 伝(1),傳,,026,9,4,6,+21231+,/chuan2,1テン1デン1つたふ1(1つたう1)1つたへる1(1つたえる1)1つたはる1(1つたわる1)1つて1,
      local ch = cols[1]
      local s, e = ch:find "%(%d+%)"
      if s then
        if ch:sub(s + 1, e - 1) == "1" then
          ch = ch:sub(1, s - 1)
        else
          ch = nil
        end
      end

      if ch then
        local item = self:get(ch)
        assert(item)
        if #cols[2] > 0 then
          item.ref = cols[2]
          -- print(vim.inspect(cols))
          -- break
        end
      end
    end
  end
end

return UniHanDict
