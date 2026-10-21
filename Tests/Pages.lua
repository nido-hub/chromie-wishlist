-- Exécuter depuis le dossier de l'addon avec Lua 5.1 : lua Tests/Pages.lua
-- Ce fichier n'est pas chargé en jeu. AtlasLoot installé est utilisé en fin de test.
local checks = 0
local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
SlashCmdList = {}
wipe = function(t) for k in pairs(t) do t[k] = nil end end
local faction = "Alliance"
UnitFactionGroup = function() return faction end
GetItemInfo = function() return nil end
assert(loadfile("Core.lua"))("ChromieWishlist")
local CW = ChromieWishlist
CW.db = { language = "fr", classFilter = false }
AtlasLoot_Data, AtlasLoot_TableNames = {}, {}
AtlasLoot_DewDropDown_SubTables = {
    Test = { { "Boss A", "BossA1" }, { "Boss B", "BossB1" } },
}
local entry = { key = "Test", name = "Test", kind = "Submenu" }
AtlasLoot_Data.BossA1 = { { 1, 101 }, Next = "BossA2" }
AtlasLoot_Data.BossA2 = { { 1, 102 }, Next = "BossB1" }
AtlasLoot_Data.BossB1 = { { 1, 201 }, Next = "BossB2" }
AtlasLoot_Data.BossB2 = { { 1, 202 }, Next = "BossB1" }
local refs = CW:GetInstanceTables(entry, 3)
check(#refs == 4, "all pages included once despite cycles and linked bosses")
check(refs[2].label == "Boss A" and refs[3].label == "Boss B", "boss labels retained")
check(refs[4].id == "BossB2", "submenu order retained")
CW.instanceIndex = { entry }
CW:BuildRows("Test", 3)
local items = 0
for _, row in ipairs(CW.rows) do if row.kind == "item" then items = items + 1 end end
check(items == 4, "later-page items visible")
check(CW:FindItemSource(202).tableID == "BossB2", "later-page source found")
CW:SearchLoot("202")
check(#CW.rows == 2 and CW.rows[2].itemID == 202, "later-page item searchable")
check(#CW:GetInstanceTables({ key = "BossA1", kind = "Table" }, 3) == 4,
    "direct tables still follow Next and terminate on cycles")

AtlasLoot_DewDropDown_SubTables.Missing = { { "Missing", "Missing1" } }
check(#CW:GetInstanceTables({ key = "Missing", kind = "Submenu" }, 3) == 1,
    "missing data terminates safely")
AtlasLoot_TableNames.Lazy1, AtlasLoot_TableNames.Lazy2 = { "Lazy" }, { "Lazy" }
AtlasLoot_IsLootTableAvailable = function(id)
    AtlasLoot_Data[id] = id == "Lazy1" and { Next = "Lazy2" } or {}
    return true
end
AtlasLoot_DewDropDown_SubTables.Lazy = { { "Lazy", "Lazy1" } }
check(#CW:GetInstanceTables({ key = "Lazy", kind = "Submenu" }, 3) == 2,
    "load-on-demand tables followed")
AtlasLoot_IsLootTableAvailable = nil

-- Charger les vraies tables du Caveau sans exécuter le reste du module WoW.
local file = assert(io.open("../AtlasLoot_WrathoftheLichKing/wrathofthelichking.lua", "rb"))
local source = file:read("*a")
file:close()
local first = assert(source:find('AtlasLoot_Data["VaultofArchavonArchavon1"]', 1, true))
local last = assert(source:find('AtlasLoot_Data["Naxx80Patchwerk"]', first, true))
AtlasLoot_Data, AtlasLoot_TableNames = {}, {}
local identity = setmetatable({}, { __index = function(_, key) return key end })
local chunk = assert(loadstring(source:sub(first, last - 1), "Vault of Archavon data"))
setfenv(chunk, {
    AtlasLoot_Data = AtlasLoot_Data, LOCALIZED_CLASS_NAMES_MALE = identity,
    AL = identity, BabbleInventory = identity,
})()
for id in pairs(AtlasLoot_Data) do AtlasLoot_TableNames[id] = { id } end
AtlasLoot_DewDropDown_SubTables.Vault = {
    { "Archavon", "VaultofArchavonArchavon1" },
    { "Emalon", "VaultofArchavonEmalon1" },
    { "Koralon", "VaultofArchavonKoralon1_A" },
    { "Toravon", "VaultofArchavonToravon1" },
}
local vault = { key = "Vault", name = "Vault of Archavon", kind = "Submenu" }
CW.instanceIndex = { vault }
for _, side in ipairs({ "Alliance", "Horde" }) do
    faction = side
    for _, mode in ipairs({ 3, 4 }) do
        local pages = CW:GetInstanceTables(vault, mode)
        check(#pages == 31, side .. " mode " .. mode .. ": all 31 pages")
        local counts, ids, expectedItems = {}, {}, 0
        for _, ref in ipairs(pages) do
            check(not ids[ref.id], "unique page: " .. ref.id)
            ids[ref.id] = true
            counts[ref.label] = (counts[ref.label] or 0) + 1
            check((ref.id:find("25Man", 1, true) ~= nil) == (mode == 4), "correct raid size")
            if ref.label == "Koralon" then
                check(ref.id:sub(-2) == (side == "Horde" and "_H" or "_A"), "correct faction")
            end
            for _, item in ipairs(AtlasLoot_Data[ref.id]) do
                if tonumber(item[2]) and item[2] > 0 then expectedItems = expectedItems + 1 end
            end
        end
        check(counts.Archavon == 7 and counts.Emalon == 8 and counts.Koralon == 8 and counts.Toravon == 8,
            "all pages of each boss")
        CW:BuildRows(vault.name, mode)
        local visible = 0
        for _, row in ipairs(CW.rows) do
            if row.kind == "item" then visible = visible + 1 end
        end
        check(visible == expectedItems, "all AtlasLoot items visible with class filter off")
    end
end
print("OK - " .. checks .. " page checks (Lua " .. _VERSION:match("[%d.]+") .. ")")
