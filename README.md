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
      unihan = vim.fn.expand "~/.skk/Unihan_DictionaryLikeData.txt",
      xszd = vim.fn.expand "~/.skk/xszd.txt",
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

## テスト環境

`Windows11`

```sh
> pip install hererocks
> hererocks -j 2.1 -r latest luarocks
> .\luarocks\bin\lua.exe -v
LuaJIT 2.1.0-beta3 -- Copyright (C) 2005-2017 Mike Pall. http://luajit.org/
> .\luarocks\bin\activate.ps1
> luarocks install busted
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
  - [ ] 音読み
  - [ ] pinyin => (注音符号) => 漢字
- [ ] WEB支那漢 日本語音訓 https://www.seiwatei.net/info/dnchina.htm
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

### unicode

- https://www.unicode.org/Public/emoji/1.0/emoji-data.txt

#### Unihan

- https://www.unicode.org/Public/UCD/latest/ucd/
  - https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
- https://hexdocs.pm/unicode_unihan/dictionary_like_data.html#content

- Unihan_DictionaryLikeData.txt 四角号碼 etc...
- Unihan_Readings.txt 字音, pinyin etc...
- Unihan_Variants.txt 異字体, kSimplifiedVariant, kTraditionalVariant

### 漢字

- WEB支那漢 日本語音訓 
  - https://www.seiwatei.net/info/dnchina.htm
- https://github.com/cjkvi/cjkvi-dict
  - 學生字典 Text Data (xszd.txt)

- 常用漢字
  - https://x0213.org/joyo-kanji-code/

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
