local utf8 = require "neoskk.utf8"
-- 平水韻(106)と廣韻(206)の対応 from 唐詩概説
-- https://ytenx.org/kyonh/

---平水韻 韻目
---@class YunMu
---@field name string 韻目
---@field guangyun string[] 廣韻の対応する韻目
---@field kana string かな
---@field zhuyin string 注音
local YunMu = {}
YunMu.__index = YunMu

---@param ... string 廣韻韻目
---@return YunMu
function YunMu.new(...)
  local guangyun = { ... }
  local self = setmetatable({
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

---韻攝
---@class YunShe
---@field name string
---@field list [YunMu?, YunMu?, YunMu?, YunMu?][] 四声相配された韻目のリスト
local YunShe = {}
YunShe.__index = YunShe

---@param guangyun string
---@return boolean
function YunShe:has_guangyun(guangyun)
  for _, yunmu_list in ipairs(self.list) do
    for _, m in ipairs(yunmu_list) do
      if m then
        for _, g in ipairs(m.guangyun) do
          if g == guangyun then
            return true
          end
        end
      end
    end
  end
  return false
end

---@param name string
---@param list [YunMu?, YunMu?, YunMu?, YunMu?][]
---@return YunShe
function YunShe.new(name, list)
  local self = setmetatable({
    name = name,
    list = list,
  }, YunShe)
  return self
end

local M = {}

---@type YunShe[]
M.list = {
  YunShe.new("通", {
    {
      YunMu.new "東", -- とう
      YunMu.new "董", -- とう
      YunMu.new "送", -- そう
      YunMu.new "屋", -- おく
    },
    {
      YunMu.new("冬", "鍾"), -- とう
      YunMu.new "腫", -- しょう
      YunMu.new("宋", "用"), -- そう
      YunMu.new("沃", "燭"), -- よく
    },
  }),
  YunShe.new("江", {
    {
      YunMu.new "江", -- かう
      YunMu.new "講", -- かう
      YunMu.new "絳", -- かう
      YunMu.new("覺", "覚"), -- かく
    },
  }),
  YunShe.new("止", {
    {
      YunMu.new("支", "脂", "之"), -- し
      YunMu.new("紙", "旨", "止"), -- し
      YunMu.new("寘", "至", "志"), -- し
      nil,
    },
    {
      YunMu.new "微", -- び
      YunMu.new "尾", -- び
      YunMu.new "未", -- み
      nil,
    },
  }),
  YunShe.new("遇", {
    {
      YunMu.new "魚", -- ぎょ
      YunMu.new "語", -- ご
      YunMu.new "御", -- ご
      nil,
    },
    {
      YunMu.new("虞", "模"), -- ぐ
      YunMu.new("麌", "姥"), -- ぐ
      YunMu.new("遇", "暮"), -- ぐ
      nil,
    },
  }),
  YunShe.new("蟹", {
    {
      YunMu.new "斉", -- せい
      YunMu.new "薺", -- せい
      YunMu.new("霽", "祭"), -- せい
      nil,
    },
    {
      nil,
      nil,
      YunMu.new "泰", -- たい
      nil,
    },
    {
      YunMu.new("佳", "皆"), -- かい
      YunMu.new("蟹", "駭"), -- かい
      YunMu.new("卦", "怪", "夬"), -- くわい
      nil,
    },
    {
      YunMu.new("灰", "咍"), -- はい
      YunMu.new("賄", "海"), -- わい
      YunMu.new("隊", "代", "廃"), -- たい
      nil,
    },
  }),
  YunShe.new("臻", {
    {
      YunMu.new("眞", "諄", "臻"), -- しん
      YunMu.new("軫", "準"), -- しん
      YunMu.new("震", "稕"), -- しん
      YunMu.new("質", "術", "櫛"), -- しつ
    },
    {
      YunMu.new("文", "欣"), -- ぶん
      YunMu.new "吻", -- ぶん
      YunMu.new "問", -- ぶん
      YunMu.new "物", -- ぶつ
    },
    {
      YunMu.new("元", "魂", "痕"), -- げん
      YunMu.new "阮",
      YunMu.new "願",
      YunMu.new "月",
    },
  }),
  YunShe.new("山", {
    {
      YunMu.new("寒", "桓"), -- くわん
      YunMu.new("旱", "緩"),
      YunMu.new("翰", "換"),
      YunMu.new("曷", "末"),
    },
    {
      YunMu.new("刪", "山"), -- さん
      YunMu.new("潸", "產"),
      YunMu.new("諫", "襇"),
      YunMu.new("黠", "鎋"),
    },
    {
      YunMu.new("先", "仙"),
      YunMu.new("銑", "獮"),
      YunMu.new("霰", "線"),
      YunMu.new("屑", "薛"),
    },
  }),
  YunShe.new("效", {
    {
      YunMu.new("蕭", "宵"),
      YunMu.new("篠", "小"),
      YunMu.new("嘯", "笑"),
      nil,
    },
    {
      YunMu.new "肴",
      YunMu.new "巧",
      YunMu.new "效",
      nil,
    },
    {
      YunMu.new "豪",
      YunMu.new "晧",
      YunMu.new "号",
      nil,
    },
  }),
  YunShe.new("果", {
    {
      YunMu.new("歌", "戈"),
      YunMu.new("哿", "果"),
      YunMu.new("箇", "過"),
      nil,
    },
  }),
  YunShe.new("仮", {
    {
      YunMu.new "麻",
      YunMu.new "馬",
      YunMu.new "禡",
      nil,
    },
  }),
  YunShe.new("宕梗", {
    {
      YunMu.new("陽", "唐"),
      YunMu.new("養", "蕩"),
      YunMu.new("漾", "宕"),
      YunMu.new("薬", "藥", "鐸"),
    },
    {
      YunMu.new("庚", "耕", "清"),
      YunMu.new("梗", "耿", "静"),
      YunMu.new(--[["敬"]]"映", "諍", "勁"),
      YunMu.new("陌", "麦", "昔"),
    },
    {
      YunMu.new "青",
      YunMu.new "迥",
      YunMu.new "徑",
      YunMu.new "錫",
    },
  }),
  YunShe.new("曾", {
    {
      YunMu.new("蒸", "登"),
      YunMu.new("拯", "等"),
      YunMu.new("證", "嶝"),
      YunMu.new("職", "德"),
    },
  }),
  YunShe.new("流", {
    {
      YunMu.new("尤", "侯", "幽"),
      YunMu.new("有", "厚", "黝"),
      YunMu.new("宥", "候", "幼"),
      nil,
    },
  }),
  YunShe.new("深", {
    {
      YunMu.new "侵",
      YunMu.new "寝",
      YunMu.new "沁",
      YunMu.new "緝",
    },
  }),
  YunShe.new("咸", {
    {
      YunMu.new("覃", "談"),
      YunMu.new("感", "敢"),
      YunMu.new("勘", "闞"),
      YunMu.new("合", "盍"),
    },
    {
      YunMu.new("鹽", "添", "厳"),
      YunMu.new("琰", "忝", "儼"),
      YunMu.new("艶", "㮇", "釅"),
      YunMu.new("葉", "帖", "業"),
    },
    {
      YunMu.new("咸", "銜", "凡"),
      YunMu.new("豏", "檻", "范"),
      YunMu.new("陥", "鑑", "梵"),
      YunMu.new("洽", "狎", "乏"),
    },
  }),
}

--十六攝
---@param guang string 廣韻韻目
---@return YunShe? 韻攝
---@return YunMu? 韻目 平水韻
function M.get_she(guang)
  for _, ch in utf8.codes(guang) do
    -- 支A など対策
    if ch ~= guang then
      print(ch, guang)
    end
    guang = ch
    break
  end

  for _, yunshe in ipairs(M.list) do
    for _, group in ipairs(yunshe.list) do
      local a = group[1]
      local b = group[2]
      local c = group[3]
      local d = group[4]
      if a and a:has(guang) then
        return yunshe, a
      end
      if b and b:has(guang) then
        return yunshe, b
      end
      if c and c:has(guang) then
        return yunshe, c
      end
      if d and d:has(guang) then
        return yunshe, d
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
  for _, she in ipairs(M.list) do
    for _, group in ipairs(she.list) do
      -- unpack は nil が入っるとだめ
      -- local a, b, c, d = unpack(group)
      local a = group[1]
      local b = group[2]
      local c = group[3]
      local d = group[4]

      if a and a:has(search) then
        return ("`%s`%s%s%s"):format(
          a and a.guangyun[1] or "〇",
          b and b.guangyun[1] or "〇",
          c and c.guangyun[1] or "〇",
          d and d.guangyun[1] or "〇"
        )
      end

      if b and b:has(search) then
        return ("%s`%s`%s%s"):format(
          a and a.guangyun[1] or "〇",
          b and b.guangyun[1] or "〇",
          c and c.guangyun[1] or "〇",
          d and d.guangyun[1] or "〇"
        )
      end

      if c and c:has(search) then
        return ("%s%s`%s`%s"):format(
          a and a.guangyun[1] or "〇",
          b and b.guangyun[1] or "〇",
          c and c.guangyun[1] or "〇",
          d and d.guangyun[1] or "〇"
        )
      end

      if d and d:has(search) then
        return ("%s%s%s`%s`"):format(
          a and a.guangyun[1] or "〇",
          b and b.guangyun[1] or "〇",
          c and c.guangyun[1] or "〇",
          d and d.guangyun[1] or "〇"
        )
      end
    end
  end

  return search .. " NOT_FOUND"
end

function M.get_groups(search)
  local list = {}
  return list
end

return M
