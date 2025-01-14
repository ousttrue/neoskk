describe("Tests for lua", function()
  it("string", function()
    assert.are.equal("b", ("abc"):sub(2, 2))

    assert.are.equal("", ("abc"):sub(2, 1))
  end)
end)


