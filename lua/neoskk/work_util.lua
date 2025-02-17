---@class NeoSkkOpts
---@field jisyo string? path to SKK-JISYO.L from https://github.com/skk-dict/jisyo
---@field unihan_dir string? path to dir. Extracted https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
---@field xszd string? path to xszd.txt from https://github.com/cjkvi/cjkvi-dict
---@field kangxi string? kx2ucs.txt from https://github.com/cjkvi/cjkvi-dict
---@field chinadat string? path to chinadat.csv from https://www.seiwatei.net/info/dnchina.htm
---@field guangyun string? path to Kuankhiunn0704-semicolon.txt from https://github.com/syimyuzya/guangyun0704
---@field user string? path to user_dict.json
---@field dir string basedir

---@param encoded string
---@return string string.buffer encoded
local function parse_unihan(encoded)
  local opts = require("string.buffer").decode(encoded)
  ---@cast opts NeoSkkOpts
  local UniHanDict = require "neoskk.UniHanDict"
  local dict = UniHanDict.new()
  local util = require "neoskk.util"
  local utf8 = require "neoskk.utf8"

  local unihan_dir = opts.unihan_dir or opts.dir
  local data = util.readfile_sync(vim.uv, unihan_dir .. "/Unihan_DictionaryLikeData.txt")
  if data then
    for unicode, k, v in string.gmatch(data, UniHanDict.UNIHAN_PATTERN) do
      local codepoint = tonumber(unicode, 16)
      local ch = utf8.char(codepoint)
      local item = dict:get_or_create(ch)
      -- assert(item)
      if k == "kFourCornerCode" then
        item.goma = v
      end
    end
  end

  data = util.readfile_sync(vim.uv, unihan_dir .. "/Unihan_Readings.txt")
  if data then
    dict:load_unihan_readings(data)
  end

  data = util.readfile_sync(vim.uv, unihan_dir .. "/Unihan_Variants.txt")
  if data then
    dict:load_unihan_variants(data)
  end

  data = util.readfile_sync(vim.uv, unihan_dir .. "/Unihan_OtherMappings.txt")
  if data then
    dict:load_unihan_othermappings(data)
  end

  if opts.guangyun then
    data = util.readfile_sync(vim.uv, opts.guangyun)
    if data then
      dict:load_quangyun(data)
    end
  end

  if opts.kangxi then
    data = util.readfile_sync(vim.uv, opts.kangxi)
    if data then
      dict:load_kangxi(data)
    end
  end

  if opts.xszd then
    data = util.readfile_sync(vim.uv, opts.xszd)
    if data then
      dict:load_xszd(data)
    end
  end

  if opts.chinadat then
    data = util.readfile_sync(vim.uv, opts.chinadat)
    if data then
      dict:load_chinadat(data)
    end
  end

  ---@type string[]
  local jisyo = {}
  if type(opts.jisyo) == "string" then
    table.insert(jisyo, opts.jisyo)
  elseif type(opts.jisyo) == "table" then
    for _, j in ipairs(opts.jisyo) do
      table.insert(jisyo, j)
    end
  end
  if #jisyo == 0 then
    table.insert(jisyo, opts.dir .. "/SKK-JISYO.L")
    table.insert(jisyo, opts.dir .. "/SKK-JISYO.china_taiwan")
  end

  -- for _, j in ipairs(jisyo) do
  --   data = util.readfile_sync(vim.uv, j, "euc-jp", "utf-8", {})
  --   if data then
  --     dict:load_skk(data)
  --   end
  -- end

  if opts.user then
    data = util.readfile_sync(vim.uv, opts.user)
    if data then
      local json = vim.json.decode(data)
      dict:load_user(json)
    end
  end

  return require("string.buffer").encode(dict)
end

local M = {}

---@param opts NeoSkkOpts
function M.async_load(opts, on_completed)
  local async = require "plenary.async"
  async.void(function()
    local function async_parse(src, callback)
      local work = vim.uv.new_work(parse_unihan, callback)
      return work:queue(src)
    end
    local encoded = async.wrap(async_parse, 2)(require("string.buffer").encode(opts))
    assert(encoded)
    ---@diagnostic disable
    local dict = require("string.buffer").decode(encoded)
    ---@cast dict UniHanDict
    on_completed(dict)
    -- print(vim.inspect(dict))
  end)()
end

return M
