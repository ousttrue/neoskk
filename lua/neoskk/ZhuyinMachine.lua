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
function ZhuyinMachine:input(lhs)
  local out_tmp
  local out = ""
  for key in lhs:gmatch "." do
    -- 一文字ずつ
    out_tmp = self:_input(key)
    if out_tmp then
      out = out .. out_tmp
    end
  end
  return out
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
