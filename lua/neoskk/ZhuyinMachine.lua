local Completion = require "neoskk.Completion"
local CompletionItem = require "neoskk.CompletionItem"
local utf8 = require "neoskk.utf8"

-- 注音輸入法 https://ja.wikipedia.org/wiki/%E6%B3%A8%E9%9F%B3%E8%BC%B8%E5%85%A5%E6%B3%95

local rules = {
  ["1"] = "ㄅ",
  q = "ㄆ",
  a = "ㄇ",
  z = "ㄈ",

  ["2"] = "ㄉ",
  w = "ㄊ",
  s = "ㄋ",
  x = "ㄌ",

  e = "ㄍ",
  d = "ㄎ",
  c = "ㄏ",

  r = "ㄐ",
  f = "ㄑ",
  v = "ㄒ",

  ["5"] = "ㄓ",
  t = "ㄔ",
  g = "ㄕ",
  b = "ㄖ",

  y = "ㄗ",
  h = "ㄘ",
  n = "ㄙ",

  u = "ㄧ",
  j = "ㄨ",
  m = "ㄩ",

  ["8"] = "ㄚ",
  i = "ㄛ",
  k = "ㄜ",
  [","] = "ㄝ",

  ["9"] = "ㄞ",
  o = "ㄟ",
  l = "ㄠ",
  ["."] = "ㄡ",

  ["0"] = "ㄢ",
  p = "ㄣ",
  [";"] = "ㄤ",
  ["/"] = "ㄥ",

  ["-"] = "ㄦ",
}

---@class ZhuyinMachine
local ZhuyinMachine = {}
ZhuyinMachine.__index = ZhuyinMachine

ZhuyinMachine.map = {}
for k, v in pairs(rules) do
  ZhuyinMachine.map[v] = k
end

---@return ZhuyinMachine
function ZhuyinMachine.new()
  local self = setmetatable({}, ZhuyinMachine)
  return self
end

function ZhuyinMachine:mode_text()
  return "ㄅ"
end

---@param lhs string
---@return string out
---@return string preedit
---@return Completion?
function ZhuyinMachine:input(lhs)
  local out_tmp, preedit, completion
  local out = ""
  for key in lhs:gmatch "." do
    -- 一文字ずつ
    out_tmp, preedit, completion = self:_input(key)
    if out_tmp then
      out = out .. out_tmp
    end
  end
  return out, preedit, completion
end

---@return CompletionItem
local function copy_item(src)
  local dst = {}
  for k, v in pairs(src) do
    dst[k] = v
  end
  return dst
end

---@param dict UniHanDict
---@param zhuyin string
---@return CompletionItem[]
local function filter_jisyo(dict, zhuyin)
  local items = {}
  for k, v in pairs(dict.zhuyin_map) do
    if k == zhuyin then
      for _, ch in ipairs(v) do
        local item = dict:get_or_create(ch)
        assert(item)
        local new_item = CompletionItem.from_word(ch, item, dict)
        new_item.word = zhuyin
        new_item.dup = true
        new_item.user_data = {
          replace = ch,
        }
        if item.tiao then
          new_item.word = new_item.word .. ("%d").format(item.tiao)
        end
        table.insert(items, new_item)
      end
    end
  end
  return items
end

---@param lhs string
---@return string out
function ZhuyinMachine:_input(lhs)
  if lhs == "\b" then
    return "<C-h>"
  end

  return self:input_char(lhs)
end

---@param lhs string
---@return string
function ZhuyinMachine.input_char(self, lhs)
  local tmp = rules[lhs]
  if tmp then
    return tmp
  else
    return lhs
  end
end

return ZhuyinMachine
