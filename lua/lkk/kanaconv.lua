local M = {}

---@class KanaInputState
---@field feed string
M.KanaInputState = {}

---@param feed string?
function M.KanaInputState.new(feed)
  local self = setmetatable({
    __index = M.KanaInputState,
    feed = feed and feed or "",
  }, M.KanaInputState)
  return self
end

local Context = require "lkk.context"

---@param src string
---@param state KanaInputState?
---@return string
---@return KanaInputState
function M.to_kana(src, state)
  local context = Context.new()
  if state then
    context.feed = state.feed
  end
  for key in src:gmatch "." do
    context:kanaInput(key)
  end
  return context.kakutei, M.KanaInputState.new(context.feed)
end

return M
