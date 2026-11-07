-- Run from the addon directory: lua Tests/UI.lua
local widgets = {}
local function widget(name, parent)
    local w = { name = name, parent = parent, scripts = {}, shown = true }
    setmetatable(w, { __index = function(_, key)
        if key == "SetScript" then return function(self, event, fn) self.scripts[event] = fn end end
        if key == "GetName" then return function(self) return self.name end end
        if key == "GetFrameLevel" then return function() return 1 end end
        if key == "SetParent" then return function(self, value) self.parent = value end end
        if key == "CreateFontString" or key == "CreateTexture" then return function(self) return widget(nil, self) end end
        if key == "Show" or key == "Hide" then return function(self) self.shown = key == "Show" end end
        if key == "SetText" then return function(self, value) self.text = value end end
        if key == "GetText" then return function(self) return self.text or "" end end
        if key == "GetFontString" then return function() return widget() end end
        if key == "SetChecked" then return function(self, value) self.checked = value end end
        if key == "GetChecked" then return function(self) return self.checked end end
        return function() end
    end })
    if name then widgets[name] = w; _G[name] = w end
    return w
end
CreateFrame = function(_, name, parent) return widget(name, parent) end
UIParent = widget("UIParent")
Minimap = widget("Minimap")
SlashCmdList = {}
UISpecialFrames = {}
UnitClass = function() return "Mage", "MAGE" end
GetTime = function() return 100 end
GetItemInfo = function() end
PlaySoundFile = function() end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
wipe = function(t) for key in pairs(t) do t[key] = nil end end
CloseDropDownMenus = function() end
for _, name in ipairs({ "UIDropDownMenu_SetWidth", "UIDropDownMenu_SetSelectedValue", "UIDropDownMenu_SetText",
    "UIDropDownMenu_EnableDropDown", "UIDropDownMenu_DisableDropDown", "FauxScrollFrame_Update" }) do
    _G[name] = function() end
end
UIDropDownMenu_Initialize = function(w, fn) w.initialize = fn end
FauxScrollFrame_GetOffset = function() return 0 end
FauxScrollFrame_SetOffset = function() end
assert(loadfile("Core.lua"))("ChromieWishlist")
assert(loadfile("UI.lua"))()
local CW = ChromieWishlist
CW.db = { language = "fr", wishlist = { ["123"] = { priority = 1, sourceChecked = true },
    ["456"] = { priority = 2, sourceChecked = true } }, soundChoice = "raid", sound = true, soundDelay = 0 }
CW:CreateUI()
assert(CW.activeTab == "wishlist", "opens on wishlist")
assert(CW.rowFrames[2].itemID == 123, "wishlist is populated on opening")
CW:SelectTab("sounds")
assert(CW.soundPanel.shown and not CW.lootPanel.shown, "sound settings hide loot rows")
CW:SelectSoundPriority(2)
assert(CW.editSoundPriority == 2, "priority submenu selects separate profile")
CW:SetSoundChoice("alarm", false, 2)
assert(CW:GetSoundProfile(1).soundChoice == "raid", "editing P2 leaves P1 unchanged")
CW.randomChecks.raid:SetChecked(false)
CW.randomChecks.raid.scripts.OnClick(CW.randomChecks.raid)
assert(not CW:GetSoundProfile(2).randomSounds.raid and CW:GetSoundProfile(2).randomSounds.ready,
    "unchecking a default random candidate keeps other candidates")
assert(CW:GetSoundProfile(1).randomSounds == nil, "random selection is scoped to selected priority")
CW:ShowSoundImport(2)
CW.soundFileBox:SetText("second.ogg")
CW.soundImportSave.scripts.OnClick()
assert(CW:GetSoundOption("custom", 2).path == "Interface\\AddOns\\ChromieWishlist\\Media\\second.ogg",
    "dialog saves file in selected priority")
assert(CW:GetSoundProfile(1).customSoundFile == "sound_addon.ogg", "dialog does not overwrite another priority")
CW:SelectTab("wishlist")
CW.wishlistPriority = 2
CW:Refresh()
assert(CW.rowFrames[2].itemID == 456 and not CW.rowFrames[3].shown, "wishlist priority filter hides other priorities")
CW.priorityFilters[0].scripts.OnClick()
assert(CW.rowFrames[2].itemID == 123 and CW.rowFrames[3].itemID == 456, "All button restores every priority")
CW:SelectTab("explore")
assert(CW.exploreTools.shown and not CW.wishlistTools.shown and CW.lootPanel.shown, "explorer has own toolbar")
CW:BuildWishlistRows(); CW:Refresh()
assert(CW.activeTab == "wishlist", "external wishlist command leaves explorer")
CW:SelectTab("sounds")
CW.db.language = "en"
CW:ApplyLanguage()
assert(CW.tabs.sounds.text == "Sounds" and CW.activeTab == "sounds", "language change preserves active settings tab")
CW:SearchLoot("needle")
local searchHeading = CW.rows[1].text
CW:SelectTab("sounds")
CW:SelectTab("explore")
assert(CW.viewMode == "search" and CW.rows[1].text == searchHeading, "returning from sounds preserves search")
CW:SelectTab("wishlist")
CW:SelectTab("explore")
assert(CW.viewMode == "search" and CW.rows[1].text == searchHeading, "returning from wishlist restores search results")
UnitFactionGroup = function() return "Alliance" end
GetInstanceInfo = function() return "Test Dungeon", "party", 1 end
IsInInstance = function() return true end
CW.instanceIndex = { { name = "Test Dungeon", key = "TestBoss", kind = "Table" } }
AtlasLoot_Data = { TestBoss = { { 1, 123 } } }
CW:UpdateZone(true)
CW:SelectTab("wishlist")
CW:SelectTab("explore")
assert(CW.viewMode == "zone" and CW.rows[2].itemID == 123, "current-zone results survive a wishlist round trip")
print("OK - tab navigation, wishlist filters and sound profile UI")
