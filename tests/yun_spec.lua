local util = require "neoskk.util"
local utf8 = require "neoskk.utf8"
local UniHanDict = require "neoskk.UniHanDict"

local uv = require "luv"

local file = os.getenv "GUANGYUN"
assert(file, "env")

local data = util.readfile_sync(uv, file)
assert(data, "file")

local dict = UniHanDict.new()
dict:load_quangyun(data)

describe("韻目", function()
  it("小韻", function()
    assert.equal(3883, #dict.xiaoyun_list)

    local xiao = dict:xiaoyun_from_char "東"
    assert.equal(17, #xiao.chars)
  end)
end)
