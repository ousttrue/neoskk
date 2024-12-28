# neoskk

neovim の skk(lua).

[SKK実装入門 (2) ひらがな入力](https://zenn.dev/uga_rosa/articles/e4c532a59de7d6)

を基点に実装しました.

未確定の入力を extmark で色を変えて表示します.

```lua
-- lazy
{
  "ousttrue/neoskk",
  config = function()
    require("neoskk").setup {
      jisyo = vim.fn.expand "~/.skk/SKK-JISYO.L",
      unihan = vim.fn.expand "~/.skk/Unihan_DictionaryLikeData.txt",
    }
    vim.keymap.set("i", "<C-j>", function()
      return require("neoskk").toggle()
    end, {
      remap = false,
      expr = true,
    })
  end,
},
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
- [ ] insertmode を抜けるときに conv_feed を buffer に出力する

- [ ] floating でカーソル近くにモード表示

https://github.com/delphinus/skkeleton_indicator.nvim

- alphabet 以外の入力
  - [x] `-` `~` `[`, `]` `,.` `0123456789`
  - [x] q: カタカナ・ひらがなスイッチ
  - [x] 変換モードq: カタカナ・ひらがなスイッチ

[Vim scriptでひらがな・カタカナ相互変換](https://zenn.dev/kawarimidoll/articles/46ccbbf8b62700)

language-mapping

https://zenn.dev/uga_rosa/articles/e4c532a59de7d6#2.6.-language-mapping

- [x] `<BS>`
- [x] 変換モード`<Space>`: completion
- [ ] l: ASCIIモード
- [ ] completion キャンセルで conv_feed 化する
- [ ] visual mode 選択を conv_feed 化する

- [ ] azik
- [ ] 絵文字 https://www.unicode.org/Public/emoji/1.0/emoji-data.txt
- Unihan_DictionaryLikeData.txt
  - [x] 四角号碼 G1234 のように入力する
  - [ ] 音読み
  - [ ] pinyin => (注音符号) => 漢字
- [ ] 學生字典から completion info
- [ ] 學生字典の反切から字音仮名遣を生成する

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
- https://www.unicode.org/Public/UCD/latest/ucd/
  - https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip

### 漢字

- https://github.com/cjkvi/cjkvi-dict
  - 學生字典 Text Data (xszd.txt)

### pinyin

- https://github.com/ZSaberLv0/ZFVimIM_pinyin_base/tree/master/misc
- https://github.com/ZSaberLv0/ZFVimIM_pinyin/tree/master/misc

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
