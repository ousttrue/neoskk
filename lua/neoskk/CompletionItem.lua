local pinyin = require "neoskk.pinyin"
local utf8 = require "neoskk.utf8"
local util = require "neoskk.util"

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

---for test
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

---@param src CompletionItem
---@return CompletionItem
function CompletionItem.copy(src)
  local dst = {}
  for k, v in pairs(src) do
    dst[k] = v
  end
  return dst
end

---@param w string word
---@param item UniHanChar? 単漢字情報
---@param dict UniHanDict
---@return CompletionItem
function CompletionItem.from_word(w, item, dict)
  local menu = " "
  if item then
    menu = dict:get_label(w, item)
  end
  local new_item = {
    word = w,
    abbr = w,
    menu = menu,
    dup = true,
  }
  if item then
    -- info
    if #item.kana > 0 then
      new_item.info = util.join(item.kana, ",")
    end
    if item.xszd then
      new_item.info = (new_item.info or "") .. "\n"
      for _, section in ipairs(item.xszd) do
        new_item.info = new_item.info .. "# " .. section.header .. '\n' .. section.body
      end
    end

    -- abbr
    if item.goma then
      new_item.abbr = new_item.abbr .. " " .. item.goma
    end
    for i, r in ipairs(item.readings) do
      new_item.abbr = new_item.abbr .. (i > 1 and "," or " ")
      if r.pinyin then
        new_item.abbr = new_item.abbr .. (r.zhuyin and r.zhuyin or r.pinyin)
        if r.diao then
          new_item.abbr = new_item.abbr .. ("%d"):format(r.diao)
        end
      end
    end
    if item.annotation then
      new_item.abbr = new_item.abbr .. " " .. item.annotation
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
