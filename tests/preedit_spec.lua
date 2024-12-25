local PreEdit = require "lkk.preedit"

describe("preedit test", function()
  it("normal", function()
    local preEdit = PreEdit.new()
    -- input 'ひら'
    assert.are.equal("h", preEdit:output "h")
    preEdit:doKakutei "ひ"
    assert.are.equal("\bひ", preEdit:output "")
    assert.are.equal("r", preEdit:output "r")
    preEdit:doKakutei "ら"
    assert.are.equal("\bら", preEdit:output "")
  end)

  it("emoji", function()
    local preEdit = PreEdit.new()
    assert.are.equal("💩", preEdit:output "💩")
    assert.are.equal("\b🚽", preEdit:output "🚽")
    assert.are.equal("\b🍦", preEdit:output "🍦")
  end)
end)
