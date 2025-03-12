---@class NeoSkkOpts
---@field jisyo string? path to SKK-JISYO.L from https://github.com/skk-dict/jisyo
---@field unihan_dir string? path to dir. Extracted https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
---@field xszd string? path to xszd.txt from https://github.com/cjkvi/cjkvi-dict
---@field kangxi string? kx2ucs.txt from https://github.com/cjkvi/cjkvi-dict
---@field chinadat string? path to chinadat.csv from https://www.seiwatei.net/info/dnchina.htm
---@field guangyun string? path to Kuankhiunn0704-semicolon.txt from https://github.com/syimyuzya/guangyun0704
---@field user string? path to user_dict.json
---@field dir string? basedir

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
  local unihan_like_file = unihan_dir .. "/Unihan_DictionaryLikeData.txt"
  local data = util.readfile_sync(vim.uv, unihan_like_file)
  if data then
    dict:load_unihan_likedata(data, unihan_like_file)
  end

  local unihan_reading_file = unihan_dir .. "/Unihan_Readings.txt"
  data = util.readfile_sync(vim.uv, unihan_reading_file)
  if data then
    dict:load_unihan_readings(data, unihan_reading_file)
  end

  local unihan_variants_file = unihan_dir .. "/Unihan_Variants.txt"
  data = util.readfile_sync(vim.uv, unihan_variants_file)
  if data then
    dict:load_unihan_variants(data, unihan_variants_file)
  end

  data = util.readfile_sync(vim.uv, unihan_dir .. "/Unihan_OtherMappings.txt")
  if data then
    dict:load_unihan_othermappings(data)
  end

  if opts.guangyun then
    data = util.readfile_sync(vim.uv, opts.guangyun)
    if data then
      dict:load_quangyun(data, opts.guangyun)
    end
  end

  if opts.kangxi then
    data = util.readfile_sync(vim.uv, opts.kangxi)
    if data then
      dict:load_kangxi(data)
    end
  end

  do
    local xszd_file = opts.xszd and opts.xszd or (vim.fs.joinpath(opts.dir, "cjkvi-dict-master/xszd.txt"))
    data = util.readfile_sync(vim.uv, xszd_file)
    if data then
      dict:load_xszd(data, xszd_file)
    end
  end

  do
    local kyu_file =
        vim.fs.joinpath(opts.dir, "hanzi-chars-main/data-charlist/日本《常用漢字表》（2010年）旧字体.txt")
    data = util.readfile_sync(vim.uv, kyu_file)
    if data then
      dict:load_kyu(data, kyu_file)
    end
  end

  do
    local chinadat_file = opts.chinadat and opts.chinadat or (vim.fs.joinpath(opts.dir, "chinadat.csv"))
    data = util.readfile_sync(vim.uv, chinadat_file)
    if data then
      dict:load_chinadat(data, chinadat_file)
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

  for _, path in ipairs(jisyo) do
    data = util.readfile_sync(vim.uv, path)
    if data then
      dict:load_skk(data, path)
    end
  end

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
    assert(encoded, vim.inspect(opts))
    ---@diagnostic disable
    local dict = require("string.buffer").decode(encoded)
    ---@cast dict UniHanDict
    on_completed(dict)
    -- print(vim.inspect(dict))
  end)()
end

return M
