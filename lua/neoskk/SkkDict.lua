local utf8 = require "neoskk.utf8"
local CompletionItem = require "neoskk.CompletionItem"
local Completion = require "neoskk.Completion"

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

---@class SkkDict
---@field jisyo table<string, CompletionItem[]>
---@field goma CompletionItem[]
---@field chars table<string, string>
local SkkDict = {}
SkkDict.__index = SkkDict
---@return SkkDict
function SkkDict.new()
  local self = setmetatable({
    jisyo = {},
    goma = {},
    chars = {},
  }, SkkDict)
  return self
end

--- 學生字典(XueShengZiDian)
---@param path string
function SkkDict:load_xszd(path)
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
  while pos do
    local s, e = data:find("\n%*%*[^\n]+\n", pos)
    if s then
      if char then
        self.chars[char] = data:sub(self.chars[char], s)
      end
      char = data:sub(s + 3, e - 1)
      self.chars[char] = e + 1
    else
      if char then
        self.chars[char] = data:sub(self.chars[char])
      end
      break
    end
    pos = e + 1
  end
end

---@param path string
function SkkDict:load_skk(path)
  local data = readFileSync(path, "euc-jp", "utf-8", {})
  if not data then
    return
  end
  for i, l in ipairs(vim.split(data, "\n")) do
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
        if annotation then
          table.insert(items, {
            word = w:sub(1, annotation - 1),
            abbr = w,
          })
        else
          table.insert(items, {
            word = w,
            -- abbr = w,
          })
        end
      end
      -- break
    end
  end
end

---@param path string
function SkkDict:load_goma(path)
  local data = readFileSync(path)
  if not data then
    return
  end
  -- U+5650	kFourCornerCode	6666.1
  for unicode, goma in string.gmatch(data, "U%+([A-F0-9]+)\tkFourCornerCode\t([%d%.]+)") do
    local codepoint = tonumber(unicode, 16)
    local ch = utf8.char(codepoint)
    table.insert(self.goma, {
      word = "g" .. goma,
      abbr = ch .. " " .. goma,
      menu = "[四]",
      dup = true,
      user_data = {
        replace = ch,
      },
    })
  end
end

---@param n string %d
---@return Completion
function SkkDict:filter_goma(n)
  --@type CompletionItem[]
  local items = {}
  for i, item in ipairs(self.goma) do
    if item.word:match(n) then
      local info = self.chars[item.user_data.replace]
      if info then
        item.info = info
      end
      table.insert(items, item)
    end
  end
  return Completion.new(items, Completion.FUZZY_OPTS)
end

return SkkDict
