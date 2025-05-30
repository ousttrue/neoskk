local util = require "neoskk.util"
local utf8 = require "neoskk.utf8"
local UniHanDict = require "neoskk.UniHanDict"
local yun = require "neoskk.yun"
local GuangYun = require "neoskk.GuangYun"
local FanqieShang = require("neoskk.fanqie").FanqieShang
local XiLian = require "neoskk.XiLian"

local uv = require "luv"

local dir = os.getenv "GHQ_ROOT"
assert(dir, "env: GHQ_ROOT")

local data = util.readfile_sync(uv, dir .. "/github.com/syimyuzya/guangyun0704/Kuankhiunn0704-semicolon.txt")
assert(data, "file")

local dict = UniHanDict.new()
dict:load_quangyun(data)

local guangyun = GuangYun.new()
guangyun:load(data)

describe("韻目", function()
  it("小韻", function()
    assert.equal("`東`董送屋", yun.get_group "東")
    assert.equal("江講絳`覺`", yun.get_group "覺")
    assert.equal("蒸拯證`職`", yun.get_group "德")
    assert.equal("眞軫震`質`", yun.get_group "質")
  end)
end)

describe("廣韻", function()
  it("韻目", function()
    assert.equal(3874, #guangyun.list)
    for i, xiaoyun in ipairs(guangyun.list) do
      assert.equal(i, xiaoyun.no)
    end
    assert.equal("東", guangyun.list[1].name)
    assert.equal(guangyun:xiaoyun_from_char "凍", guangyun.list[1])

    assert.equal("薛", guangyun:xiaoyun_from_char("列").name)

    local xiao = guangyun:xiaoyun_from_char "東"
    assert(xiao)
    assert.equal(17, #xiao.chars)

    xiao = guangyun:xiaoyun_from_char "覺"
    assert(xiao)
    assert.equal("覺", xiao.name)
  end)

  it("声紐", function()
    local xilian = XiLian.parse(guangyun.list)
    -- assert.equal(38, #xilian.hi)
  end)
end)
