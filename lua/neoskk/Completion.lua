local CompletionItem = require "neoskk.CompletionItem"

local SKK_OPTS = 0
local FUZZY_OPTS = 1

---@alias COMPLETION_OPTS `SKK_OPTS` | `FUZZY_OPTS`

---@class Completion
---@field items CompletionItem[]
---@field opts COMPLETION_OPTS

local Completion = {
  SKK_OPTS = SKK_OPTS,
  FUZZY_OPTS = FUZZY_OPTS,
}
Completion.__index = Completion

---@param items (CompletionItem|string)[]?
---@param opts COMPLETION_OPTS?
---@return Completion
function Completion.new(items, opts)
  local self = setmetatable({
    items = items and items or {},
    opts = opts and opts or SKK_OPTS,
  }, Completion)
  return self
end

function Completion.__eq(a, b)
  if #a ~= #b then
    return false
  end

  if a.opts ~= b.opts then
    return false
  end

  for i, x in ipairs(a) do
    local found = false
    for j, y in ipairs(b) do
      if x == y then
        found = true
        break
      elseif type(x) == "table" and type(y) == "string" and x.word == y then
        found = true
        break
      elseif type(x) == "string" and type(y) == "table" and x == y.word then
        found = true
        break
      end
    end
    if not found then
      return false
    end
  end

  return true
end

return Completion
