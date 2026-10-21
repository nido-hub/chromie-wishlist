-- Exécuter depuis le dossier de l'addon avec Lua 5.1 : lua Tests/Import.lua
-- Ce fichier n'est pas chargé en jeu.
local checks = 0
local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end

local function equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

local function widget(name)
    return setmetatable({ name = name, scripts = {} }, { __index = function(_, key)
        if key == "SetScript" then return function(self, event, fn) self.scripts[event] = fn end end
        if key == "GetName" then return function(self) return self.name end end
        if key == "CreateFontString" then return function() return widget() end end
        if key == "SetText" then return function(self, text) self.text = text end end
        if key == "Show" then return function(self) self.shown = true end end
        if key == "Hide" then return function(self) self.shown = false end end
        return function() end
    end })
end

CreateFrame = function(_, name) return widget(name) end
SlashCmdList = {}
UnitName = function() return "Tester" end
UnitFactionGroup = function() return "Alliance" end
wipe = function(t) for k in pairs(t) do t[k] = nil end end
local messages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) messages[#messages + 1] = text end }
UIDropDownMenu_SetWidth = function() end
UIDropDownMenu_SetText = function(frame, text) frame.text = text end
UIDropDownMenu_Initialize = function(frame, fn) frame.initialize = fn end
UIDropDownMenu_CreateInfo = function() return {} end
local menu = {}
UIDropDownMenu_AddButton = function(info) menu[#menu + 1] = info end
CloseDropDownMenus = function() end
FauxScrollFrame_SetOffset = function(frame, value) frame.offset = value end

assert(loadfile("Core.lua"))("ChromieWishlist")
assert(loadfile("Import.lua"))()
assert(loadfile("UI.lua"))()
local CW = ChromieWishlist
CW.db = { language = "fr", wishlist = {} }
local refreshes = 0
CW.Refresh = function() refreshes = refreshes + 1 end
CW.frame = widget("MainFrame")
CW.scroll = widget("TestScroll")
TestScrollScrollBar = { SetValue = function(_, value) check(value == 0, "scroll resets") end }

AtlasLootWishList = nil
check(#CW:GetAtlasWishlists() == 0, "missing database")
AtlasLootWishList = { Own = false, Shared = { Broken = false } }
check(#CW:GetAtlasWishlists() == 0, "malformed database")
CW:ShowAtlasImport()
check(messages[#messages]:find("Aucune wishlist", 1, true), "empty import message")

local function item(id, source, boss)
    return { 0, id, "icon", "name", boss or "Boss", "", "", source or "Boss|AtlasLoot_Data" }
end
local list = {
    info = { "Raid", { Tester = true }, "icon" },
    item(99), item(100, "Boss25Man|AtlasLoot_Data"), item(100), item("101"),
    item("|cff0070dd|Hitem:102:0:0:0|h[Object]|h|r"), item("s123"),
    item(0), item(-1), item(1.5), false,
    item(103, "Crafting|AtlasLoot_Data", "=q4=|cff0070ddCrafted|r"), item("invalid"),
    [14] = item(104),
}
AtlasLootWishList = {
    Own = {
        Tester = { raid = list, empty = { info = { "Empty" } } },
        Alt = { raid = { info = { "Raid" }, item(200) } },
    },
    Shared = { Friend = { raid = { info = { "Raid" }, item(500) } } },
}
local original = copy(AtlasLootWishList)
AtlasLoot_DewDropDown_SubTables = { Ulduar = { { "Boss 10", "Boss" } } }
AtlasLoot_TableNames = { Boss = { "Boss 10" }, Boss25Man = { "Boss 25" } }
AtlasLoot_Data = { Boss = { item(100), item(101), item(102), item(104) }, Boss25Man = { item(100) } }
CW.instanceIndex = { { name = "Ulduar", key = "Ulduar", kind = "Submenu" } }
CW.db.wishlist["99"] = { priority = 1, instance = "Existing", boss = "Existing boss", tableID = "ExistingTable" }
local existing = copy(CW.db.wishlist["99"])

local lists = CW:GetAtlasWishlists()
check(#lists == 4, "all personal, alt and shared lists discovered")
check(lists[1].owner == "Tester" and lists[2].owner == "Tester", "current character first")
check(lists[3].owner == "Alt" and lists[4].group == "Shared", "alts then shared")
local selection = lists[2]
check(selection.key == "raid", "stable list ordering")
local added, duplicates, invalid = CW:ImportAtlasWishlist(selection)
check(added == 5 and duplicates == 2 and invalid == 6, "import counters including sparse entries")
check(equal(existing, CW.db.wishlist["99"]), "existing priorities and sources preserved")
check(CW.db.wishlist["100"].priority == 3, "default P3")
check(CW.db.wishlist["100"].tableID == "Boss25Man", "original difficulty preserved")
check(CW.db.wishlist["100"].instance == "Ulduar", "source instance resolved")
check(CW.db.wishlist["101"] and CW.db.wishlist["102"], "numeric strings and links imported")
check(CW.db.wishlist["103"].boss == "Crafted", "unknown item retains cleaned AtlasLoot source")
check(CW.db.wishlist["104"], "sparse list entry imported")
check(equal(original, AtlasLootWishList), "AtlasLoot database unchanged")
check(refreshes == 1 and CW.viewMode == "wishlist", "single refresh after batch")
check(CW.scroll.offset == 0, "wishlist scrolled to top")
check(messages[#messages]:find("5 objet(s)", 1, true), "French summary")

added, duplicates, invalid = CW:ImportAtlasWishlist(selection)
check(added == 0 and duplicates == 7 and invalid == 6, "repeat import is idempotent")
added, duplicates, invalid = CW:ImportAtlasWishlist(lists[1])
check(added == 0 and duplicates == 0 and invalid == 0, "empty list import succeeds")
CW.db.language = "en"
added = CW:ImportAtlasWishlist(lists[4])
check(added == 1 and CW.db.wishlist["500"].priority == 3, "shared list import")
check(messages[#messages]:find("1 item(s) added", 1, true), "English summary")
added = CW:ImportAtlasWishlist(lists[3])
check(added == 1 and CW.db.wishlist["200"], "alt list import")
check(equal(original, AtlasLootWishList), "all source lists remain unchanged")

-- Fenêtre, sélection, annulation, confirmation et raccourci /cw import.
SlashCmdList.CHROMIEWISHLIST("import")
check(CW.importFrame.shown and CW.importTitle.text == "Import from AtlasLoot", "slash opens localized picker")
menu = {}
CW.importDropDown:initialize()
check(#menu == 4, "picker contains all lists")
menu[2].func()
check(CW.importSelection.key == "raid" and CW.importSelection.owner == "Tester", "picker selects correct list")
local before = copy(CW.db.wishlist)
CW.importCancel.scripts.OnClick()
check(not CW.importFrame.shown and equal(before, CW.db.wishlist), "cancel does not import")
CW:ShowAtlasImport()
CW.importConfirm.scripts.OnClick()
check(not CW.importFrame.shown, "successful empty import closes picker")
CW:ShowAtlasImport()
AtlasLootWishList.Own.Tester.empty = nil
CW.importConfirm.scripts.OnClick()
check(CW.importFrame.shown, "deleted list keeps picker open")
check(messages[#messages]:find("no longer exists", 1, true), "deleted list message")
check(equal(before, CW.db.wishlist), "deleted list does not modify target")
CW.db = { language = "fr", wishlist = {} }
check(next(CW.db.wishlist) == nil, "new character database is separate")
CW:ImportAtlasWishlist(lists[4])
check(CW.db.wishlist["500"] and not CW.db.wishlist["99"], "import only affects current character")

print("OK - " .. checks .. " checks (Lua 5.1)")
