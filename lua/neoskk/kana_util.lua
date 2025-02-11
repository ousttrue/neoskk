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

local HIRA = [[
あいうえお
かきくけこ
さしすせそ
たちつてと
なにぬねの
はひふへほ
まみむめも
やゆよ
らりるれろ
わをん
がぎぐげご
ざじずぜぞ
だぢづでど
ばびぶべぼ
ぱぴぷぺぽ
ぁぃぅぇぉ
ゃゅょ
]]
local HIRA_LIST = {}
for _, code in utf8.codes(HIRA) do
  if #code > 1 then
    table.insert(HIRA_LIST, code)
  end
end
assert(#HIRA_LIST == 46 + 25 + 8)

local KATA = [[
アイウエオ
カキクケコ
サシスセソ
タチツテト
ナニヌネノ
ハヒフヘホ
マミムメモ
ヤユヨ
ラリルレロ
ワヲン
ガギグゲゴ
ザジズゼゾ
ダヂヅデド
バビブベボ
パピプペポ
ァィゥェォ
ャュョ
]]
local KATA_LIST = {}
for _, code in utf8.codes(KATA) do
  if #code > 1 then
    table.insert(KATA_LIST, code)
  end
end
assert(#KATA_LIST == #HIRA_LIST)

M.hira_to_kata = {}
M.kata_to_hira = {}

for i = 1, #HIRA_LIST do
  M.hira_to_kata[HIRA_LIST[i]] = KATA_LIST[i]
  M.kata_to_hira[KATA_LIST[i]] = HIRA_LIST[i]
end

-- assert(#M.hira_to_kata == #HIRA_LIST)
-- assert(#M.kata_to_hira == #KATA_LIST)

---@param src string
---@return string
function M.str_to_katakana(src)
  local dst = ""
  for _, c in utf8.codes(src) do
    local kata = M.hira_to_kata[c]
    if kata then
      dst = dst .. kata
    else
      dst = dst .. c
    end
  end
  return dst
end

---@param src string
---@return string
function M.str_to_hirakana(src)
  local dst = ""
  for _, c in utf8.codes(src) do
    local hira = M.kata_to_hira[c]
    if hira then
      dst = dst .. hira
    else
      dst = dst .. c
    end
  end
  return dst
end

---@param src string
---@return string
function M.str_toggle_kana(src)
  local dst = ""
  for _, c in utf8.codes(src) do
    local kata = M.hira_to_kata[c]
    local hira = M.kata_to_hira[c]
    if kata then
      dst = dst .. kata
    elseif hira then
      dst = dst .. hira
    else
      dst = dst .. c
    end
  end
  return dst
end

return M
