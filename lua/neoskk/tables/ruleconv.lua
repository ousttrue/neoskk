local match_rules = require "neoskk.tables.match_rules"

---
--- KanaRule[] により入力文字を変換する(ASCII to かな)
---
---@param rules KanaRule[]
---@param src string キー入力
---@param _feed string?
---@return string 確定変換済み
---@return string 未使用のキー入力
local function ruleconv(rules, feed, candidate)
  local match = match_rules(rules, feed)
  return match:resolve(candidate)
end

return ruleconv
