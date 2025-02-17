---廣韻
-- [有女同車《〈廣韻〉全字表》原表](https://github.com/syimyuzya/guangyun0704)
-- [音韻学入門 －中古音篇－](https://kodaimoji.chowder.jp/chinese-phonology/pdf/oningaku.pdf)
-- https://ytenx.org/kyonh/
local util = require "neoskk.util"
local yun = require "neoskk.yun"
local XiaoYun = require "neoskk.XiaoYun"
local utf8 = require "neoskk.utf8"

---@alias ShengNiuType "重唇音"|"軽唇音"|"舌頭音"|"舌上音"|"牙音"|"歯頭音"|"正歯音莊組"|"正歯音章組"|"喉音"|"半舌音"|"半歯音"
local type1 = {
  ["重唇音"] = "唇",
  ["軽唇音"] = "唇",
  ["舌頭音"] = "舌",
  ["舌上音"] = "舌",
  ["牙音"] = "牙",
  ["歯頭音"] = "歯",
  ["正歯音"] = "歯",
  ["正歯音莊組"] = "歯",
  ["正歯音章組"] = "歯",
  ["喉音"] = "喉",
  ["半舌音"] = "半",
  ["半歯音"] = "半",
}

---@alias ShengNiuSeidaku "清"|"次清"|"濁"|"清濁"
local seidaku1 = {
  ["清"] = "清",
  ["次清"] = "次",
  ["濁"] = "濁",
  ["清濁"] = "両",
}

---聲紐 字母
---@class ShengNiu
---@field name string
---@field names string[]
---@field type ShengNiuType
---@field seidaku ShengNiuSeidaku
---@field xiaoyun_list string[] 小韻のリスト
local ShengNiu = {}
ShengNiu.__index = ShengNiu

---@param name string
---@param t ShengNiuType
---@param seidaku ShengNiuSeidaku
---@param line integer? 一等四等 or 二等三等 or nil
---@param chars string?
---@return ShengNiu
function ShengNiu.new(name, t, seidaku, line, chars)
  local self = setmetatable({
    name = name,
    names = {},
    type = t,
    seidaku = seidaku,
    xiaoyun_list = {},
  }, ShengNiu)
  if chars then
    for _, ch in utf8.codes(chars) do
      table.insert(self.names, ch)
    end
  end
  return self
end

---@return string
function ShengNiu:__tostring()
  return ("%s#%d %s"):format(self.names[1], #self.xiaoyun_list, util.join(util.take(self.xiaoyun_list, 10)))
  -- return ("%s %s%s (%s)"):format(self.name, self.type, self.seidaku, self.roma)
end

---@param s string
---@return boolean
function ShengNiu:match(s)
  if s == self.name then
    return true
  end
  for _, name in ipairs(self.names) do
    if name == s then
      return true
    end
  end
  return false
end

---廣韻
---@class GuangYun
---@field list XiaoYun[] 小韻リスト
---@field sheng_list ShengNiu[]
local GuangYun = {}
GuangYun.__index = GuangYun

---@return GuangYun
function GuangYun.new()
  local self = setmetatable({
    list = {},
    sheng_list = {
      --唇 p
      ShengNiu.new(
        "幫",
        "重唇音",
        "清",
        nil,
        "方府博彼甫邊布必北卑伯筆巴并補陂分兵晡畀封鄙百"
      ),
      ShengNiu.new("滂", "重唇音", "次清", nil, "方敷匹芳普撫孚滂披妃丕峯譬拂"),
      ShengNiu.new(
        "並",
        "重唇音",
        "濁",
        nil,
        "房薄符防部步扶附蒲縛皮白便浮裴傍毗平捕馮婢父弼"
      ),
      ShengNiu.new("明", "重唇音", "清濁", nil, "莫靡武無彌母亡文綿眉模謨明摸巫美望矛慕"),
      ShengNiu.new("非", "軽唇音", "次清", 3),
      ShengNiu.new("敷", "軽唇音", "濁", 3),
      ShengNiu.new("奉", "軽唇音", "清", 3),
      ShengNiu.new("微", "軽唇音", "清濁", 3),
      --舌 t
      ShengNiu.new("端", "舌頭音", "清", 1, "德都丁當多得冬"),
      ShengNiu.new("透", "舌頭音", "次清", 1, "他土吐託天湯通台"),
      ShengNiu.new("定", "舌頭音", "濁", 1, "徒同杜度墜特堂唐田陀"),
      ShengNiu.new("泥", "舌頭音", "清濁", 1, "奴乃諾那内"),
      ShengNiu.new("知", "舌上音", "清", 2, "陟都竹丁卓張中知豬珍追猪徵"),
      ShengNiu.new("徹", "舌上音", "次清", 2, "敕他丑褚楮癡抽恥"),
      ShengNiu.new("澄", "舌上音", "濁", 2, "徒直宅柱池丈持除治馳遟佇場"),
      ShengNiu.new("孃", "舌上音", "清濁", 2, "奴女乃妳諾尼拏穠"),
      --歯 ts
      ShengNiu.new("精", "歯頭音", "清", 1, "子作即姊遵醉則祖臧將借兹𩛠資姉"),
      ShengNiu.new("清", "歯頭音", "次清", 1, "倉七此取蒼醋千雌采親麁靑麤遷"),
      ShengNiu.new("從", "歯頭音", "濁", 1, "徂藏疾昨匠在才自慈秦漸情前"),
      ShengNiu.new("心", "歯頭音", "清", 1, "息蘇私相素先思須寫桑速斯胥悉雖司辛"),
      ShengNiu.new("邪", "歯頭音", "濁", 1, "祥旬似詳夕徐隨辝辭寺"),
      ShengNiu.new("莊", "正歯音莊組", "清", 1, "子側莊阻仄爭鄒簪"),
      ShengNiu.new("初", "正歯音莊組", "次清", 1, "楚叉測初創瘡芻廁"),
      ShengNiu.new("崇", "正歯音莊組", "濁", 1, "鋤士仕崇鉏助牀鶵雛犲崱查査"),
      ShengNiu.new("生", "正歯音莊組", "清", 1, "所山疏數色史踈砂沙生"),
      ShengNiu.new("俟", "正歯音莊組", "濁", 1, "俟牀"),
      ShengNiu.new("章", "正歯音章組", "清", 1, "職章旨止諸正煑之占支脂征"),
      ShengNiu.new("昌", "正歯音章組", "次清", 1, "昌尺叱處叉赤充姝"),
      ShengNiu.new("常", "正歯音章組", "濁", 1, "蜀是視市署成植常氏時承臣殖甞寔殊十"),
      ShengNiu.new("書", "正歯音章組", "濁", 1, "書式傷失識施詩舒賞矢釋商試始"),
      ShengNiu.new("船", "正歯音章組", "次清", 1, "食神實乗"),
      --牙 k
      ShengNiu.new("見", "牙音", "清", nil, "居古九舉公過俱佳乖姑各兼詭規几吉紀格"),
      ShengNiu.new(
        "溪",
        "牙音",
        "次清",
        nil,
        "去苦曲丘豈口可起乞客綺恪康墟袪羌驅弃空牽枯欽謙區窺卿詰傾楷"
      ),
      ShengNiu.new("羣", "牙音", "濁", nil, "渠巨強其跪求曁狂奇具臼衢"),
      ShengNiu.new("疑", "牙音", "清濁", nil, "五魚牛語遇擬愚俄虞疑研宜危吾玉"),
      --喉 h
      ShengNiu.new("曉", "喉音", "清", nil, "呼許香喜朽況荒火虚虎興花休况馨海羲呵"),
      ShengNiu.new("匣", "喉音", "清", nil, "戸下胡獲侯懷何乎黃"),
      ShengNiu.new("影", "喉音", "濁", nil, "烏於握央憶哀乙謁一委挹安紆烟衣依鷖伊憂愛"),
      ShengNiu.new("云", "喉音", "清濁", nil, "羽下薳洧雨爲王有于永韋榮云雲筠"),
      ShengNiu.new("以", "喉音", "清濁", nil, "以餘弋悅與羊翼于余移夷營"),
      -- 半
      ShengNiu.new("來", "半舌音", "清濁", nil, "力盧吕里落郎賴魯縷勒良來洛連練離林"),
      ShengNiu.new("日", "半歯音", "清濁", nil, "如而汝人儒耳兒仍"),
    },
  }, GuangYun)
  return self
end

function GuangYun.resetmetatable(self)
  setmetatable(self, GuangYun)
  for _, sheng in ipairs(self.sheng_list) do
    setmetatable(sheng, ShengNiu)
  end
end

---@param data string Kuankhiunn0704-semicolon.txt
function GuangYun:load(data)
  for line in string.gmatch(data, "([^\n]+)\n") do
    local xiaoyun = XiaoYun.parse(line)
    if xiaoyun then
      table.insert(self.list, xiaoyun)
      local sheng = self:get_or_create_shengniu(xiaoyun.shengniu)
      if sheng then
        table.insert(sheng.xiaoyun_list, xiaoyun.chars[1])
      end
    end
  end
end

---@param ch string
---@return ShengNiu
function GuangYun:get_or_create_shengniu(ch)
  for _, sheng in ipairs(self.sheng_list) do
    if sheng:match(ch) then
      return sheng
    end
  end

  -- local sheng = ShengNiu.new({ ch }, "?", "?", "?")
  -- table.insert(self.sheng_list, sheng)
  -- return sheng
end

---@param char string
---@return XiaoYun?
function GuangYun:xiaoyun_from_char(char)
  for _, x in ipairs(self.list) do
    if x.chars[1] == char then
      -- find first
      return x
    end
  end
  for _, x in ipairs(self.list) do
    for _, ch in ipairs(x.chars) do
      if ch == char then
        return x
      end
    end
  end
end

---@param fanqie string
---@return XiaoYun?
function GuangYun:xiaoyun_from_fanqie(fanqie)
  for _, x in ipairs(self.list) do
    if x.fanqie == fanqie then
      return x
    end
    --TODO: 反切系聯法
    -- if x:match_fanqie(fantie) then
    --   return x
    -- end
  end
end

---@param callback fun(x:XiaoYun):boolean
---@return XiaoYun?
function GuangYun:find_xiaoyun(callback)
  for _, x in ipairs(self.list) do
    if callback(x) then
      return x
    end
  end
  return nil
end

---@param name string 韻目
---@return XiaoYun[]
function GuangYun:make_xiaoyun_list(name)
  ---@type (XiaoYun?)[]
  local list = {}
  for i, sheng in ipairs(self.sheng_list) do
    local xiaoyun = self:find_xiaoyun(function(x)
      return x.name == name --[[and x.deng == deng]]
        and sheng:match(x.shengniu)
    end)
    if xiaoyun then
      table.insert(list, xiaoyun)
    else
      print(name, sheng.name, "not found")
      table.insert(list, false)
    end
  end
  return list
end

---@param xiaoyuns XiaoYun[]
---@return string[]?, XiaoYun?
function GuangYun:hover(xiaoyuns)
  for _, xiaoyun in ipairs(xiaoyuns) do
    local lines = self:_hover(xiaoyun)
    if lines then
      return lines, xiaoyun
    end
  end
end

---@param xiaoyun XiaoYun
---@return string[]?
function GuangYun:_hover(xiaoyun)
  local yunshe, yunmu = yun.get_she(xiaoyun.name)
  if not yunshe or not yunmu then
    return
  end
  local shengniu = self:get_or_create_shengniu(xiaoyun.shengniu)
  if not shengniu then
    return
  end

  -- 韻
  local lines = {}
  table.insert(lines, ("## %s攝"):format(yunshe.name))
  table.insert(
    lines,
    ("%s %s %s %s"):format(
      "平" == xiaoyun.diao and "`平`" or "平",
      "上" == xiaoyun.diao and "`上`" or "上",
      "去" == xiaoyun.diao and "`去`" or "去",
      "入" == xiaoyun.diao and "`入`" or "入"
    )
  )
  for _, group in ipairs(yunshe.list) do
    --平水韻 delimiter
    table.insert(lines, "-----------")

    local a = group[1]
    local b = group[2]
    local c = group[3]
    local d = group[4]

    local i = 1
    while
      (a and i <= #a.guangyun)
      or (b and i <= #b.guangyun)
      or (c and i <= #c.guangyun)
      or (d and i <= #d.guangyun)
    do
      local hei = a and (a.guangyun[i] or "〇") or "〇"
      if hei == xiaoyun.name then
        hei = "`" .. hei .. "`"
      end
      local jou = b and (b.guangyun[i] or "〇") or "〇"
      if jou == xiaoyun.name then
        jou = "`" .. jou .. "`"
      end
      local kyo = c and (c.guangyun[i] or "〇") or "〇"
      if kyo == xiaoyun.name then
        kyo = "`" .. kyo .. "`"
      end
      local nyu = d and (d.guangyun[i] or "〇") or "〇"
      if nyu == xiaoyun.name then
        nyu = "`" .. nyu .. "`"
      end

      local a_xiaoyun = false
      if a then
        a_xiaoyun = self:xiaoyun_from_char(a.guangyun[1])
      end
      if a_xiaoyun then
        table.insert(lines, ("%s %s %s %s %s口%s等"):format(hei, jou, kyo, nyu, a_xiaoyun.huo, a_xiaoyun.deng))
      else
        table.insert(lines, ("%s %s %s %s"):format(hei, jou, kyo, nyu))
      end
      i = i + 1
    end
  end
  table.insert(lines, "")

  -- 聲紐
  table.insert(lines, ("## 聲紐: %s, %s%s"):format(xiaoyun.shengniu, shengniu.type, shengniu.seidaku))
  local yuns = self:make_xiaoyun_list(xiaoyun.name)
  local line_type = "五音| "
  local line_seidaku = "清濁| "
  local shengniu_name = "聲紐| "
  local xiaoyun_name = "小韻| "
  local found = false
  for i, s in ipairs(self.sheng_list) do
    local t = type1[s.type]
    if not t then
      print(s.type)
      t = "？"
    end
    line_type = line_type .. t
    line_seidaku = line_seidaku .. seidaku1[s.seidaku]

    local y = yuns[i]
    if y then
      shengniu_name = shengniu_name .. s.name
      if y == xiaoyun then
        found = true
        xiaoyun_name = xiaoyun_name .. "`" .. y.chars[1] .. "`"
      else
        xiaoyun_name = xiaoyun_name .. y.chars[1]
      end
    else
      shengniu_name = shengniu_name .. "〇"
      xiaoyun_name = xiaoyun_name .. "〇"
    end
  end
  table.insert(lines, line_type)
  table.insert(lines, line_seidaku)
  table.insert(lines, shengniu_name)
  table.insert(lines, "----")
  table.insert(lines, xiaoyun_name)
  table.insert(lines, "")

  if found then
    return lines
  end
end

return GuangYun
