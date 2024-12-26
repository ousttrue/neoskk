---
--- vim の状態管理
---
local MODULE_NAME = "neoskk"
local KEYS = vim.split("abcdefghijklmnopqrstuvwxyz", "")
local kanaconv = require "neoskk.kanaconv"
local PreEdit = require("neoskk.preedit").PreEdit
local dict = require "neoskk.dict"

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

---@class NeoSkk
---@field kana_feed string かな入力の未確定(ascii)
---@field conv_feed string 漢字変換の未確定(かな)
---@field conv_col integer 漢字変換を開始した col
---@field okuri_feed string 送り仮名
---@field preedit PreEdit
---@field map_keys string[]
---@field mode MODE
M.NeoSkk = {}

---@param opts Opts?
---@return NeoSkk
function M.NeoSkk.new(opts)
  local self = setmetatable({
    opts = opts and opts or {},
    kana_feed = "",
    conv_feed = "",
    conv_col = 0,
    okuri_feed = "",
    preedit = PreEdit.new(MODULE_NAME),
    map_keys = {},
    mode = RAW,
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

---@param lhs string
---@param is_upper boolean
---@return string
function M.NeoSkk.input(self, lhs, is_upper)
  if is_upper then
    if self.mode == RAW then
      self.mode = CONV
      self.conv_col = vim.fn.col "."
    elseif self.mode == CONV then
      self.mode = OKURI
      self.okuri_feed = lhs
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
      if #out > 0 then
        -- trigger
        local conv_feed = self.conv_feed
        self.conv_feed = ""
        vim.defer_fn(function()
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
          vim.fn.complete(self.conv_col, items)
        end, 0)
        self.preedit:highlight ""
        self.mode = RAW
        return conv_feed .. out
      else
        self.preedit:highlight(self.conv_feed .. self.kana_feed)
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
