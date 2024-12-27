local match_rules = require "neoskk.tables.match_rules"

---
--- KanaRule[] により入力文字を変換する(ASCII to かな)
---
---@param rules KanaRule[]
---@param src string キー入力
---@param _feed string?
---@return string 確定変換済み
---@return string 未使用のキー入力
local function ruleconv(rules, src, _feed)
  -- 出力文字列
  local output = ""
  -- 未使用のキー入力
  local feed = _feed and _feed or ""
  -- 部分一致が複数在って後続を見るまで確定できない
  ---@type MatchedKanaRule?
  local candidate = nil

  for key in src:gmatch "." do
    -- 一文字ずつ処理する
    feed = feed .. key
    local match = match_rules(candidate and candidate.prefix_matches or rules, feed)
    local tmp_output
    tmp_output, feed, candidate = match:resolve(candidate)
    if tmp_output then
      output = output .. tmp_output
    end
  end

  while #feed > 0 do
    -- 入力の残り
    local match = match_rules(candidate and candidate.prefix_matches or rules, feed)
    local tmp_output, tmp_feed, tmp_candidate = match:resolve(candidate)
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

return ruleconv
