local utf8 = require "neoskk.utf8"

---@param path string
---@param from string?
---@param to string?
---@param opts table? vim.iconv opts
---@return string
local function readFileSync(path, from, to, opts)
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
local SkkDict = {}
SkkDict.__index = SkkDict
---@return SkkDict
function SkkDict.new()
  local self = setmetatable({
    jisyo = {},
    goma = {},
  }, SkkDict)
  return self
end

---@param path string
function SkkDict:load_skk(path)
  if not vim.uv.fs_stat(path) then
    return
  end

  local data = readFileSync(path, "euc-jp", "utf-8", {})
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
  local src = readFileSync(path)
  -- U+5650	kFourCornerCode	6666.1
  for unicode, goma in string.gmatch(src, "U%+([A-F0-9]+)\tkFourCornerCode\t([%d%.]+)") do
    local codepoint = tonumber(unicode, 16)
    local ch = utf8.char(codepoint)
    table.insert(self.goma, {
      word = "g" .. goma,
      abbr = ch .. " " .. goma,
      menu = "号碼",
      user_data = {
        replace = ch,
      },
    })
  end
end

return SkkDict
