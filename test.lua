--
-- vscode でデバッガをアタッチする
--

-- local kanaconv = require "neoskk.kanaconv"
-- local SkkMachine = require("neoskk.machine").SkkMachine
local CompletionItem = require("neoskk.CompletionItem")

-- local kana, new_state = kanaconv.to_kana("k")
-- print(kana, new_state)
-- kana, new_state = kanaconv.to_kana("a", new_state)
-- print(kana, new_state)

-- local kana, new_state = kanaconv.to_kana "amenbo"
-- local kana, new_state = kanaconv.to_kana "rkakyra"

-- local engine = SkkMachine.new()

-- local out, feed = engine:input "b"
-- out, feed = engine:input "\b"

-- print(out, feed)

local Kls = {
    __eq = function(a, b)
        return true
    end
}

local x = setmetatable({}, Kls)

local b = setmetatable({}, Kls)

assert(x==b)
