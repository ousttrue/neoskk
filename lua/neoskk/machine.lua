local kanaconv = require "neoskk.kanaconv"
local util = require "neoskk.util"

local M = {}

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
M.SkkMachine = {
  HIRAKANA = HIRAKANA,
  KATAKANA = KATAKANA,

  RAW = RAW,
  CONV = CONV,
  OKURI = OKURI,
}

function M.SkkMachine.new()
  local self = setmetatable({
    input_mode = HIRAKANA,
    kana_feed = "",
    conv_feed = "",
    okuri_feed = "",
    conv_mode = RAW,
  }, {
    __index = M.SkkMachine,
  })
  return self
end

--- 大文字入力によるモード変更
--- @param lhs string
function M.SkkMachine.upper(self, lhs)
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
function M.SkkMachine.clear_conv(self)
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
---@param conv_feed string
---@param okuri string?
---@return JisyoItem[]
local function filter_jisyo(jisyo, conv_feed, okuri)
  -- local items = {}
  -- local key = conv_feed .. self.okuri_feed
  -- for k, v in pairs(M.jisyo) do
  --   if k == key then
  --     for _, item in ipairs(v) do
  --       local copy = copy_item(item)
  --       copy.word = copy.word .. out
  --       table.insert(items, copy)
  --     end
  --   end
  -- end

  local items = {}
  for k, v in pairs(jisyo) do
    if k == conv_feed then
      for _, item in ipairs(v) do
        -- table.insert(items, item)
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

---@param ch string
---@return string
function M.SkkMachine._input(self, ch)
  if ch == "q" then
    if self.input_mode == HIRAKANA then
      self.input_mode = KATAKANA
    else
      self.input_mode = HIRAKANA
    end
    return ""
  else
    local kana, feed = kanaconv.to_kana(self.kana_feed .. ch)
    self.kana_feed = feed
    if self.input_mode == KATAKANA then
      return util.hira_to_kata(kana)
    else
      return kana
    end
  end
end

---@param lhs string
---@return string out
---@return string preedit
---@return JisyoItem[]?
function M.SkkMachine.input(self, lhs, jisyo)
  if self.conv_mode == RAW then
    -- raw
    local out = self:_input(lhs)
    return out, self.kana_feed
  elseif self.conv_mode == CONV then
    -- conv
    if lhs == " " then
      local conv_feed = self:clear_conv()
      local items = filter_jisyo(jisyo, conv_feed)
      return conv_feed, "", items
    else
      local out = self:_input(lhs)
      self.conv_feed = self.conv_feed .. out
      return "", self.conv_feed .. self.kana_feed
    end
  elseif self.conv_mode == OKURI then
    -- okuri
    local out = self:_input(lhs)
    if #out > 0 then
      -- trigger
      local conv_feed = self:clear_conv()
      local items = filter_jisyo(jisyo, conv_feed .. self.okuri_feed)
      return conv_feed .. out, ""
    else
      return "", self.conv_feed .. self.kana_feed
    end
  else
    assert(false)
    return "", ""
  end
end

return M
