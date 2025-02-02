---廣韻
-- [有女同車《〈廣韻〉全字表》原表](https://github.com/syimyuzya/guangyun0704)
-- [音韻学入門 －中古音篇－](https://kodaimoji.chowder.jp/chinese-phonology/pdf/oningaku.pdf)
local util = require "neoskk.util"
local utf8 = require "neoskk.utf8"
local yun = require "neoskk.yun"

---小韻
---@class XiaoYun
---@field no integer 小韻番号 1-3874 https://gijodai.jp/library/file/kiyo2006/SUMIYA.pdf
---@field fanqie string
---@field name string
---@field parent string
---@field roma string
---@field diao string
---@field chars string[]
---@field shengniu string 聲紐
---@field huo string 開合呼
---@field deng string 等
local XiaoYun = {}
XiaoYun.__index = XiaoYun

-- 字段(fields)由「;」分隔，内容由左至右依次爲
-- 1、舊版(unicode3.1字符集第一版)小韻總序號。缺錄:丑戾切、no=2381，烏懈切、no=2455，他德切、no=3728，盧合、no=3784四小韻。
-- 2、刊正小韻總序號
-- 3、反切
-- 4、小韻内辭目（headwords）
-- 5、小韻所收辭目數
-- 6、校驗表記
-- 7、韻目。阿拉伯數碼「X.XX」，小數點前一位爲卷號，小數點後兩位爲韻目。如「4.11暮」意爲「第四卷去聲、十一暮韻」。
-- 8、小韻在韻中的序號。如「『德紅切』『東』爲『東』韻第一小韻，『薄紅切』『蓬』爲『東』韻第三十一小韻。」古書向無頁碼，兼且版本紛紜卷帙雜沓難於取捨，故此僅錄標目序號不記頁碼。
-- 9、聲紐
-- 10、呼（開合口）
-- 11、等
-- 12、韻部（四聲劃一）
-- 13、聲調
-- 14、Polyhedron擬羅馬字
-- 15、有女同車擬羅馬字
-- 16、舊版備註
-- 17、本次復校備註
-- 18、特殊小韻韻目歸屬說明
-- 19、見於廣韻辭條中的辭目重文、取自集韻的增補和異體字、等價異形字、備考新字等
-- 20、unicode3.1未收字的準IDS（Ideographic Desciption Characters）描述：H=⿰、Z=⿱、P=⿸、E=⿳、V=某字unicode缺載之變體
-- 1;1;德紅;東菄鶇䍶𠍀倲𩜍𢘐涷蝀凍鯟𢔅崠埬𧓕䰤;17;.;1.01東;1;端;開;一;東;平;tung;tung;;;;;
-- 3674;3676;都歷;的適嫡甋靮鏑馰滴肑弔芍蹢䶂玓樀𪄱𦉹𥕐𥐝扚𣂉啇魡㣿𨑩杓;26;.;5.23錫;5;端;開;四;青;入;tek;tek;;;;;
---@param line string
---@return XiaoYun?
function XiaoYun.parse(line)
  local cols = util.splited(line, ";")
  if #cols <= 5 then
    return
  end

  local no = tonumber(cols[2])
  if no > 3874 then
    -- 3870;3874;丑法;𦑣;1;.;5.34乏;6;徹;合;三;凡;入;thryap;thvap;;;;;

    -- https://gijodai.jp/library/file/kiyo2006/SUMIYA.pdf
    -- 3874で終わり
    -- 4000番台は追加データ
    return
  end

  local name = cols[7]:match "^%d+%.%d+(.*)$"
  local shengniu = cols[9]
  for _, code in utf8.codes(shengniu) do
    shengniu = code
    break
  end

  local xiaoyun = setmetatable({
    no = no,
    fanqie = cols[3],
    name = name,
    shengniu = shengniu,
    huo = cols[10],
    deng = cols[11],
    parent = cols[12],
    diao = cols[13],
    roma = cols[14],
    chars = {},
  }, XiaoYun)
  for _, ch in utf8.codes(cols[4]) do
    table.insert(xiaoyun.chars, ch)
  end
  assert(#xiaoyun.chars, cols[5])
  return xiaoyun
end

function XiaoYun:__tostring()
  return ("%d 小韻:%s, %s切%s聲, %s呼, %s等 => %s"):format(
    self.no,
    self.name,
    self.fanqie,
    self.diao,
    self.huo,
    self.deng,
    util.join(self.chars)
  )
end

---@alias ShengNiuType "重唇音"|"軽唇音"|"舌頭音"|"舌上音"|"牙音"|"歯頭音"|"正歯音"|"喉音"|"半舌音"|"半歯音"
local type1 = {
  ["重唇音"] = "唇",
  ["軽唇音"] = "唇",
  ["舌頭音"] = "舌",
  ["舌上音"] = "舌",
  ["牙音"] = "牙",
  ["歯頭音"] = "歯",
  ["正歯音"] = "歯",
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
---@field names string[] 字
---@field type ShengNiuType
---@field seidaku ShengNiuSeidaku
---@field roma string alphabet
---@field xiaoyun_list string[] 小韻のリスト
local ShengNiu = {}
ShengNiu.__index = ShengNiu

---@param names string[]
---@param t ShengNiuType
---@param seidaku ShengNiuSeidaku
---@param line integer? 一等四等 or 二等三等 or nil
---@param roma string
---@return ShengNiu
function ShengNiu.new(names, t, seidaku, line, roma)
  local self = setmetatable({
    names = names,
    type = t,
    seidaku = seidaku,
    roma = roma,
    xiaoyun_list = {},
  }, ShengNiu)
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
      ShengNiu.new({ "幫" }, "重唇音", "清", nil, "p"),
      ShengNiu.new({ "滂" }, "重唇音", "次清", nil, "ph"),
      ShengNiu.new({ "並" }, "重唇音", "濁", nil, "b"),
      ShengNiu.new({ "明" }, "重唇音", "清濁", nil, "m"),
      ShengNiu.new({ "非" }, "軽唇音", "次清", 3, "f"),
      ShengNiu.new({ "敷" }, "軽唇音", "濁", 3, "fh"),
      ShengNiu.new({ "奉" }, "軽唇音", "清", 3, "v"),
      ShengNiu.new({ "微" }, "軽唇音", "清濁", 3, ""),
      --舌 t
      ShengNiu.new({ "端" }, "舌頭音", "清", 1, "t"),
      ShengNiu.new({ "透" }, "舌頭音", "次清", 1, "th"),
      ShengNiu.new({ "定" }, "舌頭音", "濁", 1, "d"),
      ShengNiu.new({ "泥" }, "舌頭音", "清濁", 1, "n"),
      ShengNiu.new({ "知" }, "舌上音", "清", 2, "tr"),
      ShengNiu.new({ "徹" }, "舌上音", "次清", 2, "thr"),
      ShengNiu.new({ "澄" }, "舌上音", "濁", 2, "dr"),
      ShengNiu.new({ "娘" }, "舌上音", "清濁", 2, "nr"),
      --牙 k
      ShengNiu.new({ "見" }, "牙音", "清", nil, "k"),
      ShengNiu.new({ "溪" }, "牙音", "次清", nil, "kh"),
      ShengNiu.new({ "群" }, "牙音", "濁", nil, "g"),
      ShengNiu.new({ "疑" }, "牙音", "清濁", nil, "ng"),
      --歯 ts
      ShengNiu.new({ "精", "莊" }, "歯頭音", "清", 1, "c"),
      ShengNiu.new({ "清", "初" }, "歯頭音", "次清", 1, "ch"),
      ShengNiu.new({ "從" }, "歯頭音", "濁", 1, "z"),
      ShengNiu.new({ "心" }, "歯頭音", "清", 1, "s"),
      ShengNiu.new({ "邪" }, "歯頭音", "濁", 1, "zs"),
      ShengNiu.new({ "照", "章" }, "正歯音", "清", 2, "cr"),
      ShengNiu.new({ "穿", "昌" }, "正歯音", "次清", 2, "sj"),
      ShengNiu.new({ "牀", "崇" }, "正歯音", "濁", 2, "zr"),
      ShengNiu.new({ "審", "書" }, "正歯音", "清", 2, "sr"),
      ShengNiu.new({ "禅" }, "正歯音", "濁", 2, "zsr"),
      --喉 h
      ShengNiu.new({ "影" }, "喉音", "清", nil, ""),
      ShengNiu.new({ "曉" }, "喉音", "清", nil, ""),
      ShengNiu.new({ "匣", "俟" }, "喉音", "濁", nil, ""),
      ShengNiu.new({ "喩", "以" }, "喉音", "清濁", nil, ""),
      -- 半
      ShengNiu.new({ "來" }, "半舌音", "清濁", nil, "l"),
      ShengNiu.new({ "日" }, "半歯音", "清濁", nil, "nj"),
    },
  }, GuangYun)
  return self
end

---@param data string Kuankhiunn0704-semicolon.txt
function GuangYun:load(data)
  for line in string.gmatch(data, "([^\n]+)\n") do
    local xiaoyun = XiaoYun.parse(line)
    if xiaoyun then
      table.insert(self.list, xiaoyun)
      local sheng = self:get_or_create_shengniu(xiaoyun.shengniu)
      table.insert(sheng.xiaoyun_list, xiaoyun.chars[1])
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

  local sheng = ShengNiu.new({ ch }, "?", "?", "?")
  table.insert(self.sheng_list, sheng)
  return sheng
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

---@param name string
---@param deng string 等
---@return XiaoYun[]
function GuangYun:make_xiaoyun_list(name, deng)
  ---@type (XiaoYun?)[]
  local list = {}
  for i = 1, 36 do
    local sheng = self.sheng_list[i]
    local xiaoyun = nil
    if sheng then
      xiaoyun = self:find_xiaoyun(function(x)
        return x.name == name and x.deng == deng and (sheng and sheng:match(x.shengniu))
      end)
    end
    if xiaoyun then
      table.insert(list, xiaoyun)
    else
      table.insert(list, false)
    end
  end
  return list
end

---@param ch string
---@param xiaoyun XiaoYun
---@return string[]
function GuangYun:hover(ch, xiaoyun)
  local lines = {}
  table.insert(
    lines,
    ("# 廣韻 %s, 小韻 %s, %s切%s声 %s口%s等 %s"):format(
      xiaoyun.name,
      xiaoyun.chars[1],
      xiaoyun.fanqie,
      xiaoyun.diao,
      xiaoyun.huo,
      xiaoyun.deng,
      xiaoyun.roma
    )
  )
  table.insert(lines, "")

  -- 韻
  local yunshe, yunmu = yun.get_she(xiaoyun.name)

  if yunshe and yunmu then
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
        table.insert(lines, ("%s %s %s %s"):format(hei, jou, kyo, nyu))
        i = i + 1
      end
    end
    table.insert(lines, "")
  end

  -- 聲紐
  local shengniu = self:get_or_create_shengniu(xiaoyun.shengniu)
  table.insert(
    lines,
    ("## 聲紐: %s, %s%s (%s)"):format(xiaoyun.shengniu, shengniu.type, shengniu.seidaku, shengniu.roma)
  )
  table.insert(lines, "")
  local yuns = self:make_xiaoyun_list(xiaoyun.name, xiaoyun.deng)
  local line_type = ""
  local line_seidaku = ""
  local line = ""
  local line2 = ""
  for i = 1, 36 do
    local s = self.sheng_list[i]
    line_type = line_type .. type1[s.type]
    line_seidaku = line_seidaku .. seidaku1[s.seidaku]
    line = line .. s.names[1]

    local y = yuns[i]
    if y then
      if y == xiaoyun then
        line2 = line2 .. "`" .. y.chars[1] .. "`"
      else
        line2 = line2 .. y.chars[1]
      end
    else
      line2 = line2 .. "〇"
    end
  end
  table.insert(lines, line_type)
  table.insert(lines, line_seidaku)
  table.insert(lines, line)
  table.insert(lines, "----")
  table.insert(lines, line2)
  table.insert(lines, "")

  return lines
end

return GuangYun
