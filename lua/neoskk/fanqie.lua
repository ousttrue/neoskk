local utf8 = require "neoskk.utf8"

---@class FanqieShang 半切上字
---@field map table<string, true> 含まれる半切上字
local FanqieShang = {}
FanqieShang.__index = FanqieShang

---@return FanqieShang
function FanqieShang.new()
  local self = setmetatable({
    map = {},
  }, FanqieShang)
  return self
end

function FanqieShang:push(xiaoyun)
  local hi = xiaoyun:fanqie_hi()
  self.map[hi] = true
  -- for _, ch in ipairs(xiaoyun.chars) do
  --   self.map[ch] = true
  -- end
end

---半切上字が同音であるか?
---@param xiaoyun XiaoYun
---@return boolean
function FanqieShang:keiren(xiaoyun)
  -- 半切上字
  local l = xiaoyun:fanqie_hi()

  for x, _ in pairs(self.map) do
    if x == l then
      -- 同じ半切上字がある
      return true
    end
  end

  return false
end

---@class FanqieXia 半切下字
---@field list XiaoYun[]
local FanqieXia = {}
FanqieXia.__index = FanqieXia

function FanqieXia.new()
  local self = setmetatable({
    list = {},
  }, FanqieXia)
  return self
end

local M = {
  FanqieShang = FanqieShang,
  FanqieXia = FanqieXia,
}

return M
