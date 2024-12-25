local M = {}

local KanaTable = require "lkk.kana.kana_table"

local function string_startswith(self, start)
  return self:sub(1, #start) == start
end

---inputとの前方一致で絞り込む
---@param pre string
---@return KanaRule[]
local function filter(pre)
  local items = {}
  for i, item in ipairs(KanaTable) do
    if string_startswith(item.input, pre) then
      table.insert(items, item)
    end
  end
  return items
end

---@param input string
---@return string|KanaRule|nil 確定|未確定
---@return string 未使用
local function kanaInput(input)
  local candidates = filter(input)
  if #candidates == 0 then
    return nil, input
  end

  if #candidates == 1 and candidates[1].input == input then
    -- 1 候補が一つかつ完全一致。確定
    return candidates[1].output, candidates[1].next
  end

  for _, candidate in ipairs(candidates) do
    if candidate.input == input then
      -- 2 未確定
      return candidate, input
    end
  end

  -- 3 入力を先送り
  return "", input
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
