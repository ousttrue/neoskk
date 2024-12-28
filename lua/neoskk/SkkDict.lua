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

---@class CompletionItem
---@field word string the text that will be inserted, mandatory
---@field abbr string abbreviation of "word"; when not empty it is used in the menu instead of "word"
---@field menu string extra text for the popup menu, displayed after "word" or "abbr"
---@field info string more information about the item, can be displayed in a preview window
---@field kind string single letter indicating the type of completion icase		when non-zero case is to be ignored when comparing items to be equal; when omitted zero is used, thus items that only differ in case are added
---@field equal boolean when non-zero, always treat this item to be equal when comparing. Which means, "equal=1" disables filtering of this item.
---@field dup boolean when non-zero this match will be added even when an item with the same word is already present.
---@field empty boolean	when non-zero this match will be added even when it is an empty string
---@field user_data	any custom data which is associated with the item and available in |v:completed_item|; it can be any type; defaults to an empty string
---@field abbr_hlgroup string an additional highlight group whose attributes are combined with |hl-PmenuSel| and |hl-Pmenu| or |hl-PmenuMatchSel| and |hl-PmenuMatch| highlight attributes in the popup menu to apply cterm and gui properties (with higher priority) like strikethrough to the completion items abbreviation
---@field kind_hlgroup string an additional highlight group specifically for setting the highlight attributes of the completion kind. When this field is present, it will override the |hl-PmenuKind| highlight group, allowing for the customization of ctermfg and guifg properties for the completion kind

---@class SkkDict
---@field jisyo table<string, CompletionItem[]>
---@field goma CompletionItem[]
local SkkDict = {}

---@return SkkDict
function SkkDict.new()
  local self = setmetatable({
    jisyo = {},
    goma = {},
  }, { __index = SkkDict })
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
