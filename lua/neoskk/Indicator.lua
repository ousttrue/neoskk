local MODULE_NAME = "neoskk.indicator"
local USER_SET_CONTENT = "neoskk.indicator.set_content"
local ColorMap = {
  NeoSkkDefault = {
    fg = "#444444",
    force = true,
  },
  NeoSkkHira = {
    fg = "#eeeeee",
    bg = "#2222ff",
    force = true,
  },
}

---@class Content
---@field ns integer
---@field content string
---@field lines string[]
---@field cols integer
---@field rows integer
local Content = {}
Content.__index = Content

---@return Content
function Content.new()
  local self = setmetatable({}, Content)

  -- self.ns = vim.api.nvim_create_namespace(MODULE_NAME)

  vim.defer_fn(function()
    for k, v in pairs(ColorMap) do
      -- print("Content.new", k)
      vim.api.nvim_set_hl(0, k, v)
    end
  end, 1)

  return self
end

---@param content string
function Content.set(self, content)
  self.content = content
  self.lines = nil
end

function Content.get_lines(self, buf)
  if not self.content then
    return nil
  end
  if self.lines then
    return self.lines
  end
  self.lines = vim.fn.split(self.content, "\n")
  self.cols = 0
  self.rows = 0
  for i, line in ipairs(self.lines) do
    if #line > self.cols then
      self.cols = vim.fn.strwidth(line)
    end
    self.rows = self.rows + 1
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, self.lines)
end

---@class Indicator
---@field buf number
---@field win number
---@field content Content
---@field hl string?
local Indicator = {
  content = Content.new(),
}
Indicator.__index = Indicator

function Indicator.new()
  local self = setmetatable({
    content = Content.new(),
  }, Indicator)

  --
  -- buf
  --
  self.buf = vim.api.nvim_create_buf(false, true)
  self.content:set " "

  --
  -- VimEvent
  --
  local group = vim.api.nvim_create_augroup(MODULE_NAME, { clear = true })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    callback = function(event)
      self:redraw()
    end,
  })

  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = group,
    callback = function(event)
      self:redraw()
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = USER_SET_CONTENT,
    callback = function(event)
      -- self:redraw()
      vim.defer_fn(function()
        self:set_content(event.data.content)
        self.hl = event.data.hl
        self:redraw()
      end, 0)
    end,
  })

  return self
end

function Indicator.redraw(self)
  if not self.win then
    return
  end

  local hl = self.hl
  if not hl then
    hl = "NeoSkkDefault"
  end
  vim.wo[self.win].winhighlight = "Normal:" .. hl
  -- print(self.hl, vim.wo[self.win].winhighlight)

  local lines = self.content:get_lines(self.buf)
  if not lines then
    return
  end

  local y, x = unpack(vim.fn.win_screenpos(0))
  local row = vim.fn.winline()
  local col = vim.fn.wincol()
  local anchor = ""
  if row > self.content.rows + 2 then
    row = y + row - 1
    anchor = "SW"
  else
    row = y + row
    anchor = "NW"
  end

  col = x + col - 2
  local width = self.content.cols
  if width == 0 then
    width = 1
  end
  local height = self.content.rows
  if height == 0 then
    height = 1
  end
  vim.api.nvim_win_set_config(self.win, {
    relative = "editor",
    anchor = anchor,
    row = row,
    col = col,
    width = width,
    height = height,
    zindex = 1,
  })
end

---@param content string
---@param hl string?
function Indicator.set_content(self, content, hl)
  self.content:set(content, hl)
end

function Indicator.open(self)
  if self.win then
    return
  end
  local win = vim.api.nvim_open_win(self.buf, false, {
    relative = "editor",
    row = 1,
    col = 1,
    width = 1,
    height = 1,
    -- border = "rounded",
    zindex = 9001,
    style = "minimal",
  })
  vim.wo[win].winfixbuf = true
  self.win = win
  self:redraw()
end

function Indicator.close(self)
  if self.win then
    vim.api.nvim_win_close(self.win, false)
    self.win = nil
  end
end

function Indicator.toggle_window(self)
  if self.win then
    self:close()
  else
    self:open()
  end
end

function Indicator.delete(self)
  self:close()
  vim.api.nvim_buf_delete(self.buf, {
    force = true,
    unload = false,
  })
end

---@param content string
---@param hl string?
function Indicator.set(content, hl)
  if not hl then
    if content:find "^平" then
      hl = "NeoSkkHira"
    end
  end

  vim.api.nvim_exec_autocmds("User", {
    pattern = USER_SET_CONTENT,
    data = { content = content, hl = hl },
  })
end

return Indicator
