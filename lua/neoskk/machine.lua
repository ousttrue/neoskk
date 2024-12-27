local kanaconv = require "neoskk.kanaconv"
local util = require "neoskk.util"

local M = {}

local HIRAKANA = 0
local KATAKANA = 1

---@alias INPUT_MODE `HIRAKANA` | `KATAKANA`

---@class SkkMachine
---@field input_mode INPUT_MODE
---@field feed string 未確定入力
M.SkkMachine = {
  HIRAKANA = HIRAKANA,
  KATAKANA = KATAKANA,
}

function M.SkkMachine.new()
  local self = setmetatable({
    input_mode = HIRAKANA,
    feed = "",
  }, {
    __index = M.SkkMachine,
  })
  return self
end

---@param ch string
---@return string
function M.SkkMachine.input(self, ch)
  if ch == "q" then
    if self.input_mode == HIRAKANA then
      self.input_mode = KATAKANA
    else
      self.input_mode = HIRAKANA
    end
    return ""
  else
    local kana, feed = kanaconv.to_kana(self.feed .. ch)
    self.feed = feed
    if self.input_mode == HIRAKANA then
      return kana
    elseif self.input_mode == KATAKANA then
      return util.hira_to_kata(kana)
    else
      assert(false, "unknown input_mode")
    end
  end
end

return M
