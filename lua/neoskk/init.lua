---
--- vim の状態管理
---
local MODULE_NAME = "neoskk"
local KEYS_LOWER = vim.split("abcdefghijklmnopqrstuvwxyz", "")
local KEYS_SYMBOL = vim.split("., :;-+~[](){}<>\b0123456789/", "")
local PreEdit = require "neoskk.PreEdit"
local UniHanDict = require "neoskk.UniHanDict"
local SkkMachine = require "neoskk.SkkMachine"
local ZhuyinMachine = require "neoskk.ZhuyinMachine"
local Completion = require "neoskk.Completion"
local Indicator = require "neoskk.Indicator"

local STATE_MODE_SKK = "skk"
local STATE_MODE_ZHUYIN = "zhuyin"
---@alias STATE_MODE `STATE_MODE_SKK` | `STATE_MODE_ZHUYIN`

local M = {
  ---@type STATE_MODE
  state_mode = STATE_MODE_SKK,
}

---@class NeoSkkOpts
---@field jisyo string path to SKK-JISYO.L from https://github.com/skk-dict/jisyo
---@field unihan_dir string path to dir. Extracted https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
---@field xszd string path to xszd.txt from https://github.com/cjkvi/cjkvi-dict
---@field kangxi string kx2ucs.txt from https://github.com/cjkvi/cjkvi-dict
local NeoSkkOpts = {}

---@class NeoSkk
---@field bufnr integer 対象のbuf。変わったら状態をクリアする
---@field state SkkMachine | ZhuyinMachine | nil 状態管理
---@field conv_col integer 漢字変換を開始した col
---@field preedit PreEdit
---@field map_keys string[]
---@field dict UniHanDict
---@field indicator Indicator
---@field has_backspace boolean
---@field last_completion Completion?
M.NeoSkk = {}
M.NeoSkk.__index = M.NeoSkk

---@param opts NeoSkkOpts?
---@return NeoSkk
function M.NeoSkk.new(opts)
  local self = setmetatable({
    bufnr = -1,
    opts = opts and opts or {},
    conv_col = 0,
    preedit = PreEdit.new(MODULE_NAME),
    map_keys = {},
    dict = UniHanDict.new(),
    indicator = Indicator.new(),
    has_backspace = false,
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

  vim.api.nvim_create_autocmd("CompleteDone", {
    group = group,
    -- buffer = bufnr,
    callback = function(ev)
      local event = vim.api.nvim_get_vvar "event"
      local last_completion = self.last_completion
      self.last_completion = nil

      if event.reason == "accept" then
        local item = vim.api.nvim_get_vvar "completed_item"
        -- replace
        self:on_complete_done(ev.buf, item)
      elseif event.reason == "cancel" then
        if last_completion then
          local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0)) --- @type integer, integer
          cursor_row = cursor_row - 1
          if self.has_backspace and last_completion and cursor_col > self.conv_col then
            -- 再
            local current = vim.api.nvim_buf_get_text(ev.buf, cursor_row, self.conv_col, cursor_row, cursor_col, {})[1]
            print(current)
            if current:match "^%d$" then
              -- 'g%d'
              last_completion = self.dict:filter_goma(current:sub(2, 2))
            end
            self:raise_completion(last_completion)
          else
            -- cancel clear
            vim.api.nvim_buf_set_text(ev.buf, cursor_row, self.conv_col, cursor_row, cursor_col, { "" })
          end
        end
      end
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
      self.preedit:highlight(self.bufnr, "")
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

  M.instance = self
  return self
end

function M.NeoSkk:flush()
  local out = ""
  if self.state then
    self.state:flush()
  end
  if self.bufnr ~= -1 then
    if #out > 0 then
      vim.api.nvim_put({ out }, "", true, true)
    end
    self.preedit:highlight(self.bufnr, "")
    self.bufnr = -1
  end

  self.state = nil
end

function M.NeoSkk:delete()
  self.indicator:delete()
  self.preedit:highlight(self.bufnr, "")
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
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0)) --- @type integer, integer
    cursor_row = cursor_row - 1

    -- Replace the already inserted word with user_data.replace
    local start_char = cursor_col - #item.word
    vim.api.nvim_buf_set_text(bufnr, cursor_row, start_char, cursor_row, cursor_col, { user_data.replace })
  end
end

---@param bufnr integer
---@param lhs string
---@return string
function M.NeoSkk:input(bufnr, lhs)
  if self.state then
    if self.bufnr ~= -1 and self.bufnr ~= bufnr then
      self.state:flush()
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

  if lhs == "\b" then
    if vim.bo.iminsert ~= 1 then
      return "<C-h>"
    elseif #self.state:preedit() == 0 then
      return "<C-h>"
    end
  end

  if lhs:match "^[A-Z]$" then
    -- SHIFT
    if self.state.conv_mode == SkkMachine.RAW then
      self.conv_col = vim.fn.col "."
    end
  end

  local out, preedit, completion = self.state:input(lhs, self.dict)
  if vim.fn.pumvisible() and #preedit > 0 then
    -- completion を確定する
    out = " \b" .. out
  end
  self.preedit:highlight(self.bufnr, preedit)

  if completion then
    if not completion.items or #completion.items == 0 then
    elseif #completion.items == 1 then
      -- 確定
      local item = completion.items[1]
      out = item.word
    else
      -- completion
      self:raise_completion(completion)
    end
  end

  return out
end

---@param completion Completion
function M.NeoSkk:raise_completion(completion)
  if completion.opts == Completion.FUZZY_OPTS then
    self.last_completion = completion
  else
    self.last_completion = nil
  end

  vim.defer_fn(function()
    -- trigger completion
    local opt_backup = vim.opt.completeopt
    if completion.opts == Completion.SKK_OPTS then
      vim.opt.completeopt = { "menuone", "popup" }
    elseif completion.opts == Completion.FUZZY_OPTS then
      vim.opt.completeopt = { "menuone", "popup", "fuzzy", "noselect", "noinsert" }
    else
      --
    end
    -- completeopt
    self.has_backspace = false
    vim.fn.complete(self.conv_col, completion.items)
    vim.opt.completeopt = opt_backup
  end, 0)
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
        if lhs == "\b" or alt == "\b" then
          self.has_backspace = true
        elseif lhs == "\n" or alt == "\n" then
          return "<C-y>"
        end
      end

      local bufnr = vim.api.nvim_get_current_buf()
      local win = vim.api.nvim_get_current_win()
      local out = self:input(bufnr, alt and alt or lhs)
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

  if opts.unihan_dir then
    skk.dict:load_unihan(opts.unihan_dir)
  end

  if opts.kangxi then
    skk.dict:load_kangxi(opts.kangxi)
  end

  if opts.xszd then
    skk.dict:load_xszd(opts.xszd)
  end

  if opts.jisyo then
    skk.dict:load_skk(opts.jisyo)
  end
end

return M
