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

---@param src table?
function CompletionItem.new(src)
  local self = setmetatable({
    word = (src and src.word) or "",
    abbr = (src and src.abbr) or "",
    menu = (src and src.menu) or "",
    info = (src and src.info) or "",
    kind = (src and src.kind) or "",
    equal = (src and src.equal) or false,
    dup = (src and src.dup) or false,
    empty = (src and src.empty) or false,
    user_data = (src and src.user_data) or "",
    abbr_hlgroup = (src and src.abbr_hlgroup) or "",
    kind_hlgroup = (src and src.kind_hlgroup) or "",
  }, CompletionItem)
  return self
end

---@param a CompletionItem
---@param b CompletionItem
function CompletionItem.__eq(a, b)
  return a.word == b.word
end

return CompletionItem
