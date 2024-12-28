local M = {}

---@param path string
---@param from string
---@param to string
---@return string
local function readFileSync(path, from, to, opts)
  local fd = assert(vim.uv.fs_open(path, "r", 438))
  local stat = assert(vim.uv.fs_fstat(fd))
  local data = assert(vim.uv.fs_read(fd, stat.size, 0))
  assert(vim.uv.fs_close(fd))
  return assert(vim.iconv(data, from, to, opts))
end

---@param l string
---@return string? key
---@return string? body
local function parse_line(l)
  if vim.startswith(l, ";") then
    return
  end

  local s, e = l:find "%s+/"
  if s and e then
    return l:sub(1, s - 1), l:sub(e)
  end
end

-- word		the text that will be inserted, mandatory
-- abbr		abbreviation of "word"; when not empty it is used in
-- 		the menu instead of "word"
-- menu		extra text for the popup menu, displayed after "word"
-- 		or "abbr"
-- info		more information about the item, can be displayed in a
-- 		preview window
-- kind		single letter indicating the type of completion
-- icase		when non-zero case is to be ignored when comparing
-- 		items to be equal; when omitted zero is used, thus
-- 		items that only differ in case are added
-- equal		when non-zero, always treat this item to be equal when
-- 		comparing. Which means, "equal=1" disables filtering
-- 		of this item.
-- dup		when non-zero this match will be added even when an
-- 		item with the same word is already present.
-- empty		when non-zero this match will be added even when it is
-- 		an empty string
-- user_data	custom data which is associated with the item and
-- 		available in |v:completed_item|; it can be any type;
-- 		defaults to an empty string
-- abbr_hlgroup	an additional highlight group whose attributes are
-- 		combined with |hl-PmenuSel| and |hl-Pmenu| or
-- 		|hl-PmenuMatchSel| and |hl-PmenuMatch| highlight
-- 		attributes in the popup menu to apply cterm and gui
-- 		properties (with higher priority) like strikethrough
-- 		to the completion items abbreviation
-- kind_hlgroup	an additional highlight group specifically for setting
-- 		the highlight attributes of the completion kind. When
-- 		this field is present, it will override the
-- 		|hl-PmenuKind| highlight group, allowing for the
-- 		customization of ctermfg and guifg properties for the
-- 		completion kind
---@param path string
function M.load_skk(path)
  if not vim.uv.fs_stat(path) then
    return
  end

  local jisyo = {}
  local data = readFileSync(path, "euc-jp", "utf-8", {})
  for i, l in ipairs(vim.split(data, "\n")) do
    local word, values = parse_line(l)
    if word and values then
      -- print(("[%s][%s]"):format(word, values))
      local items = jisyo[word]
      if not items then
        items = {}
        jisyo[word] = items
      end
      for w in values:gmatch "[^/]+" do
        local annotation = w:find(";", nil, true)
        if annotation then
          table.insert(items, {
            word = w:sub(1, annotation - 1),
            abbr = w,
          })
        else
          table.insert(items, {
            word = w,
            -- abbr = w,
          })
        end
      end
      -- break
    end
  end
  return jisyo
end

function M.load_goma(path)
end

function M.find_start()
  return 0
end

function M.find_completions(base)
  local items = {}
  if base then
    for k, v in pairs(M.jisyo) do
      if vim.startswith(k, base) then
        for _, item in ipairs(v) do
          table.insert(items, item)
        end
      end
    end
  end
  return items
  -- return {
  --   { word = "aa", menu = "file_complete" },
  --   { word = "あ", menu = "file_complete" },
  --   { word = "something", menu = "file_complete" },
  --   { word = "to" },
  --   { word = "complete" },
  --   { word = "devto" },
  -- }
end

return M
