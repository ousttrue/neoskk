---
--- vim の状態管理
---
local MODULE_NAME = "neoskk"

local KEYS_LOWER = vim.split("abcdefghijklmnopqrstuvwxyz", "")
local KEYS_SYMBOL = vim.split("., :;-+*~[](){}<>\b0123456789/", "")

local SkkMachine = require "neoskk.SkkMachine"
local ZhuyinMachine = require "neoskk.ZhuyinMachine"
local Indicator = require "neoskk.Indicator"
local util = require "neoskk.util"
local utf8 = require "neoskk.utf8"

local STATE_MODE_SKK = "skk"
local STATE_MODE_ZHUYIN = "zhuyin"
---@alias STATE_MODE `STATE_MODE_SKK` | `STATE_MODE_ZHUYIN`

local M = {
  ---@type STATE_MODE
  state_mode = STATE_MODE_SKK,
  marker = "▽",
}

---@class NeoSkk
---@field bufnr integer 対象のbuf。変わったら状態をクリアする
---@field state SkkMachine | ZhuyinMachine | nil 状態管理
---@field map_keys string[]
---@field indicator Indicator
M.NeoSkk = {}
M.NeoSkk.__index = M.NeoSkk

---@return NeoSkk
function M.NeoSkk.new()
  local self = setmetatable({
    bufnr = -1,
    map_keys = {},
    indicator = Indicator.new(),
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

  vim.api.nvim_create_autocmd({
    "InsertLeave",
  }, {
    group = group,
    pattern = { "*" },
    callback = function(ev)
      self.indicator:close()
    end,
  })

  vim.api.nvim_create_autocmd({
    "WinLeave",
  }, {
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
    new_module.NeoSkk.new()
  end)

  M.instance = self
  return self
end

function M.NeoSkk:flush()
  if self.bufnr ~= -1 then
    self.bufnr = -1
  end
  -- self.state = nil
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
    return M.marker
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
    -- if util.get_current_line_cursor_left():match(M.marker) then
    -- else
    out = M.marker .. out
    -- end
  end

  local preedit_len = utf8.len(kana_feed)
  if preedit_len then
    local delete_preedit = string.rep("\b", preedit_len)
    out = delete_preedit .. out
  end

  return out .. (preedit and preedit or "")
end

---@return string
function M.NeoSkk:get_feed()
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
  M.NeoSkk.new(opts)
end

function M.kana_toggle()
  -- https://minerva.mamansoft.net/Notes/%E3%83%93%E3%82%B8%E3%83%A5%E3%82%A2%E3%83%AB%E3%83%A2%E3%83%BC%E3%83%89%E3%81%A7%E9%81%B8%E6%8A%9E%E4%B8%AD%E3%81%AE%E3%83%86%E3%82%AD%E3%82%B9%E3%83%88%E5%8F%96%E5%BE%97+(Neovim)
  local start_pos = vim.fn.getpos "v"
  local end_pos = vim.fn.getpos "."
  local lines = vim.api.nvim_buf_get_lines(start_pos[1], start_pos[2] - 1, end_pos[2], false)
  local e
  if #lines == 1 then
    e = vim.str_utf_end(lines[1], end_pos[3])
    lines[1] = lines[1]:sub(start_pos[3], end_pos[3] + e)
  else
    lines[1] = lines[1]:sub(start_pos[3])
    e = vim.str_utf_end(lines[#lines], end_pos[3])
    lines[#lines] = lines[#lines]:sub(1, end_pos[3] + e)
  end
  local line = table.concat(lines, "\n")
  local mod = require("neoskk.kana_util").str_toggle_kana(line)

  vim.api.nvim_buf_set_text(
    start_pos[1],
    --
    start_pos[2] - 1,
    start_pos[3] - 1,
    --
    end_pos[2] - 1,
    end_pos[3] + e,
    { mod }
  )

  -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", false)
  vim.api.nvim_feedkeys("\027", "xt", false)
end

return M
