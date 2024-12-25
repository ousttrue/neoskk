# lkk

skk は名前空間が混んでいるのでちょっと違う名前にした。

```
skk => Simple Kana to Kanji => Lua Kana to Kanji => lkk
```

## 開発環境

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

## TODO

- [x] 素の busted でテストが動く
- [ ] nvim で動く

```sh
> busted ./tests --helper=./tests/testhelper.lua
●●●●●●●
7 successes / 0 failures / 0 errors / 0 pending : 0.0 seconds
```

## 参考

- https://github.com/uga-rosa/skk-learning.nvim
  - [SKK実装入門 (1) ローマ字 -> ひらがな変換](https://zenn.dev/uga_rosa/articles/ec5281d5a95a57)
  - [SKK実装入門 (2) ひらがな入力](https://zenn.dev/uga_rosa/articles/e4c532a59de7d6)
- [SKK (Simple Kana to Kanji conversion program) Manual &mdash; ddskk 17.1 ドキュメント](https://ddskk.readthedocs.io/ja/latest/)
