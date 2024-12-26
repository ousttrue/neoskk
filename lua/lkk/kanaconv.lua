local M = {}

local KanaTable = require "lkk.kana.kana_table"

local function string_startswith(self, start)
  return self:sub(1, #start) == start
end

---inputとの前方一致で絞り込む
---@param pre string
---@return KanaRule? full match
---@return integer prefix match count
local function match_rules(pre)
  local found = nil
  local match_count = 0
  for _, item in ipairs(KanaTable) do
    if string_startswith(item.input, pre) then
      match_count = match_count + 1
      if item.input == pre then
        found = item
      end
    end
  end
  return found, match_count
end

---@param input string
---@return string|KanaRule|nil 確定|未確定
---@return string 未使用
local function kanaInput(input)
  local candidate, match_count = match_rules(input)
  if match_count == 0 then
    return nil, input
  end

  if not candidate then
    -- 3 入力を先送り
    return "", input
  end
  assert(candidate)

  if match_count == 1 then
    -- 1 候補が一つ
    return candidate.output, candidate.next
  end
  assert(match_count > 1)

  -- 2 未確定
  return candidate, input
end

---@param src string キー入力
---@return string 確定変換済み
---@return string 未使用のキー入力
function M.to_kana(src)
  local kakutei = ""
  local feed = ""
  local tmpResult = nil

  for key in src:gmatch "." do
    -- 一文字ずつ処理する
    local result, new_feed = kanaInput(feed .. key)
    if type(result) == "string" then
      -- 1 / 3
      kakutei = kakutei .. result
    elseif type(result) == "table" then
      -- 2
      tmpResult = result
    else
      if tmpResult then
        kakutei = kakutei .. tmpResult.output
      end
      -- １文字すてる
      -- TODO: tmpResult が消費した分を削る
      new_feed = new_feed:sub(2)
    end
    feed = new_feed
  end

  if feed then
    -- 入力の残り
    local result, new_feed = kanaInput(feed)
    if type(result) == "string" then
      -- 1 / 3
      kakutei = kakutei .. result
    elseif type(result) == "table" then
      -- 2
      tmpResult = result
    else
      if tmpResult then
        kakutei = kakutei .. tmpResult.output
      end
      -- １文字すてる
      -- TODO: tmpResult が消費した分を削る
      new_feed = new_feed:sub(2)
    end
    feed = new_feed
  end

  return kakutei, feed and feed or ""
end

return M
