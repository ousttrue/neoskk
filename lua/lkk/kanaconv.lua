local M = {}

local KanaTable = require "lkk.kana.kana_table"
local MatchedKanaRule = require("lkk.kana.kanarule").MatchedKanaRule

---@param src string キー入力
---@return string 確定変換済み
---@return string 未使用のキー入力
function M.to_kana(src)
  -- 出力文字列
  local output = ""
  -- 未使用のキー入力
  local feed = ""
  -- 部分一致が複数在って後続を見るまで確定できない
  ---@type MatchedKanaRule?
  local candidate = nil

  for key in src:gmatch "." do
    -- 一文字ずつ処理する
    local match = MatchedKanaRule.match_rules(candidate and candidate.prefix_matches or KanaTable, feed .. key)
    local tmp_output
    tmp_output, feed, candidate = match:resolve(candidate)
    if tmp_output then
      output = output .. tmp_output
    end
  end

  if feed then
    -- 入力の残り
    local match = MatchedKanaRule.match_rules(candidate and candidate.prefix_matches or KanaTable, feed)
    local tmp_output
    tmp_output, feed, candidate = match:resolve(candidate)
    if tmp_output then
      output = output .. tmp_output
    end
  end

  return output, feed
end

return M
