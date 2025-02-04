local utf8 = require "neoskk.utf8"

---@class FanqieShang 半切上字
---@field shengniu string?
---@field map table<string, true>
local FanqieShang = {}
FanqieShang.__index = FanqieShang

---@param shengniu string?
---@return FanqieShang
function FanqieShang.new(shengniu)
  local self = setmetatable({
    shengniu = shengniu,
    map = {},
  }, FanqieShang)
  return self
end

---@param src string
---@param shengniu string?
---@return FanqieShang
function FanqieShang.parse(src, shengniu)
  local self = FanqieShang.new(shengniu)
  for _, code in utf8.codes(src) do
    if #code > 1 then
      self.map[code] = true
    end
  end
  return self
end

---@return string
function FanqieShang:__tostring()
  local s = self.shengniu .. ":"
  for x, _ in pairs(self.map) do
    s = s .. x
  end
  return s
end

---@param xiaoyun XiaoYun
---@return boolean
function FanqieShang:keiren(xiaoyun)
  -- 半切上字
  local l = xiaoyun:fanqie_hi()
  if not l then
    return false
  end

  for x, _ in pairs(self.map) do
    if self.shengniu == xiaoyun.shengniu then
      return true
    end

    if xiaoyun:fanqie_hi() ~= x then
      local r = x
      if l == r then
        return true
      end
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
