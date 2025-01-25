local ZhuyinMachine = require "neoskk.ZhuyinMachine"

describe("zhuyin", function()
  it("multiple chars ", function()
    local zhuyin = ZhuyinMachine.new()
    local out, feed = zhuyin:input "1qaz2wsxedcrfv5tgbyhnujm8ik,9ol.0p;/-"
    assert.are.equal(
      "ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦ",
      feed
    )
  end)
end)
