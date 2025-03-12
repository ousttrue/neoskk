local MachedKanaRule = require "neoskk.tables.MachedKanaRule"
local KanaRules = require "neoskk.tables.KanaRules"
local kana_util = require "neoskk.kana_util"

local HIRAKANA = "hirakana"
local KATAKANA = "kanakana"

---@alias INPUT_MODE `HIRAKANA` | `KATAKANA`

---@param mode INPUT_MODE
---@return string
local function input_mode_name(mode)
  if mode == HIRAKANA then
    return "平"
  elseif mode == KATAKANA then
    return "片"
  else
    return "?"
  end
end

---@class SkkMachine
---@field input_mode INPUT_MODE
local SkkMachine = {
  HIRAKANA = HIRAKANA,
  KATAKANA = KATAKANA,
}
SkkMachine.__index = SkkMachine

---@return SkkMachine
function SkkMachine.new()
  local self = setmetatable({
    input_mode = HIRAKANA,
  }, SkkMachine)
  return self
end

---@return string
function SkkMachine:mode_text()
  return input_mode_name(self.input_mode)
end

---@param lhs string
---@param kana_feed string
---@param pumvisible boolean?
---@return string out
---@return string preedit
---@return Completion?
function SkkMachine:input(lhs, kana_feed, pumvisible)
  local out = ""
  local out_tmp, preedit, completion
  for key in lhs:gmatch "." do
    -- 一文字ずつ
    out_tmp, preedit, completion = self:input_char(key:lower(), kana_feed)
    if out_tmp then
      out = out .. out_tmp
    end
  end
  return out, preedit, completion
end

---@param lhs string
---@param kana_feed string
---@return string out
---@return string preedit
---@return Completion?
function SkkMachine:input_char(lhs, kana_feed)
  if lhs == "\b" then
    if #kana_feed > 0 then
      kana_feed = kana_feed:sub(1, #kana_feed - 1)
      return "", kana_feed
    else
      return "<C-h>", ""
    end
  end

  if lhs == "q" then
    if self.input_mode == HIRAKANA then
      self.input_mode = KATAKANA
    else
      self.input_mode = HIRAKANA
    end
    return "", kana_feed
  end
  if lhs == "l" then
    return "<C-^>", kana_feed
  end

  local kana, feed =
    MachedKanaRule.conv(KanaRules, kana_feed .. lhs, MachedKanaRule.new(KanaRules, kana_feed))
  kana_feed = feed
  if self.input_mode == KATAKANA then
    kana = kana_util.str_to_katakana(kana)
  end
  return kana, kana_feed
end

return SkkMachine
