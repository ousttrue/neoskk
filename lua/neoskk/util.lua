local utf8 = require "neoskk.utf8"
local M = {}

--- [平仮名 (Unicodeのブロック)](https://ja.wikipedia.org/wiki/%E5%B9%B3%E4%BB%AE%E5%90%8D_(Unicode%E3%81%AE%E3%83%96%E3%83%AD%E3%83%83%E3%82%AF))

local HIRA_MIN = 0x3040
local HIRA_MAX = 0x309F

---@param cp integer
---@return boolean
function M.codepoint_is_hirakana(cp)
  if cp < HIRA_MIN then
    return false
  end
  if cp > HIRA_MAX then
    return false
  end
  return true
end

---@param src string
---@return boolean
function M.str_is_hirakana(src)
  for _, c in utf8.codes(src) do
    local cp = utf8.codepoint(c)
    if not M.codepoint_is_hirakana(cp) then
      return false
    end
  end
  return true
end

--- [片仮名 (Unicodeのブロック)](https://ja.wikipedia.org/wiki/%E7%89%87%E4%BB%AE%E5%90%8D_(Unicode%E3%81%AE%E3%83%96%E3%83%AD%E3%83%83%E3%82%AF))

local KATA_MIN = 0x30A0
local KATA_MAX = 0x30FF

---@param cp integer
---@return boolean
function M.codepoint_is_katakana(cp)
  if cp < KATA_MIN then
    return false
  end
  if cp > KATA_MAX then
    return false
  end
  return true
end

function M.str_is_katakana(src)
  for _, c in utf8.codes(src) do
    local cp = utf8.codepoint(c)
    if not M.codepoint_is_katakana(c) then
      return false
    end
  end
  return true
end

---@param src string
---@return string
function M.str_to_katakana(src)
  local dst = ""
  for _, c in utf8.codes(src) do
    local cp = utf8.codepoint(c)
    if M.codepoint_is_hirakana(cp) then
      c = utf8.char(cp + 96)
    end
    dst = dst .. c
  end
  return dst
end

---@param src string
---@return string
function M.str_to_hirakana(src)
  local dst = ""
  for _, c in utf8.codes(src) do
    local cp = utf8.codepoint(c)
    if M.codepoint_is_katakana(cp) then
      c = utf8.char(cp - 96)
    end
    dst = dst .. c
  end
  return dst
end

---@param src string
---@return string
function M.str_toggle_kana(src)
  local dst = ""
  for _, c in utf8.codes(src) do
    local cp = utf8.codepoint(c)
    if M.codepoint_is_hirakana(cp) then
      c = utf8.char(cp + 96)
    elseif M.codepoint_is_katakana(cp) then
      c = utf8.char(cp - 96)
    end
    dst = dst .. c
  end
  return dst
end

---@param str string
---@param ts string?
---@param plain boolean?
function M.split(str, ts, plain)
  -- 引数がないときは空tableを返す
  assert(str)
  if not ts then
    ts = "%s"
  end

  local t = {}
  local i = 1
  while i <= #str do
    local s, e = string.find(str, ts, i, plain)
    if s then
      table.insert(t, str:sub(i, s - 1))
      i = e + 1
    else
      table.insert(t, str:sub(i))
      break
    end
  end

  return t
end

return M
