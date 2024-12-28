---@class Highlighter
---@field ns integer
---@field feed string
local Highlighter = {}

function Highlighter.new(ns)
  local self = setmetatable({
    ns = ns,
    feed = "",
  }, { __index = Highlighter })
  return self
end

-- local hl_groups = { "DiffAdd", "DiffChange", "DiffDelete" }
---@param bufnr integer
function Highlighter.highlight(self, bufnr)
  if #self.feed == 0 then
    return
  end
  local col = vim.fn.col "." - 1
  local row = vim.fn.line "." - 1
  vim.api.nvim_buf_set_extmark(bufnr, self.ns, row, col, {
    virt_text = { { self.feed, "DiffAdd" } },
    virt_text_pos = "overlay",
    ephemeral = true,
  })
end

---@class PreEdit
---@field ns integer
---@field highlighter Highlighter
PreEdit = {}

---@param namespace string
function PreEdit.new(namespace)
  local ns = vim.api.nvim_create_namespace(namespace)
  local self = setmetatable({
    ns = ns,
    highlighter = Highlighter.new(ns),
  }, { __index = PreEdit })

  vim.api.nvim_set_decoration_provider(self.ns, {
    on_win = function(_, _, bufnr)
      self.highlighter:highlight(bufnr)
      return true
    end,
  })

  return self
end

function PreEdit.delete(self)
  -- vim.api.nvim_buf_clear_namespace
end

function PreEdit.highlight(self, feed)
  if self.highlighter.feed == feed then
    return
  end
  self.highlighter.feed = feed
  vim.defer_fn(function()
    vim.fn.winrestview(vim.fn.winsaveview())
  end, 0)
end

return PreEdit
