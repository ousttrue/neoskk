local Context = require "lkk.context"

---@type Context
local context

local input = require "lkk.input"

---@param context Context
---@param keys string
local function dispatch(context, keys)
  for key in keys:gmatch "." do
    -- print(key)
    input.kanaInput(context, key)
  end
end

---@param input string
---@param expect string
local function test(input, expect)
  dispatch(context, input)
  assert.are.equals(expect, context.preEdit:output "")
end

describe("Tests for input.lua", function()
  before_each(function()
    context = Context.new()
  end)

  it("single char", function()
    test("ka", "か")
  end)

  it("multiple chars (don't use tmpResult)", function()
    test("ohayou", "おはよう")
  end)

  it("multiple chars (use tmpResult)", function()
    test("amenbo", "あめんぼ")
  end)

  it("multiple chars (use tmpResult and its next)", function()
    test("uwwwa", "うwっわ")
  end)

  it("mistaken input", function()
    test("rkakyra", "から")
  end)
end)
