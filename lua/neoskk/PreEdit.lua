---@class Highlighter
---@field ns integer
---@field feed string
---@field bufnr integer?
local Highlighter = {}
Highlighter.__index = Highlighter

function Highlighter.new(ns)
  local self = setmetatable({
    ns = ns,
    feed = "",
  }, Highlighter)
  return self
end

-- local hl_groups = { "DiffAdd", "DiffChange", "DiffDelete" }
---@param bufnr integer
function Highlighter.highlight(self, winid, bufnr)
  local col = vim.fn.col(".", winid) - 1
  local row = vim.fn.line(".", winid) - 1

  if self.bufnr ~= bufnr or #self.feed == 0 then
    -- vim.api.nvim_buf_set_extmark(bufnr, self.ns, row, col, {
    --   virt_text = { { self.feed, "DiffAdd" } },
    --   virt_text_pos = "",
    --   ephemeral = true,
    -- })
    return false
  end

  -- local row, col = unpack(vim.api.nvim_win_get_cursor(0)) --- @type integer, integer
  -- row = row - 1

  vim.api.nvim_buf_set_extmark(bufnr, self.ns, row, col, {
    virt_text = { { self.feed, "DiffAdd" } },
    virt_text_pos = "overlay",
    ephemeral = true,
  })
  return true
end

---@class PreEdit
---@field ns integer
---@field highlighter Highlighter
PreEdit = {}
PreEdit.__index = PreEdit

---@param namespace string
function PreEdit.new(namespace)
  local ns = vim.api.nvim_create_namespace(namespace)
  local self = setmetatable({
    ns = ns,
    highlighter = Highlighter.new(ns),
  }, PreEdit)

  vim.api.nvim_set_decoration_provider(self.ns, {
    on_win = function(_, winid, bufnr)
      return self.highlighter:highlight(winid, bufnr)
    end,
  })

  return self
end

function PreEdit.delete(self)
  -- vim.api.nvim_buf_clear_namespace
end

function PreEdit:highlight(bufnr, feed)
  self.highlighter.bufnr = bufnr
  self.highlighter.feed = feed
  vim.defer_fn(function()
    vim.fn.winrestview(vim.fn.winsaveview())
  end, 0)
end

return PreEdit
