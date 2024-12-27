local SkkMachine = require("neoskk.SkkMachine")

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
end)
