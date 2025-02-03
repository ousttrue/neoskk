local kana_util = require "neoskk.kana_util"
local utf8 = require "neoskk.utf8"

describe("Utility", function()
  it("ひらかな カタカナ", function()
    assert.is_true(kana_util.codepoint_is_hirakana(utf8.codepoint "あ"))
    assert.is_true(kana_util.codepoint_is_katakana(utf8.codepoint "ア"))
    assert.are.equal("いろは", kana_util.str_to_hirakana "イロハ")
    assert.are.equal("ニホヘ", kana_util.str_to_katakana "にほへ")
    assert.are.equal("あア", kana_util.str_toggle_kana "アあ")
    assert.are.equal("がー", kana_util.str_to_hirakana "ガー")
  end)
end)
