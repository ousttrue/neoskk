local SkkMachine = require "neoskk.SkkMachine"
local Skkdict = require "neoskk.SkkDict"
local CompletionItem = require "neoskk.CompletionItem"
local Completion = require "neoskk.Completion"

local dict = Skkdict.new()
dict.jisyo = {
  ["あ"] = { { word = "亜" } },
  ["あるk"] = { { word = "歩" } },
}

describe("Tests for 変換モード", function()
  it("q", function()
    local engine = SkkMachine.new()
    assert.are.equal(SkkMachine.HIRAKANA, engine.input_mode)

    engine:input "q"
    assert.are.equal(SkkMachine.KATAKANA, engine.input_mode)
    assert.are.equal("カ", engine:input "ka")

    engine:input "q"
    assert.are.equal(SkkMachine.HIRAKANA, engine.input_mode)
    assert.are.equal("か", engine:input "ka")
  end)

  it("backspace", function()
    local engine = SkkMachine.new()

    local out, feed = engine:input "b"
    assert.are.equal("", out)
    assert.are.equal("b", feed)

    out, feed = engine:input "\b"
    assert.are.equal("", out)
    assert.are.equal("", feed)
  end)

  it("Dict", function()
    local item = CompletionItem.new { word = "a" }
    assert.are_equal(CompletionItem.new { word = "a" }, item)
    assert.are_not_equal(CompletionItem.new { word = "b" }, item)
  end)

  it("変換", function()
    local engine = SkkMachine.new()
    local out, feed = engine:input "A"
    assert.are.equal("あ", feed)
    local _out, _feed, completion = engine:input(" ", dict)

    assert.are.equal("あ", _out)
    assert.are.equal(Completion.new { "亜" }, completion)
  end)

  it("変換;", function()
    local engine = SkkMachine.new()
    local out, feed = engine:input ";a"
    assert.are.equal("あ", feed)
    local _out, _feed, completion = engine:input(" ", dict)

    assert.are.equal("あ", _out)
    assert.are.equal(Completion.new { "亜" }, completion)
  end)

  it("変換 okuri", function()
    local engine = SkkMachine.new()
    local out, feed, completion = engine:input("AruKu", dict)

    assert.are.equal("あるく", out)
    assert.are.equal(Completion.new { "歩" }, completion)
  end)

  it("変換 q", function()
    local engine = SkkMachine.new()
    local out, feed = engine:input "A"
    out, feed = engine:input "q"
    assert.are.equal("ア", out)
  end)

  it("変換 enter", function()
    local engine = SkkMachine.new()
    local out, feed = engine:input "A"
    out, feed = engine:input "\n"
    assert.are.equal("あ\n", out)
  end)
end)
