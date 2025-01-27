-- 平水韻(106)と廣韻(206)の対応 from 唐詩概説
-- かな from 新修平仄字典

---韻目
---@class YunMu
---@field name string 韻目
---@field guangyun string[] 廣韻の対応する韻目
---@field kana string かな
---@field zhuyin string 注音
local YunMu = {}

--- 平、上、去、入
---@type [YunMu?, YunMu?, YunMu?, YunMu?][]
local M = {
  {
    { name = "東", kana = "ou", zhuyin = "ㄨㄥ", guangyun = { "東" } }, -- とう
    { name = "董", kana = "ou", zhuyin = "ㄨㄥ", guangyun = { "董" } }, -- とう
    { name = "送", kana = "ou", zhuyin = "ㄨㄥ", guangyun = { "送" } }, -- そう
    { name = "屋", kana = "ok", zhuyin = "ㄨ", guangyun = { "屋" } }, -- おく
  },
  {
    { name = "冬", kana = "ou", zhuyin = "ㄨㄥ", guangyun = { "冬", "鍾" } }, -- とう
    { name = "腫", kana = "ou", zhuyin = "ㄨㄥ", guangyun = { "腫" } }, -- しょう
    { name = "宋", kana = "ou", zhuyin = "ㄨㄥ", guangyun = { "宋", "用" } }, -- そう
    { name = "沃", kana = "ok", zhuyin = "ㄨ", guangyun = { "沃", "燭" } }, -- よく
  },
  {
    { name = "江", kana = "au", zhuyin = "ㄧㄤ", guangyun = { "江" } }, -- かう
    { name = "講", kana = "au", zhuyin = "ㄧㄤ", guangyun = { "講" } }, -- かう
    { name = "絳", kana = "au", zhuyin = "ㄧㄤ", guangyun = { "絳" } }, -- かう
    { name = "覚", kana = "ak", zhuyin = "ㄝ", guangyun = { "覚" } }, -- かく
  },
  {
    { name = "支", kana = "i", zhuyin = "ㄭ", guangyun = { "支", "脂", "之" } }, -- し
    { name = "紙", kana = "i", zhuyin = "ㄭ", guangyun = { "紙", "旨", "止" } }, -- し
    { name = "寘", kana = "i", zhuyin = "ㄭ", guangyun = { "寘", "至", "志" } }, -- し
    nil,
  },
  {
    { name = "微", kana = "i", zhuyin = "ㄨㄟ", guangyun = { "微" } }, -- び
    { name = "尾", kana = "i", zhuyin = "ㄨㄟ", guangyun = { "尾" } }, -- び
    { name = "未", kana = "i", zhuyin = "ㄨㄟ", guangyun = { "未" } }, -- み
    nil,
  },
  {
    { name = "魚", kana = "o", zhuyin = "ㄩ", guangyun = { "魚" } }, -- ぎょ
    { name = "語", kana = "o", zhuyin = "ㄩ", guangyun = { "語" } }, -- ご
    { name = "御", kana = "o", zhuyin = "ㄩ", guangyun = { "御" } }, -- ご
    nil,
  },
  {
    { name = "虞", kana = "u", zhuyin = "ㄩ", guangyun = { "虞", "模" } }, -- ぐ
    { name = "麌", kana = "u", zhuyin = "ㄩ", guangyun = { "麌", "姥" } }, -- ぐ
    { name = "遇", kana = "u", zhuyin = "ㄩ", guangyun = { "遇", "暮" } }, -- ぐ
    nil,
  },
  {
    { name = "斉", kana = "ei", zhuyin = "ㄧ", guangyun = { "斉" } }, -- せい
    { name = "薺", kana = "ei", zhuyin = "ㄧ", guangyun = { "薺" } }, -- せい
    { name = "霽", kana = "ei", zhuyin = "ㄧ", guangyun = { "霽", "祭" } }, -- せい
    nil,
  },
  {
    nil,
    nil,
    { name = "泰", kana = "ai", zhuyin = "ㄞ", guangyun = {} }, -- たい
    nil,
  },
  {
    { name = "佳", kana = "ai", zhuyin = "", guangyun = { "佳", "皆" } }, -- かい
    { name = "蟹", kana = "ai", zhuyin = "", guangyun = { "蟹", "駭" } }, -- かい
    { name = "卦", kana = "ai", zhuyin = "", guangyun = { "卦", "怪", "夬" } }, -- くわい
    nil,
  },
  {
    { name = "灰", kana = "ai", zhuyin = "ㄨㄟ", guangyun = { "灰", "咍" } }, -- はい
    { name = "賄", kana = "ai", zhuyin = "ㄨㄟ", guangyun = { "賄", "海" } }, -- わい
    { name = "隊", kana = "ai", zhuyin = "ㄨㄟ", guangyun = { "隊", "代", "廃" } }, -- たい
    nil,
  },
  {
    { name = "真", kana = "in", zhuyin = "ㄭㄣ", guangyun = { "真", "諄", "臻" } }, -- しん
    { name = "軫", kana = "in", zhuyin = "ㄭㄣ", guangyun = { "軫", "準" } }, -- しん
    { name = "震", kana = "in", zhuyin = "ㄭㄣ", guangyun = { "震", "稕" } }, -- しん
    { name = "質", kana = "it", zhuyin = "ㄭ", guangyun = { "質", "術", "櫛" } }, -- しつ
  },
  {
    { name = "文", kana = "un", zhuyin = "ㄨㄣ", guangyun = { "文", "欣" } }, -- ぶん
    { name = "吻", kana = "un", zhuyin = "ㄨㄣ", guangyun = { "吻" } }, -- ぶん
    { name = "問", kana = "un", zhuyin = "ㄨㄣ", guangyun = { "問" } }, -- ぶん
    { name = "物", kana = "ut", zhuyin = "ㄨ", guangyun = { "物" } }, -- ぶつ
  },
  {
    { name = "元", kana = "en", zhuyin = "ㄩㄢ", guangyun = { "元", "魂", "痕" } }, -- げん
    { name = "阮", kana = "en", zhuyin = "ㄩㄢ", guangyun = { "阮" } },
    { name = "願", kana = "en", zhuyin = "ㄩㄢ", guangyun = { "願" } },
    { name = "月", kana = "et", zhuyin = "ㄩㄝ", guangyun = { "月" } },
  },
  {
    { name = "寒", kana = "an", zhuyin = "ㄢ", guangyun = { "寒", "桓" } }, -- くわん
    { name = "旱", kana = "an", zhuyin = "ㄢ", guangyun = { "旱" } },
    { name = "翰", kana = "an", zhuyin = "ㄢ", guangyun = { "翰" } },
    { name = "曷", kana = "at", zhuyin = "ㄜ", guangyun = { "曷" } },
  },
  {
    { name = "刪", kana = "an", zhuyin = "ㄢ", guangyun = { "刪", "山" } }, -- さん
    { name = "潸", kana = "an", zhuyin = "ㄢ", guangyun = { "潸" } },
    { name = "諫", kana = "an", zhuyin = "ㄢ", guangyun = { "諫" } },
    { name = "黠", kana = "at", zhuyin = "ㄧㄚ", guangyun = { "黠" } },
  },
  {
    { name = "先", kana = "en", zhuyin = "ㄧㄢ", guangyun = { "先" } },
    { name = "銑", kana = "en", zhuyin = "ㄧㄢ", guangyun = { "銑" } },
    { name = "霰", kana = "en", zhuyin = "ㄧㄢ", guangyun = { "霰" } },
    { name = "屑", kana = "et", zhuyin = "ㄧㄝ", guangyun = { "屑" } },
  },
  {
    { name = "蕭", kana = "eu", zhuyin = "ㄧㄠ", guangyun = { "蕭" } },
    { name = "篠", kana = "eu", zhuyin = "ㄧㄠ", guangyun = { "篠" } },
    { name = "嘯", kana = "eu", zhuyin = "ㄧㄠ", guangyun = { "嘯" } },
    nil,
  },
  {
    { name = "肴", kana = "au", zhuyin = "ㄧㄠ", guangyun = { "肴" } },
    { name = "巧", kana = "au", zhuyin = "ㄧㄠ", guangyun = { "巧" } },
    { name = "效", kana = "au", zhuyin = "ㄧㄠ", guangyun = { "效" } },
    nil,
  },
  {
    { name = "豪", kana = "au", zhuyin = "ㄠ", guangyun = { "豪" } },
    { name = "晧", kana = "au", zhuyin = "ㄠ", guangyun = { "晧" } },
    { name = "号", kana = "au", zhuyin = "ㄠ", guangyun = { "号" } },
    nil,
  },
  {
    { name = "歌", kana = "a", zhuyin = "ㄜ", guangyun = { "歌" } },
    { name = "哿", kana = "a", zhuyin = "ㄜ", guangyun = { "哿" } },
    { name = "箇", kana = "a", zhuyin = "ㄜ", guangyun = { "箇" } },
    nil,
  },
  {
    { name = "麻", kana = "a", zhuyin = "ㄚ", guangyun = { "麻" } },
    { name = "馬", kana = "a", zhuyin = "ㄚ", guangyun = { "馬" } },
    { name = "禡", kana = "a", zhuyin = "ㄚ", guangyun = { "禡" } },
    nil,
  },
  {
    { name = "陽", kana = "au", zhuyin = "ㄧㄤ", guangyun = { "陽" } },
    { name = "養", kana = "au", zhuyin = "ㄧㄤ", guangyun = { "養" } },
    { name = "漾", kana = "au", zhuyin = "ㄧㄤ", guangyun = { "漾" } },
    { name = "藥", kana = "ak", zhuyin = "ㄧㄠ", guangyun = { "薬" } },
  },
  {
    { name = "庚", kana = "au", zhuyin = "ㄠ", guangyun = { "庚" } },
    { name = "梗", kana = "au", zhuyin = "ㄠ", guangyun = { "梗" } },
    { name = "敬", kana = "au", zhuyin = "ㄠ", guangyun = { "敬" } },
    { name = "陌", kana = "ak", zhuyin = "ㄜ", guangyun = { "陌" } },
  },
  {
    { name = "青", kana = "ei", zhuyin = "ㄧㄥ", guangyun = { "青" } },
    { name = "迥", kana = "ei", zhuyin = "ㄧㄥ", guangyun = { "迥" } },
    { name = "径", kana = "ei", zhuyin = "ㄧㄥ", guangyun = { "径" } },
    { name = "錫", kana = "ek", zhuyin = "ㄧ", guangyun = { "錫" } },
  },
  {
    { name = "蒸", kana = "ou", zhuyin = "ㄭㄥ", guangyun = { "蒸" } },
    nil,
    nil,
    { name = "職", kana = "ok", zhuyin = "ㄭ", guangyun = { "職" } },
  },
  {
    { name = "尤", kana = "iu", zhuyin = "ㄧㄡ", guangyun = { "尤" } },
    { name = "有", kana = "iu", zhuyin = "ㄧㄡ", guangyun = { "有" } },
    { name = "宥", kana = "iu", zhuyin = "ㄧㄡ", guangyun = { "宥" } },
    nil,
  },
  {
    { name = "侵", kana = "im", zhuyin = "ㄧㄣ", guangyun = { "侵" } },
    { name = "寢", kana = "im", zhuyin = "ㄧㄣ", guangyun = { "寝" } },
    { name = "沁", kana = "im", zhuyin = "ㄧㄣ", guangyun = { "沁" } },
    { name = "緝", kana = "ip", zhuyin = "ㄧ", guangyun = { "緝" } },
  },
  {
    { name = "覃", kana = "om", zhuyin = "ㄢ", guangyun = { "覃" } },
    { name = "感", kana = "om", zhuyin = "ㄢ", guangyun = { "感" } },
    { name = "勘", kana = "om", zhuyin = "ㄢ", guangyun = { "勘" } },
    { name = "合", kana = "op", zhuyin = "ㄜ", guangyun = { "合" } },
  },
  {
    { name = "鹽", kana = "em", zhuyin = "ㄧㄢ", guangyun = { "塩" } },
    { name = "琰", kana = "em", zhuyin = "ㄧㄢ", guangyun = { "琰" } },
    { name = "艶", kana = "em", zhuyin = "ㄧㄢ", guangyun = { "艶" } },
    { name = "葉", kana = "ep", zhuyin = "ㄧㄝ", guangyun = { "葉" } },
  },
  {
    { name = "咸", kana = "em", zhuyin = "ㄧㄢ", guangyun = { "咸" } },
    { name = "豏", kana = "em", zhuyin = "ㄧㄢ", guangyun = { "豏" } },
    { name = "陥", kana = "em", zhuyin = "ㄧㄢ", guangyun = { "陥" } },
    { name = "洽", kana = "ep", zhuyin = "ㄧㄚ", guangyun = { "洽" } },
  },
}

return M
