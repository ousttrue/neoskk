---
--- vim の状態管理
---
local MODULE_NAME = "neoskk"
local KEYS_LOWER = vim.split("abcdefghijklmnopqrstuvwxyz", "")
local KEYS_SYMBOL = vim.split("., -~[]\b0123456789", "")
local PreEdit = require "neoskk.PreEdit"
local dict = require "neoskk.Dict"
local SkkMachine = require "neoskk.SkkMachine"

---@class JisyoItem
---@field word string
---@fiend annotation string?

local M = {}

---@class Opts
---@field jisyo string path to SKK-JISYO.L from https://github.com/skk-dict/jisyo
---@field unihan string path to Unihan_DictionaryLikeData.txt from https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
local Opts = {}

---@class NeoSkk
---@field state SkkMachine 状態管理
---@field conv_col integer 漢字変換を開始した col
---@field preedit PreEdit
---@field map_keys string[]
---@field jisyo {[string]: JisyoItem[]}
---@field goma JisyoItem[]
M.NeoSkk = {}

---@param opts Opts?
---@return NeoSkk
function M.NeoSkk.new(opts)
  local self = setmetatable({
    opts = opts and opts or {},
    state = SkkMachine.new(),
    conv_col = 0,
    preedit = PreEdit.new(MODULE_NAME),
    map_keys = {},
    jisyo = {},
    goma = {},
  }, {
    __index = M.NeoSkk,
  })
  self:map()

  --
  -- event
  --
  local group = vim.api.nvim_create_augroup(MODULE_NAME, { clear = true })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    pattern = { "*" },
    callback = function(ev)
      self.state:clear()
      self.preedit:highlight ""
      vim.bo.iminsert = 0
    end,
  })

  vim.api.nvim_create_autocmd("CompleteDone", {
    group = group,
    -- buffer = bufnr,
    callback = function()
      local reason = vim.api.nvim_get_vvar("event").reason --- @type string
      if reason == "accept" then
        self:on_complete_done()
      end
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
    new_self.jisyo = old.jisyo
    new_self.goma = old.goma
  end)

  M.instance = self
  return self
end

function M.NeoSkk:delete()
  self.preedit:highlight ""
  self:unmap()
end

function M.NeoSkk:on_complete_done()
  local completed_item = vim.api.nvim_get_vvar "completed_item"
  if not completed_item or not completed_item.user_data or not completed_item.user_data.nvim then
    return
  end
  -- print(vim.inspect(completed_item))
end

---@param lhs string
---@return string
function M.NeoSkk.input(self, lhs)
  if lhs == "\b" then
    if vim.bo.iminsert ~= 1 then
      return "<C-h>"
    elseif #self.state.kana_feed == 0 and #self.state.conv_feed == 0 then
      return "<C-h>"
    end
  end

  if lhs:match "^[A-Z]$" then
    if self.state.conv_mode == SkkMachine.RAW then
      self.conv_col = vim.fn.col "."
    end
  end

  local out, preedit, items = self.state:input(lhs, self.jisyo, self.goma)
  self.preedit:highlight(preedit)

  if items and #items > 0 then
    if #items == 0 then
    elseif #items == 1 then
      -- 確定
      out = items[1].word
    else
      -- completion
      vim.defer_fn(function()
        -- trigger completion
        local opt_backup = vim.opt.completeopt
        vim.opt.completeopt = { "menuone", "popup" }
        vim.fn.complete(self.conv_col, items)
        vim.opt.completeopt = opt_backup
      end, 0)
    end
  end

  return out
end

--- language-mapping
function M.NeoSkk.map(self)
  ---@param lhs string
  ---@param alt string?
  local function add_key(lhs, alt)
    vim.keymap.set("l", lhs, function()
      return self:input(alt and alt or lhs)
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

---@param opts Opts
function M.setup(opts)
  local skk = M.NeoSkk.new(opts)

  if opts.jisyo then
    local jisyo = dict.load_skk(opts.jisyo)
    if jisyo then
      skk.jisyo = jisyo
    end
  end

  if opts.unihan then
    local goma = dict.load_goma(opts.unihan)
    if goma then
      skk.goma = goma
    end
  end
end

function M.toggle()
  return M.instance:toggle()
end

return M
