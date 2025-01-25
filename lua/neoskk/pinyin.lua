local util = require "neoskk.util"
local M = {}

---@type table<string, [string, integer]>
M.to_ascii = {
  --a
  ["ā"] = { "a", 1 },
  ["á"] = { "a", 2 },
  ["ǎ"] = { "a", 3 },
  ["à"] = { "a", 4 },
  --e
  ["ē"] = { "e", 1 },
  ["é"] = { "e", 2 },
  ["ě"] = { "e", 3 },
  ["è"] = { "e", 4 },
  --i
  ["ī"] = { "i", 1 },
  ["í"] = { "i", 2 },
  ["ǐ"] = { "i", 3 },
  ["ì"] = { "i", 4 },
  --o
  ["ō"] = { "o", 1 },
  ["ó"] = { "o", 2 },
  ["ǒ"] = { "o", 3 },
  ["ò"] = { "o", 4 },
  --u
  ["ū"] = { "u", 1 },
  ["ú"] = { "u", 2 },
  ["ǔ"] = { "u", 3 },
  ["ù"] = { "u", 4 },
  --
  ["ǖ"] = { "ü", 1 },
  ["ǘ"] = { "ü", 2 },
  ["ǚ"] = { "ü", 3 },
  ["ǜ"] = { "ü", 4 },
  --
  ["ň"] = { "n", 3 },
  ["ǹ"] = { "n", 4 },
  ["ḿ"] = { "m", 2 },
}

local PINYIN = [[
      ,  ㄅ  ,  ㄆ  ,  ㄇ  , ㄈ   ,  ㄉ  ,  ㄊ  ,  ㄋ  ,  ㄌ  ,  ㄍ  ,  ㄎ  ,  ㄏ  ,  ㄐ  ,  ㄑ  ,  ㄒ  ,  ㄓ  ,   ㄔ ,  ㄕ  ,  ㄖ  ,  ㄗ  ,  ㄘ  ,  ㄙ
      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,zhi   ,chi   ,shi   ,ri    ,zi    ,ci    ,si    ,
      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,ㄓ    ,ㄔ    ,ㄕ    ,ㄖ    ,ㄗ    ,ㄘ    ,ㄙ    ,
a     ,ba    ,pa    ,ma    ,fa    ,da    ,ta    ,na    ,la    ,ga    ,ka    ,ha    ,      ,      ,      ,zha   ,cha   ,sha   ,      ,za    ,ca    ,sa    ,
ㄚ    ,ㄅㄚ  ,ㄆㄚ  ,ㄇㄚ  ,ㄈㄚ  ,ㄉㄚ  ,ㄊㄚ  ,ㄋㄚ  ,ㄌㄚ  ,ㄍㄚ  ,ㄎㄚ  ,ㄏㄚ  ,      ,      ,      ,ㄓㄚ  ,ㄔㄚ  ,ㄕㄚ  ,      ,ㄗㄚ  ,ㄘㄚ  ,ㄙㄚ  ,
o     ,bo    ,po    ,mo    ,fo    ,      ,      ,      ,lo    ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,
ㄛ    ,ㄅㄛ  ,ㄆㄛ  ,ㄇㄛ  ,ㄈㄛ  ,      ,      ,      ,ㄌㄛ  ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,
e     ,      ,      ,me    ,      ,de    ,te    ,ne    ,le    ,ge    ,ke    ,he    ,      ,      ,      ,zhe   ,che   ,she   ,re    ,ze    ,ce    ,se    ,
ㄜ    ,      ,      ,ㄇㄜ  ,      ,ㄉㄜ  ,ㄊㄜ  ,ㄋㄜ  ,ㄌㄜ  ,ㄍㄜ  ,ㄎㄜ  ,ㄏㄜ  ,      ,      ,      ,ㄓㄜ  ,ㄔㄜ  ,ㄕㄜ  ,ㄖㄜ  ,ㄗㄜ  ,ㄘㄜ  ,ㄙㄜ  ,
ai    ,bai   ,pai   ,mai   ,      ,dai   ,tai   ,nai   ,lai   ,gai   ,kai   ,hai   ,      ,      ,      ,zhai  ,chai  ,shai  ,      ,zai   ,cai   ,sai   ,
ㄞ    ,ㄅㄞ  ,ㄆㄞ  ,ㄇㄞ  ,      ,ㄉㄞ  ,ㄊㄞ  ,ㄋㄞ  ,ㄌㄞ  ,ㄍㄞ  ,ㄎㄞ  ,ㄏㄞ  ,      ,      ,      ,ㄓㄞ  ,ㄔㄞ  ,ㄕㄞ  ,      ,ㄗㄞ  ,ㄘㄞ  ,ㄙㄞ  ,
ei    ,bei   ,pei   ,mei   ,fei   ,dei   ,tei   ,nei   ,lei   ,gei   ,kei   ,hei   ,      ,      ,      ,zhei  ,      ,shei  ,      ,zei   ,      ,      ,
ㄟ    ,ㄅㄟ  ,ㄆㄟ  ,ㄇㄟ  ,ㄈㄟ  ,ㄉㄟ  ,ㄊㄟ  ,ㄋㄟ  ,ㄌㄟ  ,ㄍㄟ  ,ㄎㄟ  ,ㄏㄟ  ,      ,      ,      ,ㄓㄟ  ,      ,ㄕㄟ  ,      ,ㄗㄟ  ,      ,      ,
ao    ,bao   ,pao   ,mao   ,      ,dao   ,tao   ,nao   ,lao   ,gao   ,kao   ,hao   ,      ,      ,      ,zhao  ,chao  ,shao  ,rao   ,zao   ,cao   ,sao   ,
ㄠ    ,ㄅㄠ  ,ㄆㄠ  ,ㄇㄠ  ,      ,ㄉㄠ  ,ㄊㄠ  ,ㄋㄠ  ,ㄌㄠ  ,ㄍㄠ  ,ㄎㄠ  ,ㄏㄠ  ,      ,      ,      ,ㄓㄠ  ,ㄔㄠ  ,ㄕㄠ  ,ㄖㄠ  ,ㄗㄠ  ,ㄘㄠ  ,ㄙㄠ  ,
ou    ,      ,pou   ,mou   ,fou   ,dou   ,tou   ,nou   ,lou   ,gou   ,kou   ,hou   ,      ,      ,      ,zhou  ,chou  ,shou  ,rou   ,zou   ,cou   ,sou   ,
ㄡ    ,      ,ㄆㄡ  ,ㄇㄡ  ,ㄈㄡ  ,ㄉㄡ  ,ㄊㄡ  ,ㄋㄡ  ,ㄌㄡ  ,ㄍㄡ  ,ㄎㄡ  ,ㄏㄡ  ,      ,      ,      ,ㄓㄡ  ,ㄔㄡ  ,ㄕㄡ  ,ㄖㄡ  ,ㄗㄡ  ,ㄘㄡ  ,ㄙㄡ  ,
m     ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,hm    ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,
ㄇ    ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,ㄏㄇ  ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,
an    ,ban   ,pan   ,man   ,fan   ,dan   ,tan   ,nan   ,lan   ,gan   ,kan   ,han   ,      ,      ,      ,zhan  ,chan  ,shan  ,ran   ,zan   ,can   ,san   ,
ㄢ    ,ㄅㄢ  ,ㄆㄢ  ,ㄇㄢ  ,ㄈㄢ  ,ㄉㄢ  ,ㄊㄢ  ,ㄋㄢ  ,ㄌㄢ  ,ㄍㄢ  ,ㄎㄢ  ,ㄏㄢ  ,      ,      ,      ,ㄓㄢ  ,ㄔㄢ  ,ㄕㄢ  ,ㄖㄢ  ,ㄗㄢ  ,ㄘㄢ  ,ㄙㄢ  ,
en    ,ben   ,pen   ,men   ,fen   ,den   ,      ,nen   ,      ,gen   ,ken   ,hen   ,      ,      ,      ,zhen  ,chen  ,shen  ,ren   ,zen   ,cen   ,sen   ,
ㄣ    ,ㄅㄣ  ,ㄆㄣ  ,ㄇㄣ  ,ㄈㄣ  ,ㄉㄣ  ,      ,ㄋㄣ  ,      ,ㄍㄣ  ,ㄎㄣ  ,ㄏㄣ  ,      ,      ,      ,ㄓㄣ  ,ㄔㄣ  ,ㄕㄣ  ,ㄖㄣ  ,ㄗㄣ  ,ㄘㄣ  ,ㄙㄣ  ,
ng    ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,hng   ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,
ㄫ    ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,ㄏㄫ  ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,
ang   ,bang  ,pang  ,mang  ,fang  ,dang  ,tang  ,nang  ,lang  ,gang  ,kang  ,hang  ,      ,      ,      ,zhang ,chang ,shang ,rang  ,zang  ,cang  ,sang  ,
ㄤ    ,ㄅㄤ  ,ㄆㄤ  ,ㄇㄤ  ,ㄈㄤ  ,ㄉㄤ  ,ㄊㄤ  ,ㄋㄤ  ,ㄌㄤ  ,ㄍㄤ  ,ㄎㄤ  ,ㄏㄤ  ,      ,      ,      ,ㄓㄤ  ,ㄔㄤ  ,ㄕㄤ  ,ㄖㄤ  ,ㄗㄤ  ,ㄘㄤ  ,ㄙㄤ  ,
eng   ,beng  ,peng  ,meng  ,feng  ,deng  ,teng  ,neng  ,leng  ,geng  ,keng  ,heng  ,      ,      ,      ,zheng ,cheng ,sheng ,reng  ,zeng  ,ceng  ,seng  ,
ㄥ    ,ㄅㄥ  ,ㄆㄥ  ,ㄇㄥ  ,ㄈㄥ  ,ㄉㄥ  ,ㄊㄥ  ,ㄋㄥ  ,ㄌㄥ  ,ㄍㄥ  ,ㄎㄥ  ,ㄏㄥ  ,      ,      ,      ,ㄓㄥ  ,ㄔㄥ  ,ㄕㄥ  ,ㄖㄥ  ,ㄗㄥ  ,ㄘㄥ  ,ㄙㄥ  ,
er
ㄦ    ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,
yi    ,bi    ,pi    ,mi    ,      ,di    ,ti    ,ni    ,li    ,      ,      ,      ,ji    ,qi    ,xi    ,      ,      ,      ,      ,      ,      ,      ,
ㄧ    ,ㄅㄧ  ,ㄆㄧ  ,ㄇㄧ  ,      ,ㄉㄧ  ,ㄊㄧ  ,ㄋㄧ  ,ㄌㄧ  ,      ,      ,      ,ㄐㄧ  ,ㄑㄧ  ,ㄒㄧ  ,      ,      ,      ,      ,      ,      ,      ,
ya    ,      ,      ,      ,      ,dia   ,      ,nia   ,lia   ,      ,      ,      ,jia   ,qia   ,xia   ,      ,      ,      ,      ,      ,      ,      ,
ㄧㄚ  ,      ,      ,      ,      ,ㄉㄧㄚ,      ,ㄋㄧㄚ,ㄌㄧㄚ,      ,      ,      ,ㄐㄧㄚ,ㄑㄧㄚ,ㄒㄧㄚ,      ,      ,      ,      ,      ,      ,      ,
yo
ㄧㄛ  ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,
ye    ,bie   ,pie   ,mie   ,      ,die   ,tie   ,nie   ,lie   ,      ,      ,      ,jie   ,qie   ,xie   ,      ,      ,      ,      ,      ,      ,      ,
ㄧㄝ  ,ㄅㄧㄝ,ㄆㄧㄝ,ㄇㄧㄝ,      ,ㄉㄧㄝ,ㄊㄧㄝ,ㄋㄧㄝ,ㄌㄧㄝ,      ,      ,      ,ㄐㄧㄝ,ㄑㄧㄝ,ㄒㄧㄝ,      ,      ,      ,      ,      ,      ,      ,
yai
ㄧㄞ  ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,
yao   ,biao  ,piao  ,miao  ,      ,diao  ,tiao  ,niao  ,liao  ,      ,      ,      ,jiao  ,qiao  ,xiao  ,      ,      ,      ,      ,      ,      ,      ,
ㄧㄠ  ,ㄅㄧㄠ,ㄆㄧㄠ,ㄇㄧㄠ,      ,ㄉㄧㄠ,ㄊㄧㄠ,ㄋㄧㄠ,ㄌㄧㄠ,      ,      ,      ,ㄐㄧㄠ,ㄑㄧㄠ,ㄒㄧㄠ,      ,      ,      ,      ,      ,      ,      ,
you   ,      ,      ,miu   ,      ,diu   ,      ,niu   ,liu   ,      ,      ,      ,jiu   ,qiu   ,xiu   ,      ,      ,      ,      ,      ,      ,      ,
ㄧㄡ  ,      ,      ,ㄇㄧㄡ,      ,ㄉㄧㄡ,      ,ㄋㄧㄡ,ㄌㄧㄡ,      ,      ,      ,ㄐㄧㄡ,ㄑㄧㄡ,ㄒㄧㄡ,      ,      ,      ,      ,      ,      ,      ,
yan   ,bian  ,pian  ,mian  ,      ,dian  ,tian  ,nian  ,lian  ,      ,      ,      ,jian  ,qian  ,xian  ,      ,      ,      ,      ,      ,      ,      ,
ㄧㄢ  ,ㄅㄧㄢ,ㄆㄧㄢ,ㄇㄧㄢ,      ,ㄉㄧㄢ,ㄊㄧㄢ,ㄋㄧㄢ,ㄌㄧㄢ,      ,      ,      ,ㄐㄧㄢ,ㄑㄧㄢ,ㄒㄧㄢ,      ,      ,      ,      ,      ,      ,      ,
yin   ,bin   ,pin   ,min   ,      ,      ,      ,nin   ,lin   ,      ,      ,      ,jin   ,qin   ,xin   ,      ,      ,      ,      ,      ,      ,      ,
ㄧㄣ  ,ㄅㄧㄣ,ㄆㄧㄣ,ㄇㄧㄣ,      ,      ,      ,ㄋㄧㄣ,ㄌㄧㄣ,      ,      ,      ,ㄐㄧㄣ,ㄑㄧㄣ,ㄒㄧㄣ,      ,      ,      ,      ,      ,      ,      ,
yang  ,biang ,      ,      ,      ,      ,      ,niang ,liang ,      ,      ,      ,jiang ,qiang ,xiang ,      ,      ,      ,      ,      ,      ,      ,
ㄧㄤ  ,ㄅㄧㄤ,      ,      ,      ,      ,      ,ㄋㄧㄤ,ㄌㄧㄤ,      ,      ,      ,ㄐㄧㄤ,ㄑㄧㄤ,ㄒㄧㄤ,      ,      ,      ,      ,      ,      ,      ,
ying  ,bing  ,ping  ,ming  ,      ,ding  ,ting  ,ning  ,ling  ,      ,      ,      ,jing  ,qing  ,xing  ,      ,      ,      ,      ,      ,      ,      ,
ㄧㄥ  ,ㄅㄧㄥ,ㄆㄧㄥ,ㄇㄧㄥ,      ,ㄉㄧㄥ,ㄊㄧㄥ,ㄋㄧㄥ,ㄌㄧㄥ,      ,      ,      ,ㄐㄧㄥ,ㄑㄧㄥ,ㄒㄧㄥ,      ,      ,      ,      ,      ,      ,      ,
wu    ,bu    ,pu    ,mu    ,fu    ,du    ,tu    ,nu    ,lu    ,gu    ,ku    ,hu    ,      ,      ,      ,zhu   ,chu   ,shu   ,ru    ,zu    ,cu    ,su    ,
ㄨ    ,ㄅㄨ  ,ㄆㄨ  ,ㄇㄨ  ,ㄈㄨ  ,ㄉㄨ  ,ㄊㄨ  ,ㄋㄨ  ,ㄌㄨ  ,ㄍㄨ  ,ㄎㄨ  ,ㄏㄨ  ,      ,      ,      ,ㄓㄨ  ,ㄔㄨ  ,ㄕㄨ  ,ㄖㄨ  ,ㄗㄨ  ,ㄘㄨ  ,ㄙㄨ  ,
wa    ,      ,      ,      ,      ,      ,      ,      ,      ,gua   ,kua   ,hua   ,      ,      ,      ,zhua  ,chua  ,shua  ,rua   ,      ,      ,      ,
ㄨㄚ  ,      ,      ,      ,      ,      ,      ,      ,      ,ㄍㄨㄚ,ㄎㄨㄚ,ㄏㄨㄚ,      ,      ,      ,ㄓㄨㄚ,ㄔㄨㄚ,ㄕㄨㄚ,ㄖㄨㄚ,      ,      ,      ,
wo    ,      ,      ,      ,      ,duo   ,tuo   ,nuo   ,luo   ,guo   ,kuo   ,huo   ,      ,      ,      ,zhuo  ,chuo  ,shuo  ,ruo   ,zuo   ,cuo   ,suo   ,
ㄨㄛ  ,      ,      ,      ,      ,ㄉㄨㄛ,ㄊㄨㄛ,ㄋㄨㄛ,ㄌㄨㄛ,ㄍㄨㄛ,ㄎㄨㄛ,ㄏㄨㄛ,      ,      ,      ,ㄓㄨㄛ,ㄔㄨㄛ,ㄕㄨㄛ,ㄖㄨㄛ,ㄗㄨㄛ,ㄘㄨㄛ,ㄙㄨㄛ,
wai   ,      ,      ,      ,      ,      ,      ,      ,      ,guai  ,kuai  ,huai  ,      ,      ,      ,zhuai ,chuai ,shuai ,      ,      ,      ,      ,
ㄨㄞ  ,      ,      ,      ,      ,      ,      ,      ,      ,ㄍㄨㄞ,ㄎㄨㄞ,ㄏㄨㄞ,      ,      ,      ,ㄓㄨㄞ,ㄔㄨㄞ,ㄕㄨㄞ,      ,      ,      ,      ,
wei   ,      ,      ,      ,      ,dui   ,tui   ,      ,      ,gui   ,kui   ,hui   ,      ,      ,      ,zhui  ,chui  ,shui  ,rui   ,zui   ,cui   ,sui   ,
ㄨㄟ  ,      ,      ,      ,      ,ㄉㄨㄟ,ㄊㄨㄟ,      ,      ,ㄍㄨㄟ,ㄎㄨㄟ,ㄏㄨㄟ,      ,      ,      ,ㄓㄨㄟ,ㄔㄨㄟ,ㄕㄨㄟ,ㄖㄨㄟ,ㄗㄨㄟ,ㄘㄨㄟ,ㄙㄨㄟ,
wan   ,      ,      ,      ,      ,duan  ,tuan  ,nuan  ,luan  ,guan  ,kuan  ,huan  ,      ,      ,      ,zhuan ,chuan ,shuan ,ruan  ,zuan  ,cuan  ,suan  ,
ㄨㄢ  ,      ,      ,      ,      ,ㄉㄨㄢ,ㄊㄨㄢ,ㄋㄨㄢ,ㄌㄨㄢ,ㄍㄨㄢ,ㄎㄨㄢ,ㄏㄨㄢ,      ,      ,      ,ㄓㄨㄢ,ㄔㄨㄢ,ㄕㄨㄢ,ㄖㄨㄢ,ㄗㄨㄢ,ㄘㄨㄢ,ㄙㄨㄢ,
wen   ,      ,      ,      ,      ,dun   ,tun   ,      ,lun   ,gun   ,kun   ,hun   ,      ,      ,      ,zhun  ,chun  ,shun  ,run   ,zun   ,cun   ,sun   ,
ㄨㄣ  ,      ,      ,      ,      ,ㄉㄨㄣ,ㄊㄨㄣ,      ,ㄌㄨㄣ,ㄍㄨㄣ,ㄎㄨㄣ,ㄏㄨㄣ,      ,      ,      ,ㄓㄨㄣ,ㄔㄨㄣ,ㄕㄨㄣ,ㄖㄨㄣ,ㄗㄨㄣ,ㄘㄨㄣ,ㄙㄨㄣ,
wang  ,      ,      ,      ,      ,      ,      ,      ,      ,guang ,kuang ,huang ,      ,      ,      ,zhuang,chuang,shuang,      ,      ,      ,      ,
ㄨㄤ  ,      ,      ,      ,      ,      ,      ,      ,      ,ㄍㄨㄤ,ㄎㄨㄤ,ㄏㄨㄤ,      ,      ,      ,ㄓㄨㄤ,ㄔㄨㄤ,ㄕㄨㄤ,      ,      ,      ,      ,
weng  ,      ,      ,      ,      ,dong  ,tong  ,nong  ,long  ,gong  ,kong  ,hong  ,      ,      ,      ,zhong ,chong ,      ,rong  ,zong  ,cong  ,song  ,
ㄨㄥ  ,      ,      ,      ,      ,ㄉㄨㄥ,ㄊㄨㄥ,ㄋㄨㄥ,ㄌㄨㄥ,ㄍㄨㄥ,ㄎㄨㄥ,ㄏㄨㄥ,      ,      ,      ,ㄓㄨㄥ,ㄔㄨㄥ,      ,ㄖㄨㄥ,ㄗㄨㄥ,ㄘㄨㄥ,ㄙㄨㄥ,
yu    ,      ,      ,      ,      ,      ,      ,nü    ,lü    ,      ,      ,      ,ju    ,qu    ,xu    ,      ,      ,      ,      ,      ,      ,      ,
ㄩ    ,      ,      ,      ,      ,      ,      ,ㄋㄩ  ,      ,      ,      ,      ,ㄐㄩ  ,ㄑㄩ  ,ㄒㄩ  ,      ,      ,      ,      ,      ,      ,      ,
yue   ,      ,      ,      ,      ,      ,      ,nüe   ,lüe   ,      ,      ,      ,jue   ,que   ,xue   ,      ,      ,      ,      ,      ,      ,      ,
ㄩㄝ  ,      ,      ,      ,      ,      ,      ,ㄋㄩㄝ,ㄌㄩㄝ,      ,      ,      ,ㄐㄩㄝ,ㄑㄩㄝ,ㄒㄩㄝ,      ,      ,      ,      ,      ,      ,      ,
yuan  ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,juan  ,quan  ,xuan  ,      ,      ,      ,      ,      ,      ,      ,
ㄩㄢ  ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,ㄐㄩㄢ,ㄑㄩㄢ,ㄒㄩㄢ,      ,      ,      ,      ,      ,      ,      ,
yun   ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,jun   ,qun   ,xun   ,      ,      ,      ,      ,      ,      ,      ,
ㄩㄣ  ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,ㄐㄩㄣ,ㄑㄩㄣ,ㄒㄩㄣ,      ,      ,      ,      ,      ,      ,      ,
yong  ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,jiong ,qiong ,xiong ,      ,      ,      ,      ,      ,      ,      ,
ㄩㄥ  ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,      ,ㄐㄩㄥ,ㄑㄩㄥ,ㄒㄩㄥ,      ,      ,      ,      ,      ,      ,      ,
]]

---@type table<string, string>
M.pinyin2zhuyin = {}

local lines = {}
for l in string.gmatch(PINYIN, "[^\n]+") do
  table.insert(lines, l)
end
for i = 2, #lines, 2 do
  local ks = util.splited(lines[i], ",")
  local vs = util.splited(lines[i + 1], ",")
  -- print(#cols)
  for j = 1, 22 do
    local k = util.strip(ks[j])
    local v = util.strip(vs[j])
    if #k > 0 and #v > 0 then
      M.pinyin2zhuyin[k] = v
    end
  end
end

---@param pinyin string
---@return string?
---@return integer?
function M:to_zhuyin(pinyin)
  -- remove 声調
  local n = nil
  for from, _to in pairs(self.to_ascii) do
    local to, _n = unpack(_to)
    local _pinyin = pinyin:gsub(from, to)
    if _pinyin ~= pinyin then
      pinyin = _pinyin
      if _n then
        n = _n
      end
    end
  end

  local zhuyin = self.pinyin2zhuyin[pinyin]
  if zhuyin then
    return zhuyin, n
  end
end

return M
