local utf8 = require "neoskk.utf8"
local Completion = require "neoskk.Completion"

--- 単漢字
---@class UniHanChar
---@field goma string? 四角号碼
---@field xszd string? 學生字典
---@field qieyun string? 切韻 TODO
---@field pinyin string? pinyin
---@field chuon string? 注音符号 TODO
---@field flag integer TODO 新字体 簡体字 国字 常用漢字
---@field indices string 康煕字典
local UniHanChar = {}

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
local UniHanDict = {}
UniHanDict.__index = UniHanDict
---@return UniHanDict
function UniHanDict.new()
  local self = setmetatable({
    map = {},
    jisyo = {},
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
    item = {}
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
        local annotation = w:find(";", nil, true)

        local new_item = {
          word = w,
          abbr = w,
        }
        if annotation then
          new_item.word = w:sub(1, annotation - 1)
          new_item.abbr = w
        end
        local item = self:get(new_item.word)
        if item then
          new_item.info = item.xszd
          new_item.menu = item.goma
          if item.pinyin then
            new_item.menu = new_item.menu .. " " .. item.pinyin
          end
        end
        if item and item.xszd then
          new_item.abbr = "*" .. new_item.abbr
        else
          new_item.abbr = " " .. new_item.abbr
        end
        table.insert(items, new_item)
      end
      -- break
    end
  end
end

---@param dir string
function UniHanDict:load_unihan(dir)
  self:load_unihan_likedata(dir .. "/Unihan_DictionaryLikeData.txt")
  self:load_unihan_readings(dir .. "/Unihan_Readings.txt")
  self:load_unihan_indices(dir .. "/Unihan_DictionaryIndices.txt")
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
    for unicode, pinyin in string.gmatch(data, "U%+([A-F0-9]+)\tkMandarin\t([%S%.]+)") do
      local codepoint = tonumber(unicode, 16)
      local ch = utf8.char(codepoint)
      local item = self:get(ch)
      assert(item)
      item.pinyin = pinyin
    end
  end
end

function UniHanDict:load_unihan_indices(path)
  local data = readFileSync(path)
  if data then
    -- U+3400	kKangXi	0078.010
    for unicode, kangxi in string.gmatch(data, "U%+([A-F0-9]+)\tkKangXi\t([%S%.]+)") do
      local codepoint = tonumber(unicode, 16)
      local ch = utf8.char(codepoint)
      local item = self:get(ch)
      assert(item)
      item.indices = kangxi
    end
  end
end

---@param ch string
---@param item UniHanChar
---@return CompletionItem
local function to_completion(ch, item)
  local new_item = {
    word = "g" .. item.goma,
    abbr = ch .. (item.indices and " " or "*") .. item.goma,
    menu = item.pinyin,
    dup = true,
    user_data = {
      replace = ch,
    },
    info = item.xszd,
  }
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

return UniHanDict
