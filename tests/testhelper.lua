-- local version = _VERSION:match("%d+%.%d+")

local function dirname(src)
  local found = src:find "tests[/\\]testhelper.lua$"
  if found then
    if found==1 then
      return "."
    end
    return src:sub(1, found)
  end

  return src
end

local file = debug.getinfo(1, "S").source:sub(2)
local dir = dirname(file)
-- print("file=>", dir)

package.path = ([[%s/lua/?.lua;%s/lua/?/init.lua;]]):format(dir, dir) .. package.path

-- print(package.path)
