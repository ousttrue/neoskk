---
--- vim の状態管理
---
local MODULE_NAME = "neoskk"
local KEYS_LOWER = vim.split("abcdefghijklmnopqrstuvwxyz", "")
local KEYS_SYMBOL = vim.split("., -~[]\b0123456789", "")
local PreEdit = require "neoskk.PreEdit"
local SkkDict = require "neoskk.SkkDict"
local SkkMachine = require "neoskk.SkkMachine"
local Completion = require "neoskk.Completion"

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
---@field dict SkkDict
M.NeoSkk = {}
M.NeoSkk.__index = M.NeoSkk

---@param opts Opts?
---@return NeoSkk
function M.NeoSkk.new(opts)
  local self = setmetatable({
    opts = opts and opts or {},
    state = SkkMachine.new(),
    conv_col = 0,
    preedit = PreEdit.new(MODULE_NAME),
    map_keys = {},
    dict = SkkDict.new(),
  }, M.NeoSkk)
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
    new_self.dict = old.dict
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
  if not completed_item or not completed_item.user_data then
    return
  end
  local user_data = completed_item.user_data
  if not user_data then
    return
  end
  if user_data.replace then
    -- print(vim.inspect(completed_item))
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0)) --- @type integer, integer
    cursor_row = cursor_row - 1

    -- Replace the already inserted word with user_data.replace
    local start_char = cursor_col - #completed_item.word
    print(cursor_row, cursor_col, start_char)
    vim.api.nvim_buf_set_text(bufnr, cursor_row, start_char, cursor_row, cursor_col, { user_data.replace })
  end
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

  local out, preedit, completion = self.state:input(lhs, self.dict)
  self.preedit:highlight(preedit)

  if completion then
    -- print(vim.inspect(completion))
    if not completion.items or #completion.items == 0 then
    elseif #completion.items == 1 then
      -- 確定
      local item = completion.items[1]
      out = item.word
    else
      -- completion
      vim.defer_fn(function()
        -- trigger completion
        local opt_backup = vim.opt.completeopt
        if completion.opts == Completion.SKK_OPTS then
          vim.opt.completeopt = { "menuone", "popup" }
        elseif completion.opts == Completion.FUZZY_OPTS then
          vim.opt.completeopt = {
            "menuone",
            "popup",
            "fuzzy",
            "noselect",
            "noinsert",
          }
        else
          --
        end
        -- completeopt
        vim.fn.complete(self.conv_col, completion.items)
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
    skk.dict:load_skk(opts.jisyo)
  end

  if opts.unihan then
    skk.dict:load_goma(opts.unihan)
  end
end

function M.toggle()
  return M.instance:toggle()
end

return M
