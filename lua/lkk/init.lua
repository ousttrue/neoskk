---
--- vim の状態管理
---
local MODULE_NAME = "lkk"
local KEYS = vim.split("abcdefghijklmnopqrstuvwxyz", "")
local kanaconv = require "lkk.kanaconv"

local M = {}

---@class Lkk
---@field feed string
M.Lkk = {}

---@param opts any
---@return Lkk
function M.Lkk.new(opts)
  local self = setmetatable({
    feed = "",
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
    return nil
  end, function(content)
    -- reload
    require(MODULE_NAME).Skk.new()
  end)

  return self
end

function M.Lkk.delete(self)
  self:unmap()
end

--- language-mapping
function M.Lkk.map(self)
  for _, lhs in ipairs(KEYS) do
    vim.keymap.set("l", lhs, function()
      local out, feed = kanaconv.to_kana(lhs, self.feed)
      self.feed = feed
      return out
    end, {
      -- buffer = true,
      silent = true,
      expr = true,
    })
  end
end

function M.Lkk.unmap(self)
  -- language-mapping
  for _, lhs in ipairs(KEYS) do
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
  self.feed = ""

  if vim.bo.iminsert ~= 1 then
    return ""
  end

  -- vim.defer_fn(function()
  local indicator = require "tools.indicator"
  indicator.set "Aa"
  indicator:close()
  -- end, 0)
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

function M.setup(opts)
  M.opts = opts
  M.get_or_create()
end

function M.get_or_create()
  if not M.instance then
    M.instance = M.Lkk.new(M.opts)
  end
  return M.instance
end

return M
