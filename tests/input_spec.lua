local Context = require "lkk.context"

---@param context Context
---@param input string
---@return string
local function test(context, input)
  -- dispatch(context, input)
  for key in input:gmatch "." do
    -- print(key)
    context:kanaInput(key)
  end
  return context.kakutei
end

describe("Tests for input.lua", function()
  it("single char", function()
    assert.are.equal("か", test(Context.new(), "ka"))
  end)

  it("multiple chars (don't use tmpResult)", function()
    assert.are.equal("おはよう", test(Context.new(), "ohayou"))
  end)

  it("multiple chars (use tmpResult)", function()
    assert.are.equal("あめんぼ", test(Context.new(), "amenbo"))
  end)

  it("multiple chars (use tmpResult and its next)", function()
    assert.are.equal("うwっわ", test(Context.new(), "uwwwa"))
  end)

  it("mistaken input", function()
    assert.are.equal("から", test(Context.new(), "rkakyra"))
  end)
end)
