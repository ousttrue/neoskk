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

---@return ZhuyinMachine
function ZhuyinMachine.new()
  local self = setmetatable({}, ZhuyinMachine)
  return self
end

function ZhuyinMachine:mode_text()
  return "ㄅ"
end

function ZhuyinMachine:preedit()
  return ""
end

function ZhuyinMachine:flush()
  return ""
end

---@param lhs string
---@return string out
---@return string preedit
function ZhuyinMachine:input(lhs)
  local out = ""
  for key in lhs:gmatch "." do
    -- 一文字ずつ
    local tmp = rules[key]
    if tmp then
      out = out .. tmp
    else
      out = out .. key
    end
  end
  return out, ""
end

return ZhuyinMachine
