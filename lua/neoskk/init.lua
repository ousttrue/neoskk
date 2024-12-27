---
--- vim の状態管理
---
local MODULE_NAME = "neoskk"
local KEYS = vim.split("abcdefghijklmnopqrstuvwxyz", "")
local kanaconv = require "neoskk.kanaconv"
local PreEdit = require("neoskk.preedit").PreEdit
local dict = require "neoskk.dict"
local SkkMachine = require("neoskk.machine").SkkMachine

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

local function copy_item(src)
  local dst = {}
  for k, v in pairs(src) do
    dst[k] = v
  end
  return dst
end

---@param conv_feed string
---@return JisyoItem[]
function M.NeoSkk.filter_jisyo(self, conv_feed)
  local items = {}
  local key = conv_feed .. self.okuri_feed
  for k, v in pairs(M.jisyo) do
    if k == key then
      for _, item in ipairs(v) do
        local copy = copy_item(item)
        copy.word = copy.word .. out
        table.insert(items, copy)
      end
    end
  end

  local items = {}
  for k, v in pairs(M.jisyo) do
    if k == conv_feed then
      for _, item in ipairs(v) do
        table.insert(items, item)
      end
    end
  end
  return items
end

---@param lhs string
---@param is_upper boolean
---@return string
function M.NeoSkk.input(self, lhs, is_upper)
  if is_upper then
    if self.state.conv_mode == SkkMachine.RAW then
      self.conv_col = vim.fn.col "."
    end
    self.state:upper(lhs)
  end

  if self.state.conv_mode == SkkMachine.CONV and lhs == " " then
    local conv_feed = self.state:clear_conv()
    vim.defer_fn(function()
      -- trigger completion
      local items = self:filter_jisyo(conv_feed)
      vim.fn.complete(self.conv_col, items)
    end, 0)
    self.preedit:highlight ""
    return conv_feed
  else
    local out = self.state:input(lhs)

    if self.state.conv_mode == SkkMachine.RAW then
      self.preedit:highlight(self.state.kana_feed)
      return out
    elseif self.state.conv_mode == SkkMachine.CONV then
      self.state.conv_feed = self.state.conv_feed .. out
      self.preedit:highlight(self.state.conv_feed .. self.state.kana_feed)
      return ""
    elseif self.state.conv_mode == SkkMachine.OKURI then
      if #out > 0 then
        -- trigger
        local conv_feed = self.state:clear_conv()
        vim.defer_fn(function()
          local items = self:filter_jisyo(conv_feed .. self.state.okuri_feed)
          vim.fn.complete(self.conv_col, items)
        end, 0)
        self.preedit:highlight ""
        return conv_feed .. out
      else
        self.preedit:highlight(self.state.conv_feed .. self.state.kana_feed)
        return ""
      end
    end
  end
end

--- language-mapping
function M.NeoSkk.map(self)
  for _, lhs in ipairs(KEYS) do
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

    -- space
    vim.keymap.set("l", " ", function()
      return self:input(" ", false)
    end, {
      -- buffer = true,
      silent = true,
      expr = true,
    })

    table.insert(self.map_keys, u)
  end
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
  self.kana_feed = ""
  self.mode = RAW
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
