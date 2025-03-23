# neoskk

neovim の skk(lua).

[SKK実装入門 (2) ひらがな入力](https://zenn.dev/uga_rosa/articles/e4c532a59de7d6)

を基点に実装。

## impl

かな漢字変換を LanguageServer の completion に実装して機能を分離した。

https://github.com/ousttrue/unihan.nvim

この plugin は、ascii から ひらがな/かたかな変換だけをすることになった。
LanguageServer の目印に三角マーカーを出力するが、後のことは感知しないというスタイル。
状態管理は無くなって、buffer のカーソルの左の文字を見て ascii をひらがなに変換する。
英単語に続けてかなを入力しようとすると、うまくいかないことに今気付いた。
space を入れよう。

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

- [x] 素の busted でテストが動く(コアは vim 要素を使わない)
- [ ] vusted (Windows だからなのか vusted うまくいかなかった)
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
- [x] `<Enter>` で変換モード脱出(未変換のかなを確定)
- [x] ひらがな片仮名変換除外 `ー` (範囲方式をやめた)
- [x] l: ASCIIモード
- [ ] azik

## 参考

- https://github.com/uga-rosa/skk-learning.nvim

  - [SKK実装入門 (1) ローマ字 -> ひらがな変換](https://zenn.dev/uga_rosa/articles/ec5281d5a95a57)
  - [SKK実装入門 (2) ひらがな入力](https://zenn.dev/uga_rosa/articles/e4c532a59de7d6)

- [SKK Openlab - トップ](http://openlab.ring.gr.jp/skk/index-j.html)
- [SKK (Simple Kana to Kanji conversion program) Manual &mdash; ddskk 17.1 ドキュメント](https://ddskk.readthedocs.io/ja/latest/)

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
