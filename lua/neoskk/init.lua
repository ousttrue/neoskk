---
--- vim の状態管理
---
local MODULE_NAME = "neoskk"
local KEYS_LOWER = vim.split("abcdefghijklmnopqrstuvwxyz", "")
local KEYS_SYMBOL = vim.split("., -~[]\b", "")
local PreEdit = require("neoskk.preedit").PreEdit
local dict = require "neoskk.dict"
local SkkMachine = require("neoskk.SkkMachine")

---@class JisyoItem
---@field word string
---@fiend annotation string?

local M = {
  ---@type {[string]: JisyoItem[]}
  jisyo = {},
}

---@class Opts
---@field jisyo string path to SKK-JISYO.L
local Opts = {}

---@class NeoSkk
---@field state SkkMachine 状態管理
---@field conv_col integer 漢字変換を開始した col
---@field preedit PreEdit
---@field map_keys string[]
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
      self:disable()
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
    new_module.NeoSkk.new(old.opts)
    new_module.jisyo = old.jisyo
  end)

  M.instance = self
  return self
end

function M.NeoSkk.delete(self)
  self:unmap()
end

---@param lhs string
---@param is_upper boolean
---@return string
function M.NeoSkk.input(self, lhs, is_upper)
  if lhs == "\b" then
    if vim.bo.iminsert ~= 1 then
      return "<C-h>"
    elseif #self.state.kana_feed == 0 and #self.state.conv_feed == 0 then
      return "<C-h>"
    end
  end

  if is_upper then
    if self.state.conv_mode == SkkMachine.RAW then
      self.conv_col = vim.fn.col "."
    end
    self.state:upper(lhs)
  end

  local out, preedit, items = self.state:input(lhs, M.jisyo)

  if items then
    vim.defer_fn(function()
      -- trigger completion
      vim.fn.complete(self.conv_col, items)
    end, 0)
  end

  self.preedit:highlight(preedit)
  return out
end

--- language-mapping
function M.NeoSkk.map(self)
  for _, lhs in ipairs(KEYS_LOWER) do
    vim.keymap.set("l", lhs, function()
      return self:input(lhs, false)
    end, {
      -- buffer = true,
      silent = true,
      expr = true,
    })
    table.insert(self.map_keys, lhs)

    -- upper case
    local u = lhs:upper()
    vim.keymap.set("l", u, function()
      return self:input(lhs, true)
    end, {
      -- buffer = true,
      silent = true,
      expr = true,
    })
    table.insert(self.map_keys, u)
  end

  for _, lhs in ipairs(KEYS_SYMBOL) do
    vim.keymap.set("l", lhs, function()
      return self:input(lhs, false)
    end, {
      -- buffer = true,
      silent = true,
      expr = true,
    })
    table.insert(self.map_keys, lhs)
  end

  --
  -- not lmap
  --
end

function M.NeoSkk.unmap(self)
  -- language-mapping
  for _, lhs in ipairs(self.map_keys) do
    -- vim.api.nvim_buf_del_keymap(0, "l", lhs)
    vim.api.nvim_del_keymap("l", lhs)
  end
end

---@return string
function M.NeoSkk.enable(self)
  if vim.bo.iminsert == 1 then
    return ""
  end
  return "<C-^>"
end

---@return string
function M.NeoSkk.disable(self)
  self.state:clear()
  self.preedit:highlight ""

  if vim.bo.iminsert ~= 1 then
    return ""
  end

  vim.cmd [[set iminsert=0]]
  return "<C-^>"
end

---@return string
function M.NeoSkk.toggle(self)
  if vim.bo.iminsert == 1 then
    return self:disable()
  else
    return self:enable()
  end
end

---@param opts Opts
function M.setup(opts)
  if opts.jisyo then
    M.jisyo = dict.load(opts.jisyo)
  end

  M.NeoSkk.new(opts)
end

function M.toggle()
  return M.instance:toggle()
end

return M
