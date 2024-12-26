---
--- vim の状態管理
---
local MODULE_NAME = "lkk"
local KEYS = vim.split("abcdefghijklmnopqrstuvwxyz", "")
local kanaconv = require "lkk.kanaconv"
local PreEdit = require("lkk.preedit").PreEdit
local dict = require "lkk.dict"

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

local RAW = 0
local CONV = 1
local OKURI = 2

---@alias MODE `RAW` | `CONV` | `OKURI`

---@class Lkk
---@field kana_feed string かな入力の未確定(ascii)
---@field conv_feed string 漢字変換の未確定(かな)
---@field conv_col integer 漢字変換を開始した col
---@field preedit PreEdit
---@field map_keys string[]
---@field mode MODE
M.Lkk = {}

---@param opts Opts?
---@return Lkk
function M.Lkk.new(opts)
  local self = setmetatable({
    opts = opts and opts or {},
    kana_feed = "",
    conv_feed = "",
    conv_col = 0,
    preedit = PreEdit.new(MODULE_NAME),
    map_keys = {},
    mode = RAW,
  }, {
    __index = M.Lkk,
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
  require("tools.reload").autocmd(group, MODULE_NAME, function()
    -- shutdown
    self:delete()
    return self
  end, function(old)
    -- reload
    local new_module = require(MODULE_NAME)
    new_module.Lkk.new(old.opts)
    new_module.jisyo = old.jisyo
  end)

  M.instance = self
  return self
end

function M.Lkk.delete(self)
  self:unmap()
end

---@param lhs string
---@param is_upper boolean
---@return string
function M.Lkk.input(self, lhs, is_upper)
  if is_upper then
    if self.mode == RAW then
      self.mode = CONV
      self.conv_col = vim.fn.col "."
    elseif self.mode == CONV then
      self.mode = OKURI
    elseif self.mode == OKURI then
      --
    end
  end

  if self.mode == CONV and lhs == " " then
    -- trigger
    local conv_feed = self.conv_feed
    self.conv_feed = ""
    vim.defer_fn(function()
      local items = {}
      for k, v in pairs(M.jisyo) do
        if k == conv_feed then
          for _, item in ipairs(v) do
            table.insert(items, item)
          end
        end
      end
      vim.fn.complete(self.conv_col, items)
    end, 0)
    self.preedit:highlight ""
    self.mode = RAW
    return conv_feed
  else
    local out, feed = kanaconv.to_kana(lhs, self.kana_feed)
    self.kana_feed = feed

    if self.mode == RAW then
      self.preedit:highlight(self.kana_feed)
      return out
    elseif self.mode == CONV then
      self.conv_feed = self.conv_feed .. out
      self.preedit:highlight(self.conv_feed .. self.kana_feed)
      return ""
    elseif self.mode == OKURI then
      -- TODO
      return ""
    end
  end
end

--- language-mapping
function M.Lkk.map(self)
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

function M.Lkk.unmap(self)
  -- language-mapping
  for _, lhs in ipairs(self.map_keys) do
    -- vim.api.nvim_buf_del_keymap(0, "l", lhs)
    vim.api.nvim_del_keymap("l", lhs)
  end
end

---@return string
function M.Lkk.enable(self)
  if vim.bo.iminsert == 1 then
    return ""
  end

  -- vim.defer_fn(function()
  local indicator = require "tools.indicator"
  indicator:open()
  indicator.set "あ"
  -- end, 0)
  vim.cmd [[set iminsert=1]]
  return "<C-^>"
end

---@return string
function M.Lkk.disable(self)
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
function M.Lkk.toggle(self)
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

  M.Lkk.new(opts)
end

function M.toggle()
  return M.instance:toggle()
end

return M
