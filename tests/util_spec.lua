local util = require "neoskk.util"
local utf8 = require "neoskk.utf8"

describe("Utility", function()
  it("split", function()
    assert.same({ "a", "c" }, util.splited("abc", "b"))
    assert.same({ "1", "", "3" }, util.splited("1,,3", ","))
    assert.same(
      { "hoge", "huga" },
      util.splited [[hoge
huga
]]
    )

    assert.same({ "a", "c" }, util.to_list(util.split, { "abc", "b" }))
  end)

  it("strip", function()
    assert.equal("a", util.strip " a ")
    assert.equal("a", util.strip "a ")
    assert.equal("a", util.strip " a")
    local b, e = string.find("a", "^%s*")
    assert.equal(1, b)
    assert.equal(0, e)
    local b, e = string.find("a", "%s*$")
    assert.equal(2, b)
    assert.equal(1, e)
  end)

  it("to_list", function()
    assert.same({ 1, 2, 3 }, util.to_list(next, { 1, 2, 3 }))
    assert.same({ 1, 2, 3 }, util.to_list(ipairs { 1, 2, 3 }))
    assert.same({ 1, 2, 3 }, util.to_list(pairs { 1, 2, 3 }))
    -- assert.same({ a = 1, b = 2, c = 3 }, util.to_list(next, { a = 1, b = 2, c = 3 }))
    -- assert.same({ a = 1, b = 2, c = 3 }, util.to_list(pairs { a = 1, b = 2, c = 3 }))

    assert.same(
      { 1, 2, 3 },
      util.to_list(
      ---@param _ any
      ---@param n integer?
        function(_, n)
          if not n then
            return 1, 1
          elseif n < 3 then
            return n + 1, n + 1
          end
        end
      )
    )
  end)

  it("utf8", function()
    assert.same({
      "東",
      "菄",
      "鶇",
      "䍶",
      "𠍀",
      "倲",
      "𩜍",
      "𢘐",
      "涷",
      "蝀",
      "凍",
      "鯟",
      "𢔅",
      "崠",
      "埬",
      "𧓕",
      "䰤",
    }, util.to_list(utf8.codes "東菄鶇䍶𠍀倲𩜍𢘐涷蝀凍鯟𢔅崠埬𧓕䰤"))
  end)

  it("join", function()
    assert.Equal("ab", util.join { "a", "b" })
    assert.Equal("a,b", util.join({ "a", "b" }, ","))
    assert.Equal("ab", util.join { "a", "b" }, "")
  end)

  it("hex", function()
    assert.Equal("f", util.hex(15))
    assert.Equal("ff", util.hex(255))
  end)
end)
