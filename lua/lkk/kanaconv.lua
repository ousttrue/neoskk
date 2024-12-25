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

---@param feed string
---@param candidates KanaRule[]
---@return KanaRule?
local function updateTmpResult(feed, candidates)
  for _, candidate in ipairs(candidates) do
    if candidate.input == feed then
      return candidate
    end
  end
end

---@param char string
---@param kakutei string?
---@param feed string?
---@param tmpResult KanaRule?
---@return string
---@return string
---@return KanaRule?
local function kanaInput(char, kakutei, feed, tmpResult)
  local input = (feed and feed or "") .. char
  local candidates = filter(input)
  if #candidates == 1 and candidates[1].input == input then
    -- 候補が一つかつ完全一致。確定
    kakutei = kakutei .. candidates[1].output
    feed = candidates[1].next
    return kakutei, feed, tmpResult
  elseif #candidates > 0 then
    -- 未確定
    feed = input
    tmpResult = updateTmpResult(feed, candidates)
    return kakutei and kakutei or "", feed, tmpResult
  elseif tmpResult then
    -- 新しい入力によりtmpResultで確定
    kakutei = kakutei .. tmpResult.output
    feed = tmpResult.next
    return kanaInput(char, kakutei, feed, tmpResult)
  else
    -- 入力ミス。self.tmpResultは既にnil
    return kanaInput(char, kakutei, "", tmpResult)
  end
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
    kakutei, feed, tmpResult = kanaInput(key, kakutei, feed, tmpResult)
  end
  return kakutei, feed and feed or ""
end

return M
