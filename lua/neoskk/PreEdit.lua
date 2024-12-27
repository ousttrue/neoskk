---@class Highlighter
---@field bufnr integer
---@field ns integer
---@field feed string
local Highlighter = {}

function Highlighter.new(bufnr, ns)
  local self = setmetatable({
    bufnr = bufnr,
    ns = ns,
    feed = "",
  }, { __index = Highlighter })
  return self
end

-- local hl_groups = { "DiffAdd", "DiffChange", "DiffDelete" }
function Highlighter.highlight(self)
  if #self.feed == 0 then
    return
  end
  local col = vim.fn.col "." - 1
  local row = vim.fn.line "." - 1
  vim.api.nvim_buf_set_extmark(self.bufnr, self.ns, row, col, {
    virt_text = { { self.feed, "DiffAdd" } },
    virt_text_pos = "overlay",
    ephemeral = true,
  })
end

local M = {}

---@class PreEdit
---@field ns integer
---@field bufmap {[integer]: Highlighter}
PreEdit = {}

---@param namespace string
function PreEdit.new(namespace)
  local self = setmetatable({
    ns = vim.api.nvim_create_namespace(namespace),
    bufmap = {},
  }, { __index = PreEdit })

  vim.api.nvim_set_decoration_provider(self.ns, {
    on_win = function(_, _, bufnr)
      -- return self.bufmap[bufnr] ~= nil
      if self.bufmap[bufnr] then
        self.bufmap[bufnr]:highlight()
      end
      return true
    end,
    -- on_line = function(_, _, bufnr, row)
    --   -- return true
    --   if self.bufmap[bufnr] then
    --     self.bufmap[bufnr]:highlight()
    --   end
    --   return true
    -- end,
  })

  return self
end

function PreEdit.delete(self)
  -- vim.api.nvim_buf_clear_namespace
end

function PreEdit.highlight(self, feed)
  local bufnr = vim.api.nvim_get_current_buf()
  local highlighter = self.bufmap[bufnr]
  if not highlighter then
    highlighter = Highlighter.new(bufnr, self.ns)
    self.bufmap[bufnr] = highlighter
  end
  highlighter.feed = feed
  vim.defer_fn(function()
    vim.fn.winrestview(vim.fn.winsaveview())
  end, 0)
end

return PreEdit 
