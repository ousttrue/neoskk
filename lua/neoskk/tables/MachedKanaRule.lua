---@class KanaRule
---@field input string
---@field output string
---@field next string

local function string_startswith(self, start)
  return self:sub(1, #start) == start
end

---@class MatchedKanaRule
---@field prefix string
---@field full_match KanaRule?
---@field prefix_matches KanaRule[]
local MatchedKanaRule = {}
MatchedKanaRule.__index = MatchedKanaRule

---@param rules KanaRule[]
---@param prefix string
---@return MatchedKanaRule?
function MatchedKanaRule.new(rules, prefix)
  if #prefix == 0 then
    return nil
  end

  local self = setmetatable({
    prefix = prefix,
    prefix_matches = {},
  }, MatchedKanaRule)
  for _, item in ipairs(rules) do
    self:push(item)
  end
  return self
end

function MatchedKanaRule:__tostring()
  if #self.prefix_matches == 1 and self.full_match then
    return ("<%s>"):format(self.prefix)
  end

  return ("#%s:%d"):format(self.prefix, #self.prefix_matches)
end

---@param rule KanaRule
function MatchedKanaRule.push(self, rule)
  if string_startswith(rule.input, self.prefix) then
    table.insert(self.prefix_matches, rule)
    if rule.input == self.prefix then
      self.full_match = rule
    end
  end
end

---@param rules KanaRule[]
---@param candidate MatchedKanaRule?
---@return string 確定
---@return string 未使用
---@return MatchedKanaRule? 未確定
function MatchedKanaRule:resolve(rules, candidate)
  local kakutei = ""
  local feed = self.prefix
  if #self.prefix_matches == 0 then
    -- マッチしない
    if candidate and candidate.full_match then
      -- candiate確定
      kakutei = candidate.full_match.output
      feed = candidate.full_match.next .. self.prefix:sub(#candidate.full_match.input + 1)
      candidate = MatchedKanaRule.new(rules, feed)
    else
      -- feed１文字確定
      kakutei = self.prefix:sub(1, 1)
      feed = self.prefix:sub(2)
      candidate = MatchedKanaRule.new(rules, feed)
    end
  else
    if self.full_match and #self.prefix_matches == 1 then
      kakutei = kakutei .. self.full_match.output
      feed = self.full_match.next
      candidate = MatchedKanaRule.new(rules, feed)
    else
      candidate = self
    end
  end
  return kakutei, feed, candidate
end

---
--- KanaRule[] により入力文字を変換する(ASCII to かな)
---
---@param rules KanaRule[]
---@param feed string キー入力
---@param candidate MatchedKanaRule?
---@return string 確定変換済み
---@return string 未使用のキー入力
---@return MatchedKanaRule?
function MatchedKanaRule.conv(rules, feed, candidate)
  local match = MatchedKanaRule.new(rules, feed)
  assert(match)
  local out, out_feed, new_candidate = match:resolve(rules, candidate)
  -- print(("%s + %s => %s %s: %s"):format(candidate, feed, new_candidate, out_feed, out))
  return out, out_feed, new_candidate
end

---@param src string
---@return string src
---@return string feed
function MatchedKanaRule.split(rules, src)
  local feed = ""
  -- 出力文字列
  local output = ""
  -- 部分一致が複数在って後続を見るまで確定できない
  ---@type MatchedKanaRule?
  local candidate
  for key in src:gmatch "." do
    -- 一文字ずつ処理する
    feed = feed .. key
    local tmp_output
    tmp_output, feed, candidate = MatchedKanaRule.conv(rules, feed, candidate)
    if tmp_output then
      output = output .. tmp_output
    end
  end

  while #feed > 0 do
    -- 入力の残り
    local tmp_output, tmp_feed, tmp_candidate = MatchedKanaRule.conv(rules, feed, candidate)
    candidate = tmp_candidate
    if tmp_output then
      output = output .. tmp_output
    end
    if feed == tmp_feed then
      break
    end
    feed = tmp_feed
  end

  return output, feed
end

return MatchedKanaRule
