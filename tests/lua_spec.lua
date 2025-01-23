describe("Tests for lua", function()
  it("string", function()
    assert.are.equal("b", ("abc"):sub(2, 2))

    assert.are.equal("", ("abc"):sub(2, 1))

    local function one_tow_three(_, n)
      if n then
        if n >= 3 then
          return
        end
        return n + 1
      else
        return 1
      end
    end
    local t = {}
    for n in one_tow_three, 0 do
      table.insert(t, n)
    end
    assert.same({ 1, 2, 3 }, t)
  end)
end)
