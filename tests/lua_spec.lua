local SkkDict = require "neoskk.SkkDict"

describe("Tests for lua", function()
  it("string", function()
    assert.are.equal("b", ("abc"):sub(2, 2))

    assert.are.equal("", ("abc"):sub(2, 1))
  end)

  it("gmatch", function()
    local t = {}
    local src = [[# comment
1F695 ;	emoji ;	L1 ;	none ;	j	# V6.0 (🚕) TAXI
1F378 ;	emoji ;	L1 ;	none ;	j w	# V6.0 (🍸) COCKTAIL GLASS
]]

    for l in string.gmatch(src, "[^\n]+") do
      local item = SkkDict.split_emoji_line(l)
      if item then
        table.insert(t, item)
      end
    end

    assert.same({
      { "1F695", "emoji", "L1", "none", "j", "V6.0", "🚕", "TAXI" },
      { "1F378", "emoji", "L1", "none", "j w", "V6.0", "🍸", "COCKTAIL GLASS" },
    }, t)
  end)
end)
