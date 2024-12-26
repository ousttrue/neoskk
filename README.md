# lkk

skk は名前空間が混んでいるのでちょっと違う名前にした。

```
skk => Simple Kana to Kanji => Lua Kana to Kanji => lkk
```

## 実装ノート

- [x] 素の busted でテストが動く
      (Windows だからなのか vusted うまくいかなかった)

`Windows11`

```sh
> pip install hererocks
> hererocks -j 2.1 -r latest local
> .\local\bin\lua.exe -v
LuaJIT 2.1.0-beta3 -- Copyright (C) 2005-2017 Mike Pall. http://luajit.org/
> .\local\bin\activate.ps1
> luarocks install busted
> .\local\bin\busted.bat --version
2.2.0
```

```sh
> busted ./tests --helper=./tests/testhelper.lua
●●●●●●●
7 successes / 0 failures / 0 errors / 0 pending : 0.0 seconds
```

- [x] lua-language-server

[Neovim Lua のための LuaLS セットアップ](https://zenn.dev/uga_rosa/articles/afe384341fc2e1)

- [x] ロジックを関数型っぽくしてテストしやすくする

```lua
---@param src string キー入力
---@param _feed string?
---@return string 確定変換済み
---@return string 未使用のキー入力
function M.to_kana(src, _feed)
```

- [x] nvim で動く

```lua
-- lazy
{
  "ousttrue/lkk",
  config = function()
    require("lkk").setup {
    }
    vim.keymap.set("i", "<C-j>", function()
      return require("lkk").get_or_create():toggle()
    end, {
      remap = false,
      expr = true,
    })
  end,
},
```

- [x] extmark で 未確定を表示する

- [ ] comprefunc

- [ ] backspace preedit

## 参考

- https://github.com/uga-rosa/skk-learning.nvim

  - [SKK実装入門 (1) ローマ字 -> ひらがな変換](https://zenn.dev/uga_rosa/articles/ec5281d5a95a57)
  - [SKK実装入門 (2) ひらがな入力](https://zenn.dev/uga_rosa/articles/e4c532a59de7d6)

- [SKK Openlab - トップ](http://openlab.ring.gr.jp/skk/index-j.html)
- [SKK (Simple Kana to Kanji conversion program) Manual &mdash; ddskk 17.1 ドキュメント](https://ddskk.readthedocs.io/ja/latest/)
