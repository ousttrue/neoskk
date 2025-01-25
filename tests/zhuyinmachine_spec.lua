local ZhuyinMachine = require "neoskk.ZhuyinMachine"
local UniHanDict = require "neoskk.UniHanDict"
local CompletionItem = require "neoskk.CompletionItem"
local Completion = require "neoskk.Completion"

local dict = UniHanDict.new()
dict.zhuyin_map = {
  ["ㄏㄠ"] = { "好" },
}

describe("ZhuyinMachine", function()
  it("変換", function()
    local engine = ZhuyinMachine.new()
    local out, feed = engine:input("cl", dict)
    assert.are.equal("ㄏㄠ", feed)
    local _out, _feed, completion = engine:input(" ", dict)

    assert.are.equal("ㄏㄠ", _out)
    assert.are.equal("好", completion.items[1].user_data.replace)
  end)

  it("変換 enter", function()
    local engine = ZhuyinMachine.new()
    local out, feed = engine:input("cl", dict)
    out, feed = engine:input("\n\n", dict)
    assert.are.equal("ㄏㄠ\n", out)
  end)
end)
