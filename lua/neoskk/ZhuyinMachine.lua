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
---@field kana_feed string かな入力の未確定(ascii)
---@field conv_feed string 漢字変換の未確定(かな)
local ZhuyinMachine = {}
ZhuyinMachine.__index = ZhuyinMachine

---@return ZhuyinMachine
function ZhuyinMachine.new()
  local self = setmetatable({
    kana_feed = "",
    conv_feed = "",
  }, ZhuyinMachine)
  return self
end

function ZhuyinMachine:mode_text()
  return "ㄅ"
end

function ZhuyinMachine:preedit()
  return self.conv_feed .. self.kana_feed
end

function ZhuyinMachine:flush()
  local out = self:preedit()
  self.conv_feed = ""
  self.kana_feed = ""
  return out
end

---@param lhs string
---@param dict UniHanDict
---@return string out
---@return string preedit
---@return Completion?
function ZhuyinMachine:input(lhs, dict)
  local out_tmp, preedit, completion
  local out = ""
  for key in lhs:gmatch "." do
    -- 一文字ずつ
    out_tmp, preedit, completion = self:_input(key, dict)
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
---@param key string
---@return CompletionItem[]
local function filter_jisyo(dict, key)
  local items = {}
  for k, v in pairs(dict.zhuyin_map) do
    if k == key then
      for _, ch in ipairs(v) do
        -- local item =
        local zhuyin_item = CompletionItem.from_word(ch, dict:get(ch), dict)
        zhuyin_item.equal = true
        table.insert(items, zhuyin_item)
      end
    end
  end
  return items
end

---@param lhs string
---@param dict UniHanDict?
---@return string out
---@return string preedit
---@return Completion?
function ZhuyinMachine:_input(lhs, dict)
  if lhs == "\b" then
    if #self.kana_feed > 0 then
      self.kana_feed = self.kana_feed:sub(1, #self.kana_feed - 1)
      return "", self.conv_feed .. self.kana_feed
    elseif #self.conv_feed > 0 then
      local pos
      for i, c in utf8.codes(self.conv_feed) do
        pos = i
      end
      self.conv_feed = self.conv_feed:sub(1, pos - 1)
      return "", self.conv_feed .. self.kana_feed
    else
      return "<C-h>", ""
    end
  end

  if lhs == "\n" then
    local out = self:flush()
    return #out > 0 and out or "\n", ""
  end

  -- conv
  if lhs == " " then
    if dict then
      local conv_feed = self:clear_conv()
      local items = filter_jisyo(dict, conv_feed)
      return conv_feed, "", Completion.new(items)
    end
  end

  local out = self:input_char(lhs)
  self.conv_feed = self.conv_feed .. out
  local preedit = self.conv_feed .. self.kana_feed
  return "", preedit
end

---@return string
function ZhuyinMachine.clear_conv(self)
  local conv_feed = self.conv_feed
  self.conv_feed = ""
  return conv_feed
end

---@param lhs string
---@return string
function ZhuyinMachine.input_char(self, lhs)
  -- local kana, feed =
  --     MachedKanaRule.conv(KanaRules, self.kana_feed .. lhs, MachedKanaRule.new(KanaRules, self.kana_feed))
  -- self.kana_feed = feed
  -- if self.input_mode == KATAKANA then
  --   kana = util.str_to_katakana(kana)
  -- end
  -- return kana
  local tmp = rules[lhs]
  if tmp then
    return tmp
  else
    return lhs
  end
end

return ZhuyinMachine
