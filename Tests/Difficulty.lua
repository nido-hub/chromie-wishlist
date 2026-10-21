-- Exécuter depuis le dossier de l'addon avec Lua 5.1 : lua Tests/Difficulty.lua
-- Ce fichier n'est pas chargé en jeu.
local checks = 0
local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
SlashCmdList = {}
UnitFactionGroup = function() return "Alliance" end
GetTime = function() return 100 end
assert(loadfile("Core.lua"))("ChromieWishlist")
assert(loadfile("UI.lua"))()
local CW = ChromieWishlist
CW.db = { language = "fr", browseDifficulty = 6 }
AtlasLoot_Data, AtlasLoot_TableNames, AtlasLoot_DewDropDown_SubTables = {}, {}, {}

local function instance(key, tables)
    AtlasLoot_DewDropDown_SubTables[key] = {}
    for _, id in ipairs(tables) do
        AtlasLoot_DewDropDown_SubTables[key][#AtlasLoot_DewDropDown_SubTables[key] + 1] = { "", id }
        AtlasLoot_TableNames[id] = { id }
        AtlasLoot_Data[id] = {}
    end
    return { key = key, name = key, kind = "Submenu" }
end
local function modes(entry, expected)
    local values = {}
    for _, mode in ipairs(CW:GetDifficultyOptions(entry)) do values[#values + 1] = mode.value end
    check(table.concat(values, ",") == expected, (entry and entry.key or "none") .. ": " .. expected)
end
local naxx = instance("Naxxramas", { "Patchwerk", "NaxxTrash" })
AtlasLoot_TableNames.Patchwerk25Man = { "Patchwerk" }
modes(naxx, "3,4")
check(CW:ResolveBrowseDifficulty(naxx, 5) == 3, "10 heroic falls back to 10 normal")
check(CW:ResolveBrowseDifficulty(naxx, 6) == 4, "25 heroic falls back to 25 normal")
check(CW:ResolveBrowseDifficulty(naxx, "4") == 4, "valid saved mode retained")
local icc = instance("ICC", { "Marrowgar", "ICCTrash25Man" })
for _, suffix in ipairs({ "25Man", "HEROIC", "25ManHEROIC" }) do
    AtlasLoot_TableNames["Marrowgar" .. suffix] = { "Marrowgar" }
end
modes(icc, "3,4,5,6")
local toc = instance("ToC", { "Beasts_A", "TributeHEROIC_A" })
for _, suffix in ipairs({ "25Man", "HEROIC", "25ManHEROIC" }) do
    AtlasLoot_TableNames["Beasts" .. suffix .. "_A"] = { "Beasts" }
end
modes(toc, "3,4,5,6")
UnitFactionGroup = function() return "Horde" end
for _, suffix in ipairs({ "", "25Man", "HEROIC", "25ManHEROIC" }) do
    AtlasLoot_TableNames["Beasts" .. suffix .. "_H"] = { "Beasts" }
end
modes(toc, "3,4,5,6")
UnitFactionGroup = function() return "Alliance" end

local dungeon = instance("Dungeon", { "FirstBoss", "LastBoss" })
AtlasLoot_Data.LastBoss = nil
AtlasLoot_IsLootTableAvailable = function(id)
    AtlasLoot_Data[id] = {}
    AtlasLoot_Data.LastBossHEROIC = {}
    return true
end
modes(dungeon, "1,2")
check(CW:ResolveBrowseDifficulty(dungeon, 6) == 1, "raid mode replaced for dungeon")
check(CW:GetInstanceTables(dungeon, 2)[2].id == "LastBossHEROIC", "heroic loot resolved from loaded data")
modes(instance("Classic", { "ClassicBoss" }), "1")
modes(nil, "")
local direct = { key = "Onyxia", kind = "Table" }
AtlasLoot_Data.Onyxia = {}
AtlasLoot_TableNames.Onyxia25Man = { "Onyxia" }
modes(direct, "3,4")

CW.BuildRows = function(self, name, difficulty) self.builtDifficulty = difficulty; return true end
CW.UpdateBrowserControls, CW.Refresh = nil, nil
CW:BrowseInstance(naxx, 6)
check(CW.db.browseDifficulty == 4 and CW.builtDifficulty == 4, "browse normalizes before loading loot")

UIDropDownMenu_SetSelectedValue = function(frame, value) frame.value = value end
UIDropDownMenu_SetText = function(frame, text) frame.text = text end
UIDropDownMenu_EnableDropDown = function(frame) frame.enabled = true end
UIDropDownMenu_DisableDropDown = function(frame) frame.enabled = false end
assert(loadfile("UI.lua"))()
CW.difficultyDropDown = {}
CW.browsedEntry = nil
CW:UpdateBrowserControls()
check(not CW.difficultyDropDown.enabled and CW.difficultyDropDown.value == nil, "disabled before choosing instance")
CW.browsedEntry = naxx
CW:UpdateBrowserControls()
check(CW.difficultyDropDown.enabled and CW.difficultyDropDown.text == "25 joueurs", "selected valid raid mode shown")
CW.db.language = "en"
CW:UpdateBrowserControls()
check(CW.difficultyDropDown.text == "25 player", "mode label translated")
print("OK - " .. checks .. " difficulty checks (Lua " .. _VERSION:match("[%d.]+") .. ")")
