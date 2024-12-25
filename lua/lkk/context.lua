local KanaTable = require "lkk.kana.kana_table"

---@class Context
---@field kanaTable KanaTable 全ての変換ルール
---@field kakutei string
---@field feed string
---@field tmpResult? KanaRule feedに完全一致する変換ルール
local Context = {}

---@return Context
function Context.new()
  local self = setmetatable({}, { __index = Context })
  self.kanaTable = KanaTable.new()
  self.kakutei = ""
  self.feed = ''
  return self
end

---@param result KanaRule
function Context.acceptResult(self, result)
  self.kakutei = self.kakutei .. result.output
  self.feed = result.next
end

---@param char string
function Context.kanaInput(self, char)
  local input = self.feed .. char
  local candidates = self.kanaTable:filter(input)
  if #candidates == 1 and candidates[1].input == input then
    -- 候補が一つかつ完全一致。確定
    self:acceptResult(candidates[1])
    self:updateTmpResult()
  elseif #candidates > 0 then
    -- 未確定
    self.feed = input
    self:updateTmpResult(candidates)
  elseif self.tmpResult then
    -- 新しい入力によりtmpResultで確定
    self:acceptResult(self.tmpResult)
    self:updateTmpResult()
    self:kanaInput(char)
  else
    -- 入力ミス。self.tmpResultは既にnil
    self.feed = ""
    self:kanaInput(char)
  end
end

---@param candidates? KanaRule[]
function Context:updateTmpResult(candidates)
  candidates = candidates or self.kanaTable:filter(self.feed)
  self.tmpResult = nil
  for _, candidate in ipairs(candidates) do
    if candidate.input == self.feed then
      self.tmpResult = candidate
      break
    end
  end
end

return Context
