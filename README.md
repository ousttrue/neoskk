# neoskk

neovim の skk(lua).

[SKK実装入門 (2) ひらがな入力](https://zenn.dev/uga_rosa/articles/e4c532a59de7d6)

を基点に実装しました.

preedit を extmark で表示します.

```lua
-- lazy
{
  "ousttrue/neoskk",
  config = function()
    require("neoskk").setup {
      jisyo = vim.fn.expand "~/.skk/SKK-JISYO.L",
      unihan_dir = vim.fn.expand "~/unihan",
      xszd = vim.fn.expand "~/.skk/xszd.txt",
      emoji = vim.fn.expand "~/.skk/emoji-data.txt",
      chinadat = vim.fn.expand "~/.skk/chinadat.csv",
    }
    local opts = {
      remap = false,
      expr = true,
    }
    vim.keymap.set("i", "<C-j>", function()
      local neoskk = require "neoskk"
      return neoskk.toggle()
    end, opts)
    vim.keymap.set("i", "<C-b>", function()
      local neoskk = require "neoskk"
      return neoskk.toggle "zhuyin"
    end, opts)
  end,
},
```

四角号碼と かな と 反切 と pinyin を表示。

```
  点$
~ 点 2133.6 テン      diǎn                           [=>點]
~ 店 0026.1 テン 都念 diàn                           [康煕]+
~ 天 1043.0 テン 他前 tiān                           [康煕]+
~ 転 5103.1 テン      zhuǎn                          [=>轉]
~ 展 7723.2 テン 知演 zhǎn                           [康煕]+
~ 貂 2726.2 チョウ 都聊 diāo                         [康煕]+
~ 典 5580.1 テン 多殄 diǎn                           [康煕]+
```

學生字典から info を表示。

```
  # input
  少 な$
  # completion   # info
~ 少な           -始夭切(Shao)上聲
~ 竦;足が竦んで  --不多也。此減於彼亦曰少。如言共少若干。俗亦謂失去物件曰少。如言缺少、短少、是也。
~ 窘;<rare>      --暫也。時不久也。如有間曰少頃。
~                --短也。訾人曰少之。猶稱人曰多之也。
~                -試要切去聲
~                --老之對。如少年、少壯。
~                --副貳也。如太師、太傅、太保。副之以少師、少傅、少保、是也。
~
```

hover

```md
# 成
UNICODE: U+6210, 四角号碼: 5320.0

# 読み
セイ,ジョウ,なる,なす,たいらげる,なt,なs,なr,なn,なc,しげ,じょう,せい,せい>,なり,なる,まさ
ㄔㄥ2

# 廣韻 清, 小韻 成, 是征切平声 開口三等 zjeng

## 梗攝
`平` 上 去 入
────────────────────────────────────────────────────────────────────────────────────────────
庚 梗 敬 陌 開口二等
耕 耿 諍 麦 開口二等
`清` 静 勁 昔 開口二等
────────────────────────────────────────────────────────────────────────────────────────────
青 迥 径 錫

## 聲紐: 常, 正歯音章組濁
五音| 唇唇唇唇唇唇唇唇舌舌舌舌舌舌舌舌歯歯歯歯歯歯歯歯歯歯歯歯歯歯歯牙牙牙牙喉喉喉喉喉半半
清濁| 清次濁両次濁清両清次濁両清次濁両清次濁清濁清次濁清濁清次濁濁次清次濁両清清濁両両両両
聲紐| 幫〇〇明〇〇〇〇〇〇〇〇知徹澄〇精清從心邪〇〇〇〇〇章〇常書〇〇溪〇〇曉〇影〇以來〇
────────────────────────────────────────────────────────────────────────────────────────────
小韻| 并〇〇名〇〇〇〇〇〇〇〇貞檉呈〇精清情騂𩛿〇〇〇〇〇征〇`成`聲〇〇輕〇〇𧵣〇嬰〇盈跉〇

## 10字

|① 成 ㄔㄥ2 セイ|② 𢦩|③ 城 ㄔㄥ2 ジョウ|④ 誠 ㄔㄥ2 セイ
|⑤ 宬 ㄔㄥ2 セイ|⑥ 郕 ㄔㄥ2 セイ|⑦ 筬 ㄔㄥ2 セイ|⑧ 盛 ㄕㄥ4 セイ
|⑨ 珹 ㄔㄥ2 セイ|⑩ 䫆 ㄔㄥ2 セイ
```

## テスト環境

`Windows11`

```sh
> pip install hererocks
> hererocks -j 2.1 -r latest luarocks
> .\luarocks\bin\lua.exe -v
LuaJIT 2.1.0-beta3 -- Copyright (C) 2005-2017 Mike Pall. http://luajit.org/
> .\luarocks\bin\activate.ps1
> luarocks install busted luv
> .\luarocks\bin\busted.bat --version
2.2.0
```

```sh
> busted ./tests --helper=./tests/testhelper.lua
●●●●●●●
7 successes / 0 failures / 0 errors / 0 pending : 0.0 seconds
```

## 実装ノート

```
from https://github.com/uobikiemukot/yaskk

                      +--------------------------------+
                      |         ひら or カタ           |
                      +--------------------------------+
                upper | ^ Ctrl+J (途中経過が確定)      ^ l (確定後にASCIIモードへ)
                      | | Ctrl+H (▽を消す)             | q (確定後にひら・カタのトグル)
                      | | ESC or Ctrl+G (途中経過消失) | Ctrl+J or その他の文字 (確定後に元のモードに戻る)
                      | |                              | Ctrl+H (確定後，1文字消える)
                      | |                              |
                      v |         ESC or Ctrl+G        |
                   +--------+ <------------------ +--------+
q (ひら・カタ変換) |  変換  |                     |  選択  | Ctrl+P or x: 前候補
                   +--------+ ------------------> +--------+ Ctrl+N or SPACE: 次候補
                            |        SPACE        ^
                      upper |                     | 送り仮名が確定すると自動で遷移
                            v                     | (促音では遷移しない)
                            +---------------------+
                            |  送り仮名確定待ち   |
                            +---------------------+
                              Ctrl+J: ひら or カタ モードへ戻る
                              ESC: 変換モードへ戻る
```

- [x] 素の busted でテストが動く(コアは vim 要素を使わない)
- [ ] vusted (Windows だからなのか vusted うまくいかなかった)
- [x] lua-language-server

[Neovim Lua のための LuaLS セットアップ](https://zenn.dev/uga_rosa/articles/afe384341fc2e1)

- [x] ロジックを関数型っぽくしてテストしやすくする(状態も関数の引数/返り値にする)

```lua
---@param src string キー入力
---@param _feed string?
---@return string 確定変換済み
---@return string 未使用のキー入力
function M.to_kana(src, _feed)
end

-- busted test
it("single char", function()
  local kana, feed = kanaconv.to_kana "k"
  assert.are.equal("", kana)
  assert.are.equal("k", feed)

  kana, feed = kanaconv.to_kana(feed .. "a")
  assert.are.equal("か", kana)
  assert.are.equal("", feed)
end)
```

- [x] nvim で動く
- [x] extmark で 未確定を表示する

https://zenn.dev/notomo/articles/neovim-zebra-highlight

- [x] SKK-JISYO.L
  - [x] euc to utf-8 `vim.iconv`
- [x] 大文字でのモード変更
- [x] 変換モード(RAW, CONV, OKURI)
- [x] 送り仮名
- [x] 候補が一つのときに自動で確定
- [x] insertmode を抜けるときに conv_feed を buffer に出力する
- [x] floating でカーソル近くにモード表示

https://github.com/delphinus/skkeleton_indicator.nvim

- alphabet 以外の入力
- [x] `-` `~` `[`, `]` `,.` `0123456789`
  - [x] q: カタカナ・ひらがなスイッチ
  - [x] 変換モードq: カタカナ・ひらがなスイッチ
- [x] CommandlineMode では止める

[Vim scriptでひらがな・カタカナ相互変換](https://zenn.dev/kawarimidoll/articles/46ccbbf8b62700)

language-mapping

https://zenn.dev/uga_rosa/articles/e4c532a59de7d6#2.6.-language-mapping

- [x] `<BS>`
- [x] 変換モード`<Space>`: completion
- [x] `<Enter>` で変換モード脱出(変換しなかったかなを確定)
- [ ] ひらがな片仮名変換除外 `ー`
- [x] l: ASCIIモード
- [ ] completion キャンセルで conv_feed 化する
- [ ] visual mode 選択を conv_feed 化する

- [ ] azik
- [ ] 絵文字 https://www.unicode.org/Public/emoji/1.0/emoji-data.txt
- Unihan_DictionaryLikeData.txt
  - [x] 四角号碼 G1234 のように入力する
  - [x] 音読み
  - [x] pinyin => (注音符号) => 漢字
- [x] WEB支那漢 日本語音訓 https://www.seiwatei.net/info/dnchina.htm
- [x] 學生字典から completion info
- [ ] 常用漢字などハイライトする

## 参考

- https://github.com/uga-rosa/skk-learning.nvim

  - [SKK実装入門 (1) ローマ字 -> ひらがな変換](https://zenn.dev/uga_rosa/articles/ec5281d5a95a57)
  - [SKK実装入門 (2) ひらがな入力](https://zenn.dev/uga_rosa/articles/e4c532a59de7d6)

- [SKK Openlab - トップ](http://openlab.ring.gr.jp/skk/index-j.html)
- [SKK (Simple Kana to Kanji conversion program) Manual &mdash; ddskk 17.1 ドキュメント](https://ddskk.readthedocs.io/ja/latest/)

## 辞書

### SKK

- http://openlab.ring.gr.jp/skk/wiki/wiki.cgi?page=SKK%BC%AD%BD%F1
- https://github.com/skk-dict/jisyo

#### Unicode

- https://www.unicode.org/Public/UNIDATA/

  - Blocks.txt
  - UnicodeData.txt

- https://www.unicode.org/reports/tr38/
- https://www.unicode.org/Public/UCD/latest/ucd/

  - https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
    - Unihan_DictionaryLikeData.txt 四角号碼 etc...
    - Unihan_Readings.txt かな, pinyin, 反切 etc...
    - Unihan_Variants.txt 異字体, kSimplifiedVariant, kTraditionalVariant

- https://www.unicode.org/Public/emoji/1.0/emoji-data.txt

### 漢字

- WEB支那漢 日本語音訓
  - https://www.seiwatei.net/info/dnchina.htm
- https://github.com/cjkvi/cjkvi-dict

  - 學生字典 Text Data (xszd.txt)

- https://github.com/rime-aca/character_set

- [有女同車《〈廣韻〉全字表》原表](https://github.com/syimyuzya/guangyun0704)
- `影印本` https://github.com/kanripo/KR1j0054
- https://github.com/rime-aca/rime-middle-chinese-phonetics?tab=readme-ov-file
- https://github.com/sozysozbot/zyegnio_xrynmu/tree/master
- https://ytenx.org/
- https://github.com/pujdict/pujdict

玉篇

- https://www.kanripo.org/
- https://github.com/kanripo/KR1j0056
- https://github.com/kanripo/KR1j0022

- https://github.com/g0v/moedict-app

### 常用漢字

- [簡体字、日用字変換の手順](http://mikeo410.minim.ne.jp/%EF%BC%95%EF%BC%8E%E3%80%8C%E3%81%8B%E3%81%9F%E3%81%A1%E3%80%8D%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6/%EF%BC%91%EF%BC%8E%E6%96%87%E5%AD%97/%EF%BC%91%EF%BC%8E%E7%B0%A1%E4%BD%93%E5%AD%97/%EF%BC%91%EF%BC%8E%E7%B0%A1%E4%BD%93%E5%AD%97%E3%80%81%E6%97%A5%E7%94%A8%E5%AD%97%E5%A4%89%E6%8F%9B%E3%81%AE%E6%89%8B%E9%A0%86.html)
- https://x0213.org/joyo-kanji-code/
- https://github.com/rime-aca/character_set
- https://www.aozora.gr.jp/kanji_table/

- https://github.com/zispace/hanzi-chars
  - https://github.com/zispace/hanzi-chars/blob/main/data-charlist/%E6%97%A5%E6%9C%AC%E3%80%8A%E5%B8%B8%E7%94%A8%E6%BC%A2%E5%AD%97%E8%A1%A8%E3%80%8B%EF%BC%882010%E5%B9%B4%EF%BC%89%E6%97%A7%E5%AD%97%E4%BD%93.txt

### pinyin

- https://github.com/ZSaberLv0/ZFVimIM_pinyin_base/tree/master/misc
- https://github.com/ZSaberLv0/ZFVimIM_pinyin/tree/master/misc

- https://github.com/fxsjy/jieba

## 各種SKK実装

### uim-fep

https://github.com/uim/uim/blob/master/fep/README.ja

`c, scheme, pty`

escape sequence(DECSTBM) で一番の下の行をステータスラインとして確保する。

### skkfep(いにしえ)

`c, pty`

http://ftp.nara.wide.ad.jp/pub/Linux/gentoo-portage/app-i18n/skkfep/skkfep-0.87-r1.ebuild

escape sequence で一番の下の行をステータスラインとして確保する。

### yaskk

`c`

https://github.com/uobikiemukot/yaskk

READMEの状態遷移図も参考になる。
