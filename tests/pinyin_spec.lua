local pinyin = require "neoskk.pinyin"

describe("Tests for pinyin", function()
  it("pinyin", function()
    local z, d = pinyin:to_zhuyin "gāo"
    assert.equal("ㄍㄠ", z)
    assert.equal(1, d)
  end)
end)
