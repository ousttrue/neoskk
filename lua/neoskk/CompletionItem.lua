local pinyin = require "neoskk.pinyin"

---@class CompletionItem
---@field word string the text that will be inserted, mandatory
---@field abbr string? abbreviation of "word"; when not empty it is used in the menu instead of "word"
---@field menu string? extra text for the popup menu, displayed after "word" or "abbr"
---@field info string? more information about the item, can be displayed in a preview window
---@field kind string? single letter indicating the type of completion icase		when non-zero case is to be ignored when comparing items to be equal; when omitted zero is used, thus items that only differ in case are added
---@field equal? boolean when non-zero, always treat this item to be equal when comparing. Which means, "equal=1" disables filtering of this item.
---@field dup? boolean when non-zero this match will be added even when an item with the same word is already present.
---@field empty? boolean	when non-zero this match will be added even when it is an empty string
---@field user_data?	any custom data which is associated with the item and available in |v:completed_item|; it can be any type; defaults to an empty string
---@field abbr_hlgroup? string an additional highlight group whose attributes are combined with |hl-PmenuSel| and |hl-Pmenu| or |hl-PmenuMatchSel| and |hl-PmenuMatch| highlight attributes in the popup menu to apply cterm and gui properties (with higher priority) like strikethrough to the completion items abbreviation
---@field kind_hlgroup? string an additional highlight group specifically for setting the highlight attributes of the completion kind. When this field is present, it will override the |hl-PmenuKind| highlight group, allowing for the customization of ctermfg and guifg properties for the completion kind
local CompletionItem = {}
CompletionItem.__index = CompletionItem

---@param src {word:string?, abbr:string?, menu:string?, info:string?, kind:string?, equal: boolean?, dup:boolean?, empty: boolean?, user_data: any, abbr_hlgroup:string?, kind_hlgroup:string? }?
function CompletionItem.new(src)
  local self = setmetatable({}, CompletionItem)
  if src then
    self.word = src.word or ""
    self.abbr = src.abbr or ""
    self.menu = src.menu or ""
    self.info = src.info or ""
    self.kind = src.kind or ""
    self.equal = src.equal or false
    self.dup = src.dup or false
    self.empty = src.empty or false
    self.user_data = src.user_data or ""
    self.abbr_hlgroup = src.abbr_hlgroup or ""
    self.kind_hlgroup = src.kind_hlgroup or ""
  end
  return self
end

---@param item UniHanChar
---@return string
local function get_prefix(item)
  local prefix = ""
  if item.indices then
    prefix = "康煕"
  elseif item.ref then
    prefix = "=>" .. item.ref
  else
    prefix = "    "
  end
  prefix = "[" .. prefix .. "]"
  if item.xszd then
    prefix = prefix .. "+"
  end
  return prefix
end

---@param ch string 単漢字
---@param item UniHanChar 単漢字情報
---@return CompletionItem
function CompletionItem.from_ch(ch, item, fanqie_map)
  local prefix = get_prefix(item)
  local new_item = {
    word = "g" .. item.goma,
    abbr = ch .. " " .. item.goma,
    menu = prefix,
    dup = true,
    user_data = {
      replace = ch,
    },
    info = item.xszd,
  }
  if #item.kana > 0 then
    new_item.abbr = new_item.abbr .. " " .. item.kana[1]
  end
  if #item.fanqie > 0 then
    new_item.abbr = new_item.abbr .. " " .. item.fanqie[1]
    if item.chou then
      new_item.abbr = new_item.abbr .. item.chou
    end
    local fanqie = fanqie_map[item.fanqie[1]]
    if fanqie then
      new_item.abbr = new_item.abbr .. ":" .. fanqie.koe .. fanqie.moku
    end
  else
    new_item.abbr = new_item.abbr .. " " .. "         "
  end
  if item.pinyin then
    new_item.abbr = new_item.abbr .. " " .. pinyin:to_zhuyin(item.pinyin)
  end

  return new_item
end

function CompletionItem.from_word(w, item, fanqie_map)
  local prefix = " "
  if item then
    prefix = get_prefix(item)
  end
  local new_item = {
    word = w,
    abbr = w,
    menu = prefix,
  }
  if item then
    new_item.info = item.xszd
    if item.goma then
      new_item.abbr = new_item.abbr .. " " .. item.goma
    end
    if #item.kana > 0 then
      new_item.abbr = new_item.abbr .. " " .. item.kana[1]
    end
    if #item.fanqie > 0 then
      new_item.abbr = new_item.abbr .. " " .. item.fanqie[1]
      if item.chou then
        new_item.abbr = new_item.abbr .. item.chou
      end
      local fanqie = fanqie_map[item.fanqie[1]]
      if fanqie then
        new_item.abbr = new_item.abbr .. ":" .. fanqie.koe .. fanqie.moku
      end
    else
      new_item.abbr = new_item.abbr .. " " .. "         "
    end
    if item.pinyin then
      new_item.abbr = new_item.abbr .. " " .. pinyin:to_zhuyin(item.pinyin)
    end
  end
  return new_item
end

---@param a CompletionItem
---@param b CompletionItem
function CompletionItem.__eq(a, b)
  return a.word == b.word
end

return CompletionItem
