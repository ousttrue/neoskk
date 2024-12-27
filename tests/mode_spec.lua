local SkkMachine = require "neoskk.SkkMachine"

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

  it("変換", function()
    local jisyo = { ["あ"] = { { word = "亜" } } }
    local engine = SkkMachine.new()
    local out, feed = engine:input "A"
    assert.are.equal("あ", feed)
    out, feed = engine:input(" ", jisyo)
    assert.are.equal("亜", out)
  end)

  it("変換 q", function()
    local engine = SkkMachine.new()
    local out, feed = engine:input "A"
    out, feed = engine:input "q"
    assert.are.equal("ア", feed)
  end)
end)
