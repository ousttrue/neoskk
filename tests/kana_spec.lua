local ruleconv = require "neoskk.tables.ruleconv"
local KanaRules = require "neoskk.tables.KanaRules"

---@param src string
---@return string out
---@return string feed
local function to_kana(src)
  return ruleconv(KanaRules, src)
end

-- TODO 辞書を引数にする

describe("Tests for かな入力", function()
  it("single char", function()
    local kana = to_kana "ka"
    assert.are.equal("か", kana)
  end)

  it("imcomplete", function()
    local kana, feed = to_kana "k"
    assert.are.equal("", kana)
    assert.are.equal("k", feed)

    kana, feed = to_kana(feed .. "a")
    assert.are.equal("か", kana)
    assert.are.equal("", feed)
  end)

  it("multiple chars (don't use tmpResult)", function()
    local kana = to_kana "ohayou"
    assert.are.equal("おはよう", kana)
  end)

  it("multiple chars (use tmpResult)", function()
    local kana = to_kana "amenbo"
    assert.are.equal("あめんぼ", kana)
  end)

  it("multiple chars (use tmpResult and its next)", function()
    local kana = to_kana "uwwwa"
    assert.are.equal("うwっわ", kana)
  end)

  it("mistaken input", function()
    local kana = to_kana "rkakyra"
    assert.are.equal("rかkyら", kana)
  end)
end)
