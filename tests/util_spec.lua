local util = require "neoskk.util"

describe("Utility", function()
  it("ひら to カタ", function()
    local src = string.match("あ", "[\u{30a1}-\u{30f6}]+")
    -- print(#src, src)
    -- assert.are.equal("あ", util.hira_to_kata "あ")

    -- assert.are.equal("ア", util.hira_to_kata "あ")
  end)
end)
