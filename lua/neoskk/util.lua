local M = {}

---@generic IMMUTABLE
---@generic MUTABLE
---@generic T
---@param iter fun(immutable: IMMUTABLE, mutable: MUTABLE):MUTABLE?, T?
---@param immutable IMMUTABLE?
---@param mutable MUTABLE?
---@return T[]
function M.to_list(iter, immutable, mutable)
  local list = {}
  for _, v in iter, immutable, mutable do
    table.insert(list, v)
  end
  return list
end

---@param l table
---@param r table
function M.insert_all(l, r)
  for _, x in ipairs(r) do
    table.insert(l, x)
  end
end

function M.take(l, n)
  if n >= #l then
    return l
  end

  local list = {}
  for i = 1, n do
    table.insert(list, l[i])
  end
  return list
end

---@param list string[]
---@param delimiter string?
function M.join(list, delimiter)
  local t = ""
  if not delimiter then
    delimiter = ""
  end
  for i, v in ipairs(list) do
    if i > 1 then
      t = t .. delimiter
    end
    t = t .. v
  end
  return t
end

---@param immutable[string, string, boolean?] str, delimiter, is_plain
---@param init integer? last delimiter end
---@return integer? next delimiter end
---@return string? token
function M.split(immutable, init)
  local str, ts, plain = unpack(immutable)
  assert(str)

  if not init then
    init = 0
  end

  if init < #str then
    local s, e = string.find(str, ts, init + 1, plain)
    if s then
      return e, str:sub(init + 1, s - 1)
    else
      return #str, str:sub(init + 1)
    end
  end
end

---@param str string
---@param ts string?
---@param plain boolean?
---@return string[]
function M.splited(str, ts, plain)
  if not ts then
    if plain then
      ts = " "
    else
      ts = "%s"
    end
  end
  return M.to_list(M.split, { str, ts, plain })
end

---@param src string
---@return string
function M.strip(src)
  if not src then
    return ""
  end
  local hs, be = src:find "^%s*"

  local ts, te = src:find "%s*$"

  return src:sub(be + 1, ts - 1)
end

---@param i integer
function M.hex(i)
  -- return ("%X"):format(i)
  return ("%x"):format(i)
end

-- ---@param str string
-- ---@param ts string?
-- ---@param plain boolean?
-- ---@return string[]
-- function M.splited(str, ts, plain)
--   -- 引数がないときは空tableを返す
--   assert(str)
--   if not ts then
--     if plain then
--       ts = " "
--     else
--       ts = "%s"
--     end
--   end
--
--   local t = {}
--   local i = 1
--   while i <= #str do
--     local s, e = string.find(str, ts, i, plain)
--     if s then
--       table.insert(t, str:sub(i, s - 1))
--       i = e + 1
--     else
--       table.insert(t, str:sub(i))
--       break
--     end
--   end
--
--   return t
-- end

---@param uv uv
---@param path string
---@return integer? fd
---@return integer? size
function M.open_read(uv, path)
  local stat = uv.fs_stat(path)
  if not stat then
    return
  end
  return assert(uv.fs_open(path, "r", 0)), stat.size
end

---@param uv uv
---@param path string
---@param from string?
---@param to string?
---@param opts table? vim.iconv opts
---@return string?
function M.readfile_sync(uv, path, from, to, opts)
  if not uv.fs_stat(path) then
    return
  end
  local fd = assert(uv.fs_open(path, "r", 0))
  local stat = assert(uv.fs_fstat(fd))
  local data = assert(uv.fs_read(fd, stat.size, 0))
  assert(uv.fs_close(fd))
  if from and to then
    data = assert(vim.iconv(data, from, to, opts))
  end
  return data
end

---@param uv uv
---@param path string
---@param data string
---@param from string?
---@param to string?
---@param opts table? vim.iconv opts
function M.writefile_sync(uv, path, data, from, to, opts)
  if from and to then
    print(("writefile_sync: %s => %s"):format(from, to))
    data = assert(vim.iconv(data, from, to, opts))
  end
  local fd = assert(uv.fs_open(path, "w", tonumber("0666", 8)))
  uv.fs_write(fd, data)
  assert(uv.fs_close(fd))
end

---@param t table
---@param x any
---@return boolean
function M.contains(t, x)
  for _, v in pairs(t) do
    if v == x then
      return true
    end
  end
  return false
end

---@return string
function M.get_current_line_cursor_left()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col "."
  return line:sub(1, col - 1)
end

return M
