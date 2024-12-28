local ruleconv = require "neoskk.tables.ruleconv"
local KanaRules = require "neoskk.tables.KanaRules"
local util = require "neoskk.util"
local utf8 = require "neoskk.utf8"

local HIRAKANA = 0
local KATAKANA = 1

---@alias INPUT_MODE `HIRAKANA` | `KATAKANA`

local RAW = 0
local CONV = 1
local OKURI = 2

---@alias CONV_MODE `RAW` | `CONV` | `OKURI`

---@class SkkMachine
---@field input_mode INPUT_MODE
---@field kana_feed string かな入力の未確定(ascii)
---@field conv_feed string 漢字変換の未確定(かな)
---@field okuri_feed string 送り仮名
---@field conv_mode CONV_MODE
SkkMachine = {
  HIRAKANA = HIRAKANA,
  KATAKANA = KATAKANA,

  RAW = RAW,
  CONV = CONV,
  OKURI = OKURI,
}

function SkkMachine.new()
  local self = setmetatable({
    input_mode = HIRAKANA,
    kana_feed = "",
    conv_feed = "",
    okuri_feed = "",
    conv_mode = RAW,
  }, {
    __index = SkkMachine,
  })
  return self
end

function SkkMachine.clear(self)
  self.kana_feed = ""
  self.conv_feed = ""
  self.conv_mode = RAW
end

--- 大文字入力によるモード変更
--- @param lhs string
function SkkMachine._upper(self, lhs)
  if self.conv_mode == RAW then
    self.conv_mode = CONV
  elseif self.conv_mode == CONV then
    self.conv_mode = OKURI
    self.okuri_feed = lhs
  elseif self.conv_mode == OKURI then
    --
  else
    assert(false, "unknown mode")
  end
end

---@return string
function SkkMachine.clear_conv(self)
  local conv_feed = self.conv_feed
  self.conv_feed = ""
  self.conv_mode = RAW
  return conv_feed
end

local function copy_item(src)
  local dst = {}
  for k, v in pairs(src) do
    dst[k] = v
  end
  return dst
end

---@param jisyo JisyoItem[]
---@param key string
---@param okuri string?
---@return JisyoItem[]
local function filter_jisyo(jisyo, key, okuri)
  local items = {}
  for k, v in pairs(jisyo) do
    if k == key then
      for _, item in ipairs(v) do
        local copy = copy_item(item)
        if okuri then
          copy.word = copy.word .. okuri
        end
        table.insert(items, copy)
      end
    end
  end
  return items
end

---@param lhs string
---@return string
function SkkMachine._input(self, lhs)
  if lhs == "q" then
    if self.input_mode == HIRAKANA then
      self.input_mode = KATAKANA
    else
      self.input_mode = HIRAKANA
    end
    return ""
  end

  local kana, feed = ruleconv(KanaRules, self.kana_feed .. lhs)
  self.kana_feed = feed
  if self.input_mode == KATAKANA then
    return util.str_to_katakana(kana)
  else
    return kana
  end
end

---@param lhs string
---@param dict SkkDict?
---@return string out
---@return string preedit
---@return CompletionItem[]?
function SkkMachine:input(lhs, dict)
  if lhs:match "^[A-Z]$" then
    lhs = string.lower(lhs)
    self:_upper(lhs)
  end

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

  if self.conv_mode == RAW then
    -- raw
    local out = self:_input(lhs)
    return out, self.kana_feed
  elseif self.conv_mode == CONV then
    -- conv
    if dict and lhs == " " then
      local conv_feed = self:clear_conv()
      local items = filter_jisyo(dict.jisyo, conv_feed)
      return conv_feed, "", items
    elseif lhs == "q" then
      self.conv_feed = util.str_toggle_kana(self.conv_feed)
      return "", self.conv_feed .. self.kana_feed
    else
      local out = self:_input(lhs)
      self.conv_feed = self.conv_feed .. out
      local preedit = self.conv_feed .. self.kana_feed
      if preedit:match "^g%d+$" then
        return preedit, "", {
          "四角号碼",
          "四角号碼",
        }
      else
        return "", preedit
      end
    end
  elseif self.conv_mode == OKURI then
    -- okuri
    local out = self:_input(lhs)
    if dict and #out > 0 then
      -- trigger
      local conv_feed = self:clear_conv()
      local items = filter_jisyo(dict.jisyo, conv_feed .. self.okuri_feed, out)
      return conv_feed, "", items
    else
      return "", self.conv_feed .. self.kana_feed
    end
  else
    assert(false)
    return "", ""
  end
end

return SkkMachine
