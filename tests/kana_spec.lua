local ruleconv = require "neoskk.tables.ruleconv"
local KanaRules = require "neoskk.tables.KanaRules"

---@param src string
---@return string src
---@return string feed
local function to_kana(src)
  local feed = ""
  -- 出力文字列
  local output = ""
  -- 部分一致が複数在って後続を見るまで確定できない
  ---@type MatchedKanaRule?
  local candidate = nil

  for key in src:gmatch "." do
    -- 一文字ずつ処理する
    feed = feed .. key
    -- local match = match_rules(candidate and candidate.prefix_matches or rules, feed)
    local tmp_output
    tmp_output, feed, candidate = ruleconv(candidate and candidate.prefix_matches or KanaRules, feed, candidate)
    -- tmp_output, feed, candidate = match:resolve(candidate)
    if tmp_output then
      output = output .. tmp_output
    end
  end

  while #feed > 0 do
    -- 入力の残り
    -- local match = match_rules(candidate and candidate.prefix_matches or rules, feed)
    local tmp_output, tmp_feed, tmp_candidate = ruleconv(candidate and candidate.prefix_matches or KanaRules, feed, candidate)
    candidate = tmp_candidate
    if tmp_output then
      output = output .. tmp_output
    end
    if feed == tmp_feed then
      break
    end
    feed = tmp_feed
  end

  return output, feed
end

-- TODO 辞書を引数にする

describe("Tests for かな入力", function()
  it("single char", function()
    local kana = to_kana "ka"
    assert.are.equal("か", kana)
  end)

  it("imcomplete", function()
    local kana, feed = to_kana "k"
    assert.are.equal("", kana)
    assert.are.equal("k", feed)

    kana, feed = to_kana(feed .. "a")
    assert.are.equal("か", kana)
    assert.are.equal("", feed)
  end)

  it("multiple chars (don't use tmpResult)", function()
    local kana = to_kana "ohayou"
    assert.are.equal("おはよう", kana)
  end)

  it("multiple chars (use tmpResult)", function()
    local kana = to_kana "amenbo"
    assert.are.equal("あめんぼ", kana)
  end)

  it("multiple chars (use tmpResult and its next)", function()
    local kana = to_kana "uwwwa"
    assert.are.equal("うwっわ", kana)
  end)

  it("mistaken input", function()
    local kana = to_kana "rkakyra"
    assert.are.equal("rかkyら", kana)
  end)
end)
