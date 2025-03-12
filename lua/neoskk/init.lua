---
--- vim の状態管理
---
local MODULE_NAME = "neoskk"
local cache = vim.fn.stdpath "cache"
assert(type(cache) == "string")

---@return string
local function ensure_make_cache_dir()
  local CACHE_DIR = vim.fs.joinpath(cache, MODULE_NAME)
  if not vim.uv.fs_stat(CACHE_DIR) then
    vim.notify_once("mkdir " .. CACHE_DIR, vim.log.levels.INFO, { title = "neoskk" })
    vim.fn.mkdir(CACHE_DIR, "p")
  end
  return CACHE_DIR
end

local KEYS_LOWER = vim.split("abcdefghijklmnopqrstuvwxyz", "")
local KEYS_SYMBOL = vim.split("., :;-+*~[](){}<>\b0123456789/", "")
local UNIHAN_URL = "https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip"
-- https://skk-dev.github.io/dict/
local SKK_L_URL = "https://skk-dev.github.io/dict/SKK-JISYO.L.gz"
local SKK_china_taiwan_URL = "https://skk-dev.github.io/dict/SKK-JISYO.china_taiwan.gz"
local CHINADAT_URL = "https://www.seiwatei.net/info/chinadat.csv"
local CJKVI_DICT_URL = "https://github.com/cjkvi/cjkvi-dict/archive/refs/heads/master.zip"
local HANZI_CHARS_URL = "https://github.com/zispace/hanzi-chars/archive/refs/heads/main.zip"

local UniHanDict = require "neoskk.UniHanDict"
local SkkMachine = require "neoskk.SkkMachine"
local ZhuyinMachine = require "neoskk.ZhuyinMachine"
local Completion = require "neoskk.Completion"
local Indicator = require "neoskk.Indicator"
local util = require "neoskk.util"
local utf8 = require "neoskk.utf8"

local STATE_MODE_SKK = "skk"
local STATE_MODE_ZHUYIN = "zhuyin"
---@alias STATE_MODE `STATE_MODE_SKK` | `STATE_MODE_ZHUYIN`

local M = {
  ---@type STATE_MODE
  state_mode = STATE_MODE_SKK,
}

---@class NeoSkk
---@field opts NeoSkkOpts
---@field bufnr integer 対象のbuf。変わったら状態をクリアする
---@field state SkkMachine | ZhuyinMachine | nil 状態管理
---@field map_keys string[]
---@field dict UniHanDict
---@field indicator Indicator
---@field has_kana_feed boolean
M.NeoSkk = {}
M.NeoSkk.__index = M.NeoSkk

---@param opts NeoSkkOpts?
---@return NeoSkk
function M.NeoSkk.new(opts)
  local self = setmetatable({
    bufnr = -1,
    opts = opts and opts or {},
    map_keys = {},
    dict = UniHanDict.new(),
    indicator = Indicator.new(),
    has_kana_feed = false,
  }, M.NeoSkk)
  self:map()

  self:update_indicator()

  --
  -- event
  --
  local group = vim.api.nvim_create_augroup(MODULE_NAME, { clear = true })

  vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
    group = group,
    callback = function(ev)
      self.state = nil
      vim.bo.iminsert = 0
      self.indicator:close()
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave", "WinLeave" }, {
    group = group,
    pattern = { "*" },
    callback = function(ev)
      self:flush()
      self.indicator:close()
      vim.bo.iminsert = 0
    end,
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      self.indicator:open()
      self:update_indicator()
    end,
  })

  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = "iminsert",
    callback = function()
      print "OptionSet"
      self:update_indicator()
    end,
  })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    callback = function()
      self:flush()
    end,
  })

  --
  -- reload
  --
  require("neoskk.reload").autocmd(group, MODULE_NAME, function()
    -- shutdown
    self:delete()
    return self
  end, function(old)
    -- reload
    local new_module = require(MODULE_NAME)
    local new_self = new_module.NeoSkk.new(old.opts)
    new_self.dict = old.dict
  end)

  vim.api.nvim_create_user_command("NeoSkkReload", function()
    require("neoskk").reload_dict()
  end, {})

  vim.api.nvim_create_user_command("NeoSkkUnihanDownload", function()
    require("neoskk").download_unihan()
  end, {})

  vim.api.nvim_create_user_command("NeoSkkSkkDictDownload", function()
    require("neoskk").download_skkdict()
  end, {})

  vim.api.nvim_create_user_command("NeoSkkChinadatDownload", function()
    require("neoskk").download_chinadat()
  end, {})

  vim.api.nvim_create_user_command("NeoSkkCjkviDictDownload", function()
    require("neoskk").download_cjkvi_dict()
  end, {})

  vim.api.nvim_create_user_command("NeoSkkHanziCharsDownload", function()
    require("neoskk").download_hanzi_chars()
  end, {})

  M.instance = self
  return self
end

function M.NeoSkk:flush()
  self.has_kana_feed = false
  if self.bufnr ~= -1 then
    self.bufnr = -1
  end
  self.state = nil
end

function M.NeoSkk:delete()
  self.indicator:delete()
  self:unmap()
end

---@param bufnr integer
---@param item CompletionItem
function M.NeoSkk:on_complete_done(bufnr, item)
  if not item or not item.user_data then
    return
  end
  local user_data = item.user_data
  if not user_data then
    return
  end
  if user_data.replace then
    local cursor_row, cursor_pos = unpack(vim.api.nvim_win_get_cursor(0)) --- @type integer, integer
    cursor_row = cursor_row - 1

    -- Replace the already inserted word with user_data.replace
    local start_char = cursor_pos - #item.word
    vim.api.nvim_buf_set_text(bufnr, cursor_row, start_char, cursor_row, cursor_pos, { user_data.replace })
  end
end

---@param bufnr integer
---@param lhs string
---@return string
function M.NeoSkk:input(bufnr, lhs)
  if self.state then
    if self.bufnr ~= -1 and self.bufnr ~= bufnr then
      self:flush()
    end
  else
    if M.state_mode == STATE_MODE_SKK then
      self.state = SkkMachine.new()
    elseif M.state_mode == STATE_MODE_ZHUYIN then
      self.state = ZhuyinMachine.new()
    else
      assert(false)
    end
    vim.defer_fn(function()
      self.indicator:open()
    end, 1)
  end
  self.bufnr = bufnr

  if lhs == ";" then
    return "▽"
  end

  if lhs == "\b" then
    if vim.bo.iminsert ~= 1 then
      return "<C-h>"
    end
  end

  local kana_feed = self:get_feed()

  local out, preedit = self.state:input(lhs, kana_feed, vim.fn.pumvisible() == 1)
  if lhs:match "^[A-Z]$" then
    -- SHIFT
    if util.get_current_line_cursor_left():match "▽" then
    else
      out = "▽" .. out
    end
  end

  self.has_kana_feed = preedit and #preedit > 0

  local preedit_len = utf8.len(kana_feed)
  if preedit_len then
    local delete_preedit = string.rep("\b", preedit_len)
    out = delete_preedit .. out
  end

  return out .. (preedit and preedit or "")
end

---@return string
function M.NeoSkk:get_feed()
  if not self.has_kana_feed then
    return ""
  end

  local line = util.get_current_line_cursor_left()
  local kana_feed = line:match "%a+$"
  return kana_feed or ""
end

--- language-mapping
function M.NeoSkk.map(self)
  ---@param lhs string
  ---@param alt string?
  local function add_key(lhs, alt)
    vim.keymap.set("l", lhs, function()
      if vim.fn.mode():sub(1, 1) ~= "i" then
        -- not insert mode
        return alt and alt or lhs
      end

      if vim.fn.pumvisible() == 1 then
        if lhs == "\n" or alt == "\n" then
          return "<C-y>"
        elseif lhs == " " then
          return "<C-n>"
        end
      end

      local bufnr = vim.api.nvim_get_current_buf()
      local win = vim.api.nvim_get_current_win()
      local out = self:input(bufnr, alt and alt or lhs)

      if vim.bo.filetype == "TelescopePrompt" then
        if out == "\n" then
          vim.defer_fn(function()
            require("telescope.actions").select_default(bufnr)
          end, 1)
          return
        end
      end
      self:update_indicator()

      return out
    end, {
      -- buffer = true,
      silent = true,
      expr = true,
    })
    table.insert(self.map_keys, lhs)
  end

  for _, lhs in ipairs(KEYS_LOWER) do
    add_key(lhs)
    add_key(lhs:upper())
  end

  for _, lhs in ipairs(KEYS_SYMBOL) do
    add_key(lhs)
  end

  --
  -- not lmap
  --
  add_key("<BS>", "\b")
  add_key("<CR>", "\n")
end

function M.NeoSkk.unmap(self)
  -- language-mapping
  for _, lhs in ipairs(self.map_keys) do
    -- vim.api.nvim_buf_del_keymap(0, "l", lhs)
    if vim.api.nvim_get_keymap("l")[lhs] then
      vim.api.nvim_del_keymap("l", lhs)
    end
  end
end

function M.NeoSkk:_update_indicator()
  -- if vim.bo.iminsert == 1 then
  --   if self.state then
  --     Indicator.set(self.state:mode_text())
  --   else
  --     Indicator.set "NO"
  --   end
  -- else
  --   Indicator.set "無"
  -- end
  if self.state then
    if vim.bo.iminsert == 1 then
      Indicator.set(self.state:mode_text())
    else
      Indicator.set "無"
    end
  else
    Indicator.set "No"
  end
end

function M.NeoSkk:update_indicator()
  vim.defer_fn(function()
    self:_update_indicator()
  end, 1)
end

function M.NeoSkk:hover()
  if self.dict then
    local ch = vim.fn.matchstr(vim.fn.getline ".", ".", vim.fn.col "." - 1)
    if ch then
      return self.dict:hover(ch)
    end
  end
end

function M.NeoSkk:load_dict()
  self.dict = UniHanDict.new()
  self.opts.dir = ensure_make_cache_dir()

  require("neoskk.work_util").async_load(self.opts, function(dict)
    self.dict = dict
    UniHanDict.resetmetatable(self.dict)
  end)
end

---@param mode STATE_MODE?
function M.toggle(mode)
  M.instance:update_indicator()
  if not mode then
    mode = STATE_MODE_SKK
  end

  local changed = false
  if M.state_mode ~= mode then
    changed = true
    M.state_mode = mode
  end

  if M.state_mode == STATE_MODE_SKK then
    M.instance.state = SkkMachine.new()
  elseif M.state_mode == STATE_MODE_ZHUYIN then
    M.instance.state = ZhuyinMachine.new()
  else
    assert(false)
  end

  if vim.bo.iminsert == 1 and changed then
    return ""
  else
    return "<C-^>"
  end
end

---@param opts NeoSkkOpts
function M.setup(opts)
  local skk = M.NeoSkk.new(opts)
  skk:load_dict()
end

function M.hover()
  local skk = M.instance
  if skk then
    return skk:hover()
  end
end

function M.reload_dict()
  local skk = M.instance
  if skk then
    return skk:load_dict()
  end
end

---@param url string
---@param dir string
---@param downloaded string
---@param extracted string
local function download_if_not_exist(url, dir, downloaded, extracted, opts)
  local dst_extracted = vim.fs.joinpath(dir, extracted)
  if vim.uv.fs_stat(dst_extracted) then
    vim.notify_once("exist " .. dst_extracted, vim.log.levels.INFO, { title = "neoskk" })
    return
  end

  local dst_archive = vim.fs.joinpath(dir, downloaded)
  if not vim.uv.fs_stat(dst_archive) then
    -- download
    vim.notify_once("download " .. url, vim.log.levels.INFO, { title = "neoskk" })

    local dl_job = vim.system({ "curl", "-L", url }, { text = false }):wait()
    assert(dl_job.stdout)
    vim.notify_once(("write %dbytes"):format(#dl_job.stdout), vim.log.levels.INFO, { title = "neoskk" })
    util.writefile_sync(vim.uv, dst_archive, dl_job.stdout)
  end

  -- extract
  if downloaded == extracted then
    -- skip
  else
    vim.notify_once("extact " .. dst_extracted, vim.log.levels.INFO, { title = "neoskk" })
    if not downloaded:match "%.tar%.gz$" and downloaded:match "%.gz$" then
      local gz_job = vim.system({ "C:/Program Files/Git/usr/bin/gzip.exe", "-dc", dst_archive }, { cwd = dir }):wait()
      if opts.encoding then
        util.writefile_sync(vim.uv, dst_extracted, gz_job.stdout, opts.encodng, "utf-8")
      else
        util.writefile_sync(vim.uv, dst_extracted, gz_job.stdout)
      end
      assert(vim.uv.fs_stat(dst_extracted))
      vim.notify_once("done", vim.log.levels.INFO, { title = "neoskk" })
    else
      vim.system({ "tar", "xf", dst_archive }, { cwd = dir }):wait()
      assert(vim.uv.fs_stat(dst_extracted))
      vim.notify_once("done", vim.log.levels.INFO, { title = "neoskk" })
    end
  end
end

function M.download_unihan()
  local dir = ensure_make_cache_dir()
  download_if_not_exist(UNIHAN_URL, dir, "Unihan.zip", "Unihan_DictionaryIndices.txt")
end

function M.download_skkdict()
  local dir = ensure_make_cache_dir()
  download_if_not_exist(SKK_L_URL, dir, "SKK-JISYO.L.gz", "SKK-JISYO.L", { encoding = "euc-jp" })
  download_if_not_exist(
    SKK_china_taiwan_URL,
    dir,
    "SKK-JISYO.china_taiwan.gz",
    "SKK-JISYO.china_taiwan",
    { encoding = "euc-jp" }
  )
end

function M.download_chinadat()
  local dir = ensure_make_cache_dir()
  download_if_not_exist(CHINADAT_URL, dir, "chinadat.csv", "chinadat.csv", {})
end

function M.download_cjkvi_dict()
  local dir = ensure_make_cache_dir()
  download_if_not_exist(CJKVI_DICT_URL, dir, "cjkvi-dict-master.zip", "cjkvi-dict-master/xszd.txt", {})
end

function M.download_hanzi_chars()
  local dir = ensure_make_cache_dir()
  download_if_not_exist(
    HANZI_CHARS_URL,
    dir,
    "hanzi-chars-main.zip",
    "hanzi-chars-main/data-charlist/日本《常用漢字表》（2010年）旧字体.txt",
    {}
  )
end

return M
