local util = require "neoskk.util"
local utf8 = require "neoskk.utf8"
local UniHanDict = require "neoskk.UniHanDict"
local yun = require "neoskk.yun"
local GuangYun = require "neoskk.GuangYun"

local uv = require "luv"

local file = os.getenv "GUANGYUN"
assert(file, "env")

local data = util.readfile_sync(uv, file)
assert(data, "file")

local dict = UniHanDict.new()
dict:load_quangyun(data)

local guangyun = GuangYun.new()
guangyun:load(data)

describe("韻目", function()
  it("小韻", function()
    assert.equal(3883, #dict.xiaoyun_list)

    local xiao = dict:xiaoyun_from_char "東"
    assert(xiao)
    assert.equal(17, #xiao.chars)

    xiao = dict:xiaoyun_from_char "覺"
    assert(xiao)
    assert.equal("覺", xiao.name)

    assert.equal("`東`董送屋", yun.get_group "東")
    assert.equal("江講絳`覺`", yun.get_group "覺")
    assert.equal("蒸拯證`職`", yun.get_group "德")
    assert.equal("眞軫震`質`", yun.get_group "質")
  end)
end)

describe("廣韻", function()
  it("韻目", function()
    assert.equal(3874, #guangyun.list)
    for i, yun in ipairs(guangyun.list) do
      assert.equal(i, yun.no)
    end
    assert.equal("東", guangyun.list[1].name)
    assert.equal(guangyun:find_char "凍", guangyun.list[1])

    assert.equal("薛", guangyun:find_char("列").name)
  end)

  it("声母", function()
    -- assert.equal("", guangyun:get_sheng "東")
  end)
end)
