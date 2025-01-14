local util = require "neoskk.util"
local utf8 = require "neoskk.utf8"

describe("Utility", function()
  it("ひらかな カタカナ", function()
    assert.is_true(util.codepoint_is_hirakana(utf8.codepoint "あ"))
    assert.is_true(util.codepoint_is_katakana(utf8.codepoint "ア"))
    assert.are.equal("いろは", util.str_to_hirakana "イロハ")
    assert.are.equal("ニホヘ", util.str_to_katakana "にほへ")
    assert.are.equal("あア", util.str_toggle_kana "アあ")
  end)

  it("split", function()
    assert.same({ "a", "c" }, util.split("abc", "b"))
    assert.same(
      { "hoge", "huga" },
      util.split [[hoge
huga
]]
    )

    assert.same(
      { "00A9", "text", "L1", "none", "j	# V1.1 (©) COPYRIGHT SIGN" },
      util.split("00A9 ;	text ;	L1 ;	none ;	j	# V1.1 (©) COPYRIGHT SIGN", "%s*;%s*")
    )
  end)
end)
