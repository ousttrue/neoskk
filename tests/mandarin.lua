local function readAll(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read "*all"
  f:close()
  return content
end

local data = readAll(os.getenv "USERPROFILE" .. "/Unihan/Unihan_Readings.txt")

local to_ascii = {
  --a
  ["ā"] = "a",
  ["á"] = "a",
  ["ǎ"] = "a",
  ["à"] = "a",
  --e
  ["ē"] = "e",
  ["é"] = "e",
  ["ě"] = "e",
  ["è"] = "e",
  --i
  ["ī"] = "i",
  ["í"] = "i",
  ["ǐ"] = "i",
  ["ì"] = "i",
  --o
  ["ō"] = "o",
  ["ó"] = "o",
  ["ǒ"] = "o",
  ["ò"] = "o",
  --u
  ["ū"] = "u",
  ["ú"] = "u",
  ["ǔ"] = "u",
  ["ù"] = "u",
  --
  ["üè"] = "üe",
  ["ǘ"] = "ü",
  ["ǚ"] = "ü",
  ["ǜ"] = "ü",
  ["ň"] = "n",
  ["ǹ"] = "n",
  ["ḿ"] = "m",
}

local pinyin = {}
for unicode, k, value in string.gmatch(data, "U%+([A-F0-9]+)\t(k%w+)\t([^\n]+)") do
  if k == "kMandarin" then
    for from, to in pairs(to_ascii) do
      value = value:gsub(from, to)
    end
    if not value:find " " then
      pinyin[value] = true
    end
  end
end

-- local map = {}
-- local i = 1
-- for k, v in pairs(pinyin) do
--   -- print(i, k)
--   -- table.insert(list, k)
--   -- i = i + 1
--   local m = k:match "[^%w ]+"
--   if m then
--     -- table.insert(list, m)
--     map[m] = true
--   end
-- end

local list = {}
for k, v in pairs(pinyin) do
  table.insert(list, k)
end
table.sort(list)

for i, v in ipairs(list) do
  print(i, v)
end
