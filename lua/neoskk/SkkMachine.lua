local MachedKanaRule = require "neoskk.tables.MachedKanaRule"
local KanaRules = require "neoskk.tables.KanaRules"
local ZhuyinRules = require "neoskk.tables.ZhuyinRules"
local Completion = require "neoskk.Completion"
local util = require "neoskk.util"
local utf8 = require "neoskk.utf8"

local HIRAKANA = "hirakana"
local KATAKANA = "kanakana"
local ZHUYIN = "zhuyin"

---@alias INPUT_MODE `HIRAKANA` | `KATAKANA` | `ZHUYIN`

---@param mode INPUT_MODE
---@return string
local function input_mode_name(mode)
  if mode == HIRAKANA then
    return "平"
  elseif mode == KATAKANA then
    return "片"
  elseif mode == ZHUYIN then
    return "ㄅ"
  else
    return "?"
  end
end

local RAW = 0
local CONV = 1
local OKURI = 2

---@alias CONV_MODE `RAW` | `CONV` | `OKURI`

---@param mode CONV_MODE
---@return string
local function conv_mode_name(mode)
  if mode == RAW then
    return ""
  elseif mode == CONV then
    return "変"
  elseif mode == OKURI then
    return "送"
  else
    return "?"
  end
end

---@class SkkMachine
---@field input_mode INPUT_MODE
---@field kana_feed string かな入力の未確定(ascii)
---@field conv_feed string 漢字変換の未確定(かな)
---@field okuri_feed string 送り仮名
---@field conv_mode CONV_MODE
local SkkMachine = {
  HIRAKANA = HIRAKANA,
  KATAKANA = KATAKANA,
  ZHUYIN = ZHUYIN,

  RAW = RAW,
  CONV = CONV,
  OKURI = OKURI,
}
SkkMachine.__index = SkkMachine

function SkkMachine.new()
  local self = setmetatable({
    input_mode = HIRAKANA,
    kana_feed = "",
    conv_feed = "",
    okuri_feed = "",
    conv_mode = RAW,
  }, SkkMachine)
  return self
end

function SkkMachine:mode_text()
  return input_mode_name(self.input_mode) .. conv_mode_name(self.conv_mode)
end

---@return string
function SkkMachine.flush(self)
  local out = self.conv_feed .. self.kana_feed
  self.conv_feed = ""
  self.kana_feed = ""
  self.conv_mode = RAW
  return out
end

--- 大文字入力によるモード変更
function SkkMachine._upper(self)
  if self.conv_mode == RAW then
    self.conv_mode = CONV
  elseif self.conv_mode == CONV then
    self.conv_mode = OKURI
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

---@param jisyo table<string, CompletionItem[]>
---@param key string
---@param okuri string?
---@param xszd table<string, string>?
---@return CompletionItem[]
local function filter_jisyo(jisyo, key, okuri, xszd)
  local items = {}
  for k, v in pairs(jisyo) do
    if k == key then
      for _, item in ipairs(v) do
        local copy = copy_item(item)
        if xszd then
          local info = xszd[copy.word]
          if info then
            copy.info = info
          end
        end
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
function SkkMachine.input_char(self, lhs)
  if lhs == "q" then
    if self.input_mode == HIRAKANA then
      self.input_mode = KATAKANA
    else
      self.input_mode = HIRAKANA
    end
    return ""
  end

  local rules = self.input_mode == ZHUYIN and ZhuyinRules or KanaRules
  local kana, feed = MachedKanaRule.conv(rules, self.kana_feed .. lhs, MachedKanaRule.new(rules, self.kana_feed))
  self.kana_feed = feed
  if self.input_mode == KATAKANA then
    kana = util.str_to_katakana(kana)
  end
  return kana
end

---@param lhs string
---@param dict SkkDict?
---@return string out
---@return string preedit
---@return Completion?
function SkkMachine:input(lhs, dict)
  local out = ""
  local out_tmp, preedit, completion
  for key in lhs:gmatch "." do
    -- 一文字ずつ

    if key == " " then
      -- 一文字投入して "n" を "ん" に確定させる
      out_tmp, preedit, completion = self:_input("-", dict)
      if out_tmp then
        out = out .. out_tmp
      end
      -- 削る
      out_tmp, preedit, completion = self:_input("\b", dict)
      if out_tmp then
        out = out .. out_tmp
      end
    end

    out_tmp, preedit, completion = self:_input(key, dict)
    if out_tmp then
      out = out .. out_tmp
    end
  end
  return out, preedit, completion
end

---@param lhs string
---@param dict SkkDict?
---@return string out
---@return string preedit
---@return Completion?
function SkkMachine:_input(lhs, dict)
  if lhs:match "^[A-Z]$" then
    lhs = string.lower(lhs)
    self:_upper()
  end

  if lhs == ";" then
    self:_upper()
    return "", self.conv_feed .. self.kana_feed
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

  if lhs == "\n" then
    local out = self:flush()
    return out .. "\n", ""
  end

  if self.conv_mode == RAW then
    -- raw
    local out = self:input_char(lhs)
    return out, self.kana_feed
  elseif self.conv_mode == CONV then
    if not self.okuri_feed then
      self.okuri_feed = lhs
    end
    -- conv
    if lhs == "q" then
      self.conv_feed = util.str_toggle_kana(self.conv_feed)
      -- return "", self.conv_feed .. self.kana_feed
      -- 確定
      local preedit = self.conv_feed .. self.kana_feed
      self.conv_feed = ""
      self.kana_feed = ""
      self.conv_mode = RAW
      return preedit, ""
    end

    if lhs == " " then
      if dict then
        local conv_feed = self:clear_conv()
        local items = filter_jisyo(dict.jisyo, conv_feed, nil, dict.chars)
        self.conv_mode = RAW
        return conv_feed, "", Completion.new(items)
      end
    end

    local out = self:input_char(lhs)
    self.conv_feed = self.conv_feed .. out
    local preedit = self.conv_feed .. self.kana_feed
    if preedit:match "^g%d+$" then
      -- 四角号碼
      if dict then
        self.conv_mode = RAW
        self.conv_feed = ""
        self.kana_feed = ""
        local completion = dict:filter_goma(preedit:sub(2, 2))
        return preedit, "", completion
      end
    end
    return "", preedit
  elseif self.conv_mode == OKURI then
    -- okuri
    local out = self:input_char(lhs)
    if #out > 0 then
      if dict then
        local conv_feed = self:clear_conv()
        local items = filter_jisyo(dict.jisyo, conv_feed .. self.okuri_feed, out, dict.chars)
        return conv_feed .. out, "", Completion.new(items)
      end
    end

    return "", self.conv_feed .. self.kana_feed
  else
    assert(false)
    return "", ""
  end
end

return SkkMachine
