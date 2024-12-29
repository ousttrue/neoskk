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
MatchedKanaRule = {}
MatchedKanaRule.__index = MatchedKanaRule

---@param prefix string
---@return MatchedKanaRule
function MatchedKanaRule.new(prefix)
  return setmetatable({
    prefix = prefix,
    prefix_matches = {},
  }, MatchedKanaRule)
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

---@param candidate MatchedKanaRule?
---@return string 確定
---@return string 未使用
---@return MatchedKanaRule? 未確定
function MatchedKanaRule.resolve(self, candidate)
  local kakutei = ""
  local feed = self.prefix
  if #self.prefix_matches == 0 then
    -- マッチしない
    if candidate then
      -- candidate を確定
      kakutei = candidate.full_match.output
      --  candidate が消費した分を削る
      feed = candidate.full_match.next .. self.prefix:sub(#candidate.full_match.input + 1)
      candidate = nil
    else
      -- １文字確定
      kakutei = self.prefix:sub(1, 1)
      feed = self.prefix:sub(2)
    end
  else
    if self.full_match then
      if #self.prefix_matches == 1 then
        kakutei = kakutei .. self.full_match.output
        feed = self.full_match.next
      else
        candidate = self
      end
    end
  end
  return kakutei, feed, candidate
end

---inputとの前方一致で絞り込む
---@param rules KanaRule[]
---@param pre string
---@return MatchedKanaRule
local function match_rules(rules, pre)
  local match = MatchedKanaRule.new(pre)
  for _, item in ipairs(rules) do
    match:push(item)
  end
  return match
end

return match_rules
