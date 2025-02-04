---反切系聯法
local FanqieShang = require("neoskk.fanqie").FanqieShang

---@class XiLian
---@field hi FanqieShang[] 半切上字
---@field low FanqieXia[] 半切下字
local XiLian = {}
XiLian.__index = XiLian

---@param list XiaoYun[] 小韻のリスト
---@return XiLian
function XiLian.parse(list)
  local self = setmetatable({
    hi = {},
    low = {},
  }, XiLian)

  for _, xiaoyun in ipairs(list) do
    local found = false
    local hi = xiaoyun:fanqie_hi()
    if hi then
      for _, g in ipairs(self.hi) do
        if g:keiren(xiaoyun) then
          g.map[hi] = true
          found = true
          break
        end
      end

      if not found then
        local new_group = FanqieShang.new(xiaoyun.shengniu)
        new_group.map[hi] = true
        table.insert(self.hi, new_group)
      end
    end
  end
  -- print(#groups, "Group")

  -- for _, g in ipairs(groups) do
  --   print(g.list[1].shengniu)
  -- end
  return self
end

---@return FanqieShang?
function XiLian:from_shengniu(shengniu)
  for _, g in ipairs(self.hi) do
    if g.shengniu == shengniu then
      return g
    end
  end
  return nil
end

return XiLian
