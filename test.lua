local kanaconv = require("lkk.kanaconv")

local kana, new_state = kanaconv.to_kana("k")
print(kana, new_state)
kana, new_state = kanaconv.to_kana("a", new_state)
print(kana, new_state)
