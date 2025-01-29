-- 平水韻(106)と廣韻(206)の対応 from 唐詩概説
-- かな from 新修平仄字典

---韻目
---@class YunMu
---@field name string 韻目
---@field guangyun string[] 廣韻の対応する韻目
---@field kana string かな
---@field zhuyin string 注音
local YunMu = {}
YunMu.__index = YunMu

function YunMu.new(kana, zhuyin, ...)
  local guangyun = { ... }
  local self = setmetatable({
    name = guangyun[1],
    kana = kana,
    zhuyin,
    guangyun = guangyun,
  }, YunMu)
  return self
end

---@return string
function YunMu:__tostring()
  return ("<%s#%d>"):format(self.guangyun[1], #self.guangyun)
end

---@param yun string
---@return boolean
function YunMu:has(yun)
  for _, x in ipairs(self.guangyun) do
    if x == yun then
      return true
    end
  end
  return false
end

local M = {}

--- 平、上、去、入
---@type [YunMu?, YunMu?, YunMu?, YunMu?][]
M.list = {
  -- ng,k
  {
    YunMu.new("ou", "ㄨㄥ", "東"), -- とう
    YunMu.new("ou", "ㄨㄥ", "董"), -- とう
    YunMu.new("ou", "ㄨㄥ", "送"), -- そう
    YunMu.new("ok", "ㄨ", "屋"), -- おく
  },
  {
    YunMu.new("ou", "ㄨㄥ", "冬", "鍾"), -- とう
    YunMu.new("ou", "ㄨㄥ", "腫"), -- しょう
    YunMu.new("ou", "ㄨㄥ", "宋", "用"), -- そう
    YunMu.new("ok", "ㄨ", "沃", "燭"), -- よく
  },
  {
    YunMu.new("au", "ㄧㄤ", "江"), -- かう
    YunMu.new("au", "ㄧㄤ", "講"), -- かう
    YunMu.new("au", "ㄧㄤ", "絳"), -- かう
    YunMu.new("ak", "ㄝ", "覺", "覚"), -- かく
  },
  -- i
  {
    YunMu.new("i", "ㄭ", "支", "脂", "之"), -- し
    YunMu.new("i", "ㄭ", "紙", "旨", "止"), -- し
    YunMu.new("i", "ㄭ", "寘", "至", "志"), -- し
    nil,
  },
  {
    YunMu.new("i", "ㄨㄟ", "微"), -- び
    YunMu.new("i", "ㄨㄟ", "尾"), -- び
    YunMu.new("i", "ㄨㄟ", "未"), -- み
    nil,
  },
  {
    YunMu.new("o", "ㄩ", "魚"), -- ぎょ
    YunMu.new("o", "ㄩ", "語"), -- ご
    YunMu.new("o", "ㄩ", "御"), -- ご
    nil,
  },
  {
    YunMu.new("u", "ㄩ", "虞", "模"), -- ぐ
    YunMu.new("u", "ㄩ", "麌", "姥"), -- ぐ
    YunMu.new("u", "ㄩ", "遇", "暮"), -- ぐ
    nil,
  },
  {
    YunMu.new("ei", "ㄧ", "斉"), -- せい
    YunMu.new("ei", "ㄧ", "薺"), -- せい
    YunMu.new("ei", "ㄧ", "霽", "祭"), -- せい
    nil,
  },
  {
    nil,
    nil,
    YunMu.new("ai", "ㄞ", "泰"), -- たい
    nil,
  },
  {
    YunMu.new("a", "ㄧㄚ", "佳", "皆"), -- かい
    YunMu.new("a", "ㄧㄝ", "蟹", "駭"), -- かい
    YunMu.new("a", "ㄨㄚ", "卦", "怪", "夬"), -- くわい
    nil,
  },
  {
    YunMu.new("ai", "ㄨㄟ", "灰", "咍"), -- はい
    YunMu.new("ai", "ㄨㄟ", "賄", "海"), -- わい
    YunMu.new("ai", "ㄨㄟ", "隊", "代", "廃"), -- たい
    nil,
  },
  ---
  {
    YunMu.new("in", "ㄭㄣ", "真", "諄", "臻"), -- しん
    YunMu.new("in", "ㄭㄣ", "軫", "準"), -- しん
    YunMu.new("in", "ㄭㄣ", "震", "稕"), -- しん
    YunMu.new("it", "ㄭ", "質", "術", "櫛"), -- しつ
  },
  {
    YunMu.new("un", "ㄨㄣ", "文", "欣"), -- ぶん
    YunMu.new("un", "ㄨㄣ", "吻"), -- ぶん
    YunMu.new("un", "ㄨㄣ", "問"), -- ぶん
    YunMu.new("ut", "ㄨ", "物"), -- ぶつ
  },
  {
    YunMu.new("en", "ㄩㄢ", "元", "魂", "痕"), -- げん
    YunMu.new("en", "ㄩㄢ", "阮"),
    YunMu.new("en", "ㄩㄢ", "願"),
    YunMu.new("et", "ㄩㄝ", "月"),
  },
  {
    YunMu.new("an", "ㄢ", "寒", "桓"), -- くわん
    YunMu.new("an", "ㄢ", "旱"),
    YunMu.new("an", "ㄢ", "翰"),
    YunMu.new("at", "ㄜ", "曷"),
  },
  {
    YunMu.new("an", "ㄢ", "刪", "山"), -- さん
    YunMu.new("an", "ㄢ", "潸"),
    YunMu.new("an", "ㄢ", "諫"),
    YunMu.new("at", "ㄧㄚ", "黠"),
  },
  {
    YunMu.new("en", "ㄧㄢ", "先"),
    YunMu.new("en", "ㄧㄢ", "銑"),
    YunMu.new("en", "ㄧㄢ", "霰"),
    YunMu.new("et", "ㄧㄝ", "屑"),
  },
  {
    YunMu.new("eu", "ㄧㄠ", "蕭"),
    YunMu.new("eu", "ㄧㄠ", "篠"),
    YunMu.new("eu", "ㄧㄠ", "嘯"),
    nil,
  },
  {
    YunMu.new("au", "ㄧㄠ", "肴"),
    YunMu.new("au", "ㄧㄠ", "巧"),
    YunMu.new("au", "ㄧㄠ", "效"),
    nil,
  },
  {
    YunMu.new("au", "ㄠ", "豪"),
    YunMu.new("au", "ㄠ", "晧"),
    YunMu.new("au", "ㄠ", "号"),
    nil,
  },
  {
    YunMu.new("a", "ㄜ", "歌"),
    YunMu.new("a", "ㄜ", "哿"),
    YunMu.new("a", "ㄜ", "箇"),
    nil,
  },
  {
    YunMu.new("a", "ㄚ", "麻"),
    YunMu.new("a", "ㄚ", "馬"),
    YunMu.new("a", "ㄚ", "禡"),
    nil,
  },
  {
    YunMu.new("au", "ㄧㄤ", "陽", "唐"),
    YunMu.new("au", "ㄧㄤ", "養", "蕩"),
    YunMu.new("au", "ㄧㄤ", "漾", "宕"),
    YunMu.new("ak", "ㄧㄠ", "薬", "藥", "鐸"),
  },
  {
    YunMu.new("au", "ㄠ", "庚", "耕", "清"),
    YunMu.new("au", "ㄠ", "梗", "耿", "静"),
    YunMu.new("au", "ㄠ", "敬", "諍", "勁"),
    YunMu.new("ak", "ㄜ", "陌", "麦", "昔"),
  },
  {
    YunMu.new("ei", "ㄧㄥ", "青"),
    YunMu.new("ei", "ㄧㄥ", "迥"),
    YunMu.new("ei", "ㄧㄥ", "径"),
    YunMu.new("ek", "ㄧ", "錫"),
  },
  {
    YunMu.new("ou", "ㄭㄥ", "蒸"),
    nil,
    nil,
    YunMu.new("ok", "ㄭ", "職", "德"),
  },
  {
    YunMu.new("iu", "ㄧㄡ", "尤"),
    YunMu.new("iu", "ㄧㄡ", "有"),
    YunMu.new("iu", "ㄧㄡ", "宥"),
    nil,
  },
  {
    YunMu.new("im", "ㄧㄣ", "侵"),
    YunMu.new("im", "ㄧㄣ", "寝"),
    YunMu.new("im", "ㄧㄣ", "沁"),
    YunMu.new("ip", "ㄧ", "緝"),
  },
  {
    YunMu.new("om", "ㄢ", "覃"),
    YunMu.new("om", "ㄢ", "感"),
    YunMu.new("om", "ㄢ", "勘"),
    YunMu.new("op", "ㄜ", "合"),
  },
  {
    YunMu.new("em", "ㄧㄢ", "塩"),
    YunMu.new("em", "ㄧㄢ", "琰"),
    YunMu.new("em", "ㄧㄢ", "艶"),
    YunMu.new("ep", "ㄧㄝ", "葉", "帖", "怗", "業"),
  },
  {
    YunMu.new("em", "ㄧㄢ", "咸"),
    YunMu.new("em", "ㄧㄢ", "豏"),
    YunMu.new("em", "ㄧㄢ", "陥"),
    YunMu.new("ep", "ㄧㄚ", "洽"),
  },
}

-- 攝
M.she = {
  ["通"] = { "東", "冬", "鍾" },
  ["江"] = { "江" },
  ["止"] = { "支", "脂", "之", "微" },
  ["遇"] = { "魚", "虞", "模" },
  ["蟹"] = { "斉", "祭", "泰", "佳", "皆", "夬", "灰", "咍", "廃" },
  ["臻"] = { "真", "諄", "臻", "文", "欣", "元", "魂", "痕" },
  ["山"] = { "寒", "桓", "刪", "山", "先", "仙" },
  ["效"] = { "蕭", "宵", "肴", "豪" },
  ["果"] = { "歌", "戈" },
  ["仮"] = { "麻" },
  ["宕"] = { "陽", "唐" },
  ["梗"] = { "庚", "耕", "清", "青" },
  ["曾"] = { "蒸", "登" },
  ["流"] = { "尤", "侯", "幽" },
  ["深"] = { "侵" },
  ["咸"] = { "覃", "談", "鹽", "添", "咸", "銜", "厳", "凡" },
}

--十六攝
---@param guang string 廣韻韻目
---@return string? 攝
function M.get_she(guang)
  for k, v in pairs(M.she) do
    for _, x in ipairs(v) do
      if x == guang then
        return k
      end
    end
  end
end

---@param guang string 廣韻韻目
---@return string? 平水韻
---@return string? 平水韻平聲
function M.get_heisui(guang)
  -- 祭A
  guang = guang:match "^[^%w]+"
  for _, line in ipairs(M.list) do
    for _, yun in ipairs(line) do
      if yun then
        for _, g in ipairs(yun.guangyun) do
          if g == guang then
            return yun.name, line[1] and line[1].name
          end
        end
      end
    end
  end
  --
end

---@param search string
---@return string
function M.get_group(search)
  for _, group in ipairs(M.list) do
    -- local a, b, c, d = unpack(group)
    local a = group[1]
    local b = group[2]
    local c = group[3]
    local d = group[4]
    -- print(a, b, c, d)

    if a and a:has(search) then
      return ("`%s`%s%s%s"):format(
        a and a.name or "〇",
        b and b.name or "〇",
        c and c.name or "〇",
        d and d.name or "〇"
      )
    end

    if b and b:has(search) then
      return ("%s`%s`%s%s"):format(
        a and a.name or "〇",
        b and b.name or "〇",
        c and c.name or "〇",
        d and d.name or "〇"
      )
    end

    if c and c:has(search) then
      return ("%s%s`%s`%s"):format(
        a and a.name or "〇",
        b and b.name or "〇",
        c and c.name or "〇",
        d and d.name or "〇"
      )
    end

    if d and d:has(search) then
      return ("%s%s%s`%s`"):format(
        a and a.name or "〇",
        b and b.name or "〇",
        c and c.name or "〇",
        d and d.name or "〇"
      )
    end
  end

  return search .. " NOT_FOUND"
end

return M
