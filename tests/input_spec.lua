local kanaconv = require "neoskk.kanaconv"

describe("Tests for input.lua", function()
  it("single char", function()
    local kana = kanaconv.to_kana "ka"
    assert.are.equal("か", kana)
  end)

  it("single char", function()
    local kana, feed = kanaconv.to_kana "k"
    assert.are.equal("", kana)
    assert.are.equal("k", feed)

    kana, feed = kanaconv.to_kana(feed .. "a")
    assert.are.equal("か", kana)
    assert.are.equal("", feed)
  end)

  it("multiple chars (don't use tmpResult)", function()
    local kana = kanaconv.to_kana "ohayou"
    assert.are.equal("おはよう", kana)
  end)

  it("multiple chars (use tmpResult)", function()
    local kana = kanaconv.to_kana "amenbo"
    assert.are.equal("あめんぼ", kana)
  end)

  it("multiple chars (use tmpResult and its next)", function()
    local kana = kanaconv.to_kana "uwwwa"
    assert.are.equal("うwっわ", kana)
  end)

  it("mistaken input", function()
    local kana = kanaconv.to_kana "rkakyra"
    assert.are.equal("から", kana)
  end)
end)
