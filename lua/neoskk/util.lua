local utf8 = require "neoskk.utf8"
local M = {}

--- [平仮名 (Unicodeのブロック)](https://ja.wikipedia.org/wiki/%E5%B9%B3%E4%BB%AE%E5%90%8D_(Unicode%E3%81%AE%E3%83%96%E3%83%AD%E3%83%83%E3%82%AF))
---@param src string
---@return string
function M.hira_to_kata(src)
  -- return src:gsub("[\\u30a1-\\u30f6]+", function(s)
  --   print('hoge', s)
  --   -- return vim.fn.nr2char(vim.fn.char2nr(s) + 96)
  --   return s
  -- end)

  local dst = ""
  for _, c in utf8.codes(src) do
    local cp = utf8.codepoint(c)
    if cp >= 0x3040 and cp <= 0x309F then
      c = utf8.char(cp + 96)
    end
    dst = dst .. c
  end
  return dst
end

return M
