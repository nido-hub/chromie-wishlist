local ADDON_NAME = ...

local CW = _G.ChromieWishlist or {}
_G.ChromieWishlist = CW
CW.name = ADDON_NAME
CW.version = "1.2.0"
CW.rows = {}
CW.instanceIndex = {}

CW.soundOptions = {
    { key = "custom", labelKey = "soundCustom", path = "Interface\\AddOns\\ChromieWishlist\\Media\\sound_addon.ogg" },
    { key = "raid", labelKey = "soundRaid", path = "Sound\\Interface\\RaidWarning.wav" },
    { key = "ready", labelKey = "soundReady", path = "Sound\\Interface\\ReadyCheck.wav" },
    { key = "message", labelKey = "soundMessage", path = "Sound\\Interface\\TellMessage.wav" },
    { key = "alarm", labelKey = "soundAlarm", path = "Sound\\Interface\\AlarmClockWarning3.wav" },
}

CW.soundDelayOptions = { 0, 1, 2, 3, 5, 10, 15, 30, 60 }

CW.translations = {
    fr = {
        priorityHelp = "Bouton priorite : P3 > P2 > P1 > retirer. P1 est la priorite maximale.",
        sound = "SON :", active = "Actif", classFilter = "Filtre %s",
        browse = "PARCOURIR :", chooseInstance = "Choisir une instance",
        wishlist = "Wishlist", currentZone = "Zone actuelle", search = "RECHERCHE :",
        searchButton = "Chercher", item = "OBJET", source = "INSTANCE / BOSS", priority = "PRIORITÉ",
        add = "Ajouter", noClassItem = "Aucun objet utilisable pour votre classe.",
        emptyWishlist = "La wishlist est vide.", unknownSource = "Source inconnue",
        searchTitle = "Recherche", noResult = "Aucun objet trouvé avec les filtres actuels.",
        searchPrompt = "Entrez un nom d'objet ou un ID.", tooltipSource = "Source : ",
        filterTitle = "Filtre de classe",
        filterOnTip = "Activé : objets adaptés à votre classe et à ses caractéristiques.",
        filterOffTip = "Désactivé : tous les objets de l'instance.",
        leftClick = "Clic gauche : ouvrir / fermer", rightClick = "Clic droit : afficher la wishlist",
        drag = "Glisser : déplacer le bouton",
        soundCustom = "Personnalisé", soundRaid = "Alerte de raid", soundReady = "Vérification",
        soundMessage = "Message", soundAlarm = "Alarme",
        soundImport = "Importer un son...", soundTest = "Tester", soundSave = "Utiliser ce son",
        soundImportHelp = "Placez votre fichier .ogg, .wav ou .mp3 dans Interface\\AddOns\\ChromieWishlist\\Media, puis saisissez son nom ci-dessous. Pour un nouveau fichier, redémarrez complètement WoW. L'addon ne peut ni copier ni vérifier le fichier.",
        soundFile = "Fichier dans Media (ex. : mon_alerte.ogg) :",
        soundFileInvalid = "Nom invalide : indiquez un fichier .ogg, .wav ou .mp3 relatif au dossier Media, sans chemin absolu ni '..'.",
        soundImported = "Son sélectionné : %s. Si aucun son ne joue, vérifiez le fichier et redémarrez WoW.",
        soundDefault = "Son d'origine",
        soundDelay = "Délai entre sons :", soundDelayNone = "Sans délai", soundDelaySeconds = "%d s",
        mode10 = "10 joueurs", mode25 = "25 joueurs", mode10h = "10 héroïque", mode25h = "25 héroïque",
        importAtlas = "Importer depuis AtlasLoot", importButton = "Importer", cancel = "Annuler",
        importHelp = "Choisissez une liste. Nouveaux objets en P3 ; priorités existantes conservées. AtlasLoot ne sera pas modifié.",
        importShared = "Partagée", importUnavailable = "Aucune wishlist AtlasLoot disponible. Créez d'abord une liste dans AtlasLoot.",
        importMissing = "Cette liste AtlasLoot n'existe plus. Rouvrez le menu d'import.",
        importResult = "Import « %s » : %d objet(s) ajouté(s), %d doublon(s) ignoré(s), %d entrée(s) invalide(s) ignorée(s).",
    },
    en = {
        priorityHelp = "Priority button: P3 > P2 > P1 > remove. P1 is the highest priority.",
        sound = "SOUND:", active = "Enabled", classFilter = "%s filter",
        browse = "BROWSE:", chooseInstance = "Choose an instance",
        wishlist = "Wishlist", currentZone = "Current zone", search = "SEARCH:",
        searchButton = "Search", item = "ITEM", source = "INSTANCE / BOSS", priority = "PRIORITY",
        add = "Add", noClassItem = "No usable item for your class.",
        emptyWishlist = "The wishlist is empty.", unknownSource = "Unknown source",
        searchTitle = "Search", noResult = "No item found with the current filters.",
        searchPrompt = "Enter an item name or ID.", tooltipSource = "Source: ",
        filterTitle = "Class filter",
        filterOnTip = "Enabled: items suited to your class and relevant attributes.",
        filterOffTip = "Disabled: every item from the instance.",
        leftClick = "Left-click: open / close", rightClick = "Right-click: show wishlist",
        drag = "Drag: move the button",
        soundCustom = "Custom", soundRaid = "Raid warning", soundReady = "Ready check",
        soundMessage = "Message", soundAlarm = "Alarm",
        soundImport = "Import a sound...", soundTest = "Test", soundSave = "Use this sound",
        soundImportHelp = "Place your .ogg, .wav or .mp3 file in Interface\\AddOns\\ChromieWishlist\\Media, then enter its name below. Fully restart WoW for a new file. The addon cannot copy or verify the file.",
        soundFile = "File in Media (e.g. my_alert.ogg):",
        soundFileInvalid = "Invalid name: enter an .ogg, .wav or .mp3 file relative to Media, without an absolute path or '..'.",
        soundImported = "Selected sound: %s. If nothing plays, check the file and restart WoW.",
        soundDefault = "Original sound",
        soundDelay = "Sound interval:", soundDelayNone = "No delay", soundDelaySeconds = "%d s",
        mode10 = "10 player", mode25 = "25 player", mode10h = "10 heroic", mode25h = "25 heroic",
        importAtlas = "Import from AtlasLoot", importButton = "Import", cancel = "Cancel",
        importHelp = "Choose a list. New items use P3; existing priorities are preserved. AtlasLoot will not be modified.",
        importShared = "Shared", importUnavailable = "No AtlasLoot wishlist available. Create a list in AtlasLoot first.",
        importMissing = "This AtlasLoot list no longer exists. Reopen the import menu.",
        importResult = "Import '%s': %d item(s) added, %d duplicate(s) skipped, %d invalid entry/entries skipped.",
    },
}

local defaults = {
    storageVersion = 2,
    wishlist = {},
    autoOpen = false,
    sound = true,
    soundChoice = "custom",
    customSoundFile = "sound_addon.ogg",
    soundDelay = 0,
    classFilter = true,
    statFilter = true,
    browseDifficulty = 3,
    minimapAngle = 225,
    language = "fr",
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
}

local currency = {
    [29434] = true, [40752] = true, [40753] = true, [43228] = true,
    [44990] = true, [45624] = true, [47241] = true, [49426] = true,
}

-- Sous-types d'équipement autorisés par classe. Les libellés anglais sont
-- traduits plus bas avec LibBabble-Inventory, donc cela fonctionne aussi avec
-- un client frFR. Cette méthode évite IsUsableItem, peu fiable sur certains
-- cores privés 3.3.5 (il peut renvoyer faux pour tous les objets AtlasLoot).
local classProficiencies = {
    DRUID = {
        "Cloth", "Leather", "Dagger", "Fist Weapon", "Mace", "Polearm", "Staff", "Held in Off-Hand", "Idol",
    },
    MAGE = {
        "Cloth", "Dagger", "Sword", "Staff", "Wand", "Held in Off-Hand",
    },
    PALADIN = {
        "Cloth", "Leather", "Mail", "Plate", "Axe", "Mace", "Polearm", "Sword", "Shield", "Held in Off-Hand", "Libram",
    },
    PRIEST = {
        "Cloth", "Dagger", "Mace", "Staff", "Wand", "Held in Off-Hand",
    },
    ROGUE = {
        "Cloth", "Leather", "Axe", "Bow", "Crossbow", "Dagger", "Fist Weapon", "Gun", "Mace", "Sword", "Thrown",
    },
    HUNTER = {
        "Cloth", "Leather", "Mail", "Axe", "Bow", "Crossbow", "Dagger", "Fist Weapon", "Gun", "Polearm", "Staff", "Sword",
    },
    SHAMAN = {
        "Cloth", "Leather", "Mail", "Axe", "Dagger", "Fist Weapon", "Mace", "Shield", "Staff", "Held in Off-Hand", "Totem",
    },
    WARLOCK = {
        "Cloth", "Dagger", "Sword", "Staff", "Wand", "Held in Off-Hand",
    },
    WARRIOR = {
        "Cloth", "Leather", "Mail", "Plate", "Axe", "Bow", "Crossbow", "Dagger", "Fist Weapon", "Gun", "Mace", "Polearm", "Shield", "Staff", "Sword", "Thrown",
    },
    DEATHKNIGHT = {
        "Cloth", "Leather", "Mail", "Plate", "Axe", "Mace", "Polearm", "Sword", "Sigil", "Sigils",
    },
}

local universalSlots = {
    INVTYPE_NECK = true,
    INVTYPE_CLOAK = true,
    INVTYPE_FINGER = true,
    INVTYPE_TRINKET = true,
}

local pluralInventoryKeys = {
    Axe = "Axes", Bow = "Bows", Crossbow = "Crossbows", Dagger = "Daggers",
    ["Fist Weapon"] = "Fist Weapons", Gun = "Guns", Mace = "Maces",
    Polearm = "Polearms", Shield = "Shields", Staff = "Staves",
    Sword = "Swords", Wand = "Wands", Idol = "Idols", Libram = "Librams",
    Totem = "Totems", Sigil = "Sigils",
}

local physicalCombatStats = {
    "ITEM_MOD_ATTACK_POWER_SHORT",
    "ITEM_MOD_RANGED_ATTACK_POWER_SHORT",
    "ITEM_MOD_FERAL_ATTACK_POWER_SHORT",
    "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT",
    "ITEM_MOD_EXPERTISE_RATING_SHORT",
    "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT",
    "ITEM_MOD_DODGE_RATING_SHORT",
    "ITEM_MOD_PARRY_RATING_SHORT",
    "ITEM_MOD_BLOCK_RATING_SHORT",
    "ITEM_MOD_BLOCK_VALUE_SHORT",
}

local pureCasterClasses = { MAGE = true, PRIEST = true, WARLOCK = true }

local function CopyDefaults(source, target)
    for key, value in pairs(source) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                CopyDefaults(value, target[key])
            else
                target[key] = value
            end
        end
    end
end

function CW:Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Chromie Wishlist|r : " .. tostring(text))
end

function CW:Text(key, ...)
    local language = self.db and self.db.language or "fr"
    local text = (self.translations[language] and self.translations[language][key])
        or self.translations.fr[key] or key
    if select("#", ...) > 0 then return string.format(text, ...) end
    return text
end

function CW:GetSoundLabel(option)
    return self:Text((option and option.labelKey) or "soundCustom")
end

function CW:GetSoundOption(key)
    key = key or (self.db and self.db.soundChoice) or "custom"
    for _, option in ipairs(self.soundOptions) do
        if option.key == key then
            if key == "custom" then
                local file = self:NormalizeSoundFile(self.db and self.db.customSoundFile)
                return { key = option.key, labelKey = option.labelKey,
                    path = "Interface\\AddOns\\ChromieWishlist\\Media\\" .. (file or "sound_addon.ogg") }
            end
            return option
        end
    end
    return self:GetSoundOption("custom")
end

-- WoW cannot browse, copy or check local files. Only store a Media-relative path.
function CW:NormalizeSoundFile(value)
    if type(value) ~= "string" then return nil end
    local file = value:gsub("^%s+", ""):gsub("%s+$", "")
    file = file:gsub("/", "\\")
    if file == "" or #file > 240 or file:find("[%c:*?\"<>|]")
        or file:sub(1, 1) == "\\" or file:find("..", 1, true)
        or file:find("\\\\", 1, true) then return nil end
    for part in file:gmatch("[^\\]+") do
        if part == "." or part:match("[%.%s]$") then return nil end
    end
    local extension = file:match("%.([^%.\\]+)$")
    extension = extension and extension:lower()
    if extension ~= "ogg" and extension ~= "wav" and extension ~= "mp3" then return nil end
    return file
end

function CW:PreviewSoundFile(value)
    local file = self:NormalizeSoundFile(value)
    if not file then self:Print(self:Text("soundFileInvalid")); return false end
    PlaySoundFile("Interface\\AddOns\\ChromieWishlist\\Media\\" .. file)
    return true
end

function CW:ImportSoundFile(value)
    local file = self:NormalizeSoundFile(value)
    if not file then self:Print(self:Text("soundFileInvalid")); return false end
    self.db.customSoundFile = file
    self:SetSoundChoice("custom", true)
    self:Print(self:Text("soundImported", file))
    return true
end

function CW:PlayAlertSound(force)
    if not force and (not self.db or not self.db.sound) then return end
    local now = GetTime()
    if not force then
        local delay = math.max(0, tonumber(self.db.soundDelay) or 0)
        if self.lastAlertSoundTime and now - self.lastAlertSoundTime < delay then return end
    end
    local option = self:GetSoundOption()
    if option and option.path then
        PlaySoundFile(option.path)
        if not force then self.lastAlertSoundTime = now end
    end
end

function CW:GetSoundDelayLabel(delay)
    if delay == 0 then return self:Text("soundDelayNone") end
    return self:Text("soundDelaySeconds", delay)
end

function CW:SetSoundChoice(key, preview)
    local option = self:GetSoundOption(key)
    self.db.soundChoice = option.key
    if self.UpdateSoundControls then self:UpdateSoundControls() end
    if preview then PlaySoundFile(option.path) end
end

local function Normalize(text)
    text = tostring(text or ""):lower()
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("[%s%p]+", "")
    return text
end

local function ItemID(value)
    if type(value) == "number" then return value end
    if type(value) ~= "string" then return nil end
    return tonumber(value:match("item:(%d+)") or value:match("^%s*(%d+)"))
end
CW.ItemID = ItemID

function CW:GetPriority(itemID)
    local saved = self.db and self.db.wishlist[tostring(itemID)]
    if type(saved) == "table" then return tonumber(saved.priority) or 0 end
    return tonumber(saved) or 0
end

function CW:SetPriority(itemID, priority, source)
    itemID = tonumber(itemID)
    priority = tonumber(priority) or 0
    if not itemID then return end
    if priority > 0 then
        local old = self.db.wishlist[tostring(itemID)]
        local saved = type(old) == "table" and old or {}
        saved.priority = math.min(3, priority)
        if source then
            saved.instance = source.instance or saved.instance
            saved.boss = source.boss or saved.boss
            saved.tableID = source.tableID or saved.tableID
            saved.sourceChecked = true
        end
        self.db.wishlist[tostring(itemID)] = saved
    else
        self.db.wishlist[tostring(itemID)] = nil
    end
    if self.Refresh then self:Refresh() end
end

function CW:CyclePriority(itemID, source)
    local current = self:GetPriority(itemID)
    local nextPriority = current == 0 and 3 or current == 3 and 2 or current == 2 and 1 or 0
    self:SetPriority(itemID, nextPriority, source)
end

-- Recherche les entrées d'instances dans le menu localisé d'AtlasLoot.
local function IndexAtlasNode(node, index, seen, expansion)
    if type(node) ~= "table" or seen[node] then return end
    seen[node] = true
    if type(node[1]) == "string" and type(node[2]) == "string"
       and (node[3] == "Table" or node[3] == "Submenu") then
        index[#index + 1] = { name = node[1], key = node[2], kind = node[3], expansion = expansion }
        return
    end
    for _, child in pairs(node) do IndexAtlasNode(child, index, seen, expansion) end
end

function CW:BuildInstanceIndex()
    wipe(self.instanceIndex)
    if not AtlasLoot_DewDropDown then return end
    -- Les trois premières sections sont les instances Classic, BC et WotLK.
    for section = 1, 3 do
        IndexAtlasNode(AtlasLoot_DewDropDown[section], self.instanceIndex, {}, section)
    end
    table.sort(self.instanceIndex, function(a, b)
        if a.expansion ~= b.expansion then return a.expansion < b.expansion end
        return tostring(a.name) < tostring(b.name)
    end)
end

function CW:GetInstancesByExpansion(expansion)
    local result = {}
    for _, entry in ipairs(self.instanceIndex) do
        if entry.expansion == expansion then result[#result + 1] = entry end
    end
    return result
end

function CW:BuildClassFilter()
    self.allowedSubTypes = {}
    self.allowHeldInOffHand = false
    local _, class = UnitClass("player")
    self.playerClass = class
    local inventory
    if AtlasLoot_GetLocaleLibBabble then
        inventory = AtlasLoot_GetLocaleLibBabble("LibBabble-Inventory-3.0")
    end
    for _, key in ipairs(classProficiencies[class] or {}) do
        self.allowedSubTypes[key] = true
        if inventory and inventory[key] then self.allowedSubTypes[inventory[key]] = true end
        local plural = pluralInventoryKeys[key]
        if plural then
            self.allowedSubTypes[plural] = true
            if inventory and inventory[plural] then self.allowedSubTypes[inventory[plural]] = true end
        end
        if key == "Held in Off-Hand" then self.allowHeldInOffHand = true end
    end
    -- Plusieurs versions de LibBabble utilisent le singulier pour le sigil.
    if inventory and inventory["Sigils"] then self.allowedSubTypes[inventory["Sigils"]] = true end
end

local function SumStats(stats, keys)
    local total = 0
    for _, key in ipairs(keys) do total = total + (tonumber(stats[key]) or 0) end
    return total
end

function CW:IsStatRelevant(link)
    if not self.db.statFilter or not pureCasterClasses[self.playerClass] then return true end
    if not GetItemStats or not link then return true end
    local stats = GetItemStats(link, {})
    if type(stats) ~= "table" then return true end

    local strength = tonumber(stats["ITEM_MOD_STRENGTH_SHORT"]) or 0
    local agility = tonumber(stats["ITEM_MOD_AGILITY_SHORT"]) or 0
    local intellect = tonumber(stats["ITEM_MOD_INTELLECT_SHORT"]) or 0
    local physicalCombat = SumStats(stats, physicalCombatStats)

    -- AP, pénétration d'armure, expertise et statistiques de tank ne sont
    -- jamais pertinentes pour un mage/prêtre/démoniste.
    if physicalCombat > 0 then return false end
    -- Force ou Agilité seules signalent un objet physique. L'exception couvre
    -- les objets « toutes les caractéristiques » (+For/+Agi/+Int ensemble).
    if strength > 0 or agility > 0 then
        return strength > 0 and agility > 0 and intellect > 0
    end
    return true
end

function CW:IsAllowedSubType(itemSubType)
    if not itemSubType or not self.allowedSubTypes then return false end
    if self.allowedSubTypes[itemSubType] then return true end
    local lowerSubType = itemSubType:lower()
    for allowed in pairs(self.allowedSubTypes) do
        local lowerAllowed = tostring(allowed):lower()
        -- GetItemInfo renvoie par exemple "One-Handed Swords", tandis que
        -- LibBabble fournit "Sword". La comparaison partielle couvre les
        -- variantes une main/deux mains et leurs traductions.
        if #lowerAllowed >= 4 and (lowerSubType:find(lowerAllowed, 1, true)
           or lowerAllowed:find(lowerSubType, 1, true)) then
            return true
        end
    end
    return false
end

function CW:FindInstance(name)
    local wanted = Normalize(name)
    local best, score
    for _, entry in ipairs(self.instanceIndex) do
        local candidate = Normalize(entry.name)
        local value = 0
        if candidate == wanted then
            value = 10000
        elseif candidate:find(wanted, 1, true) or wanted:find(candidate, 1, true) then
            value = math.min(#candidate, #wanted)
        end
        if value > 0 and (not score or value > score) then best, score = entry, value end
    end
    return best
end

local function EnsureTable(tableID)
    if AtlasLoot_Data and AtlasLoot_Data[tableID] then return true end
    if AtlasLoot_IsLootTableAvailable and AtlasLoot_TableNames and AtlasLoot_TableNames[tableID] then
        return AtlasLoot_IsLootTableAvailable(tableID)
    end
    return false
end

local function DifficultyVariant(tableID, difficulty)
    local suffix = ({ [4] = "25Man", [5] = "HEROIC", [6] = "25ManHEROIC" })[difficulty]
    if not suffix then return tableID end
    local base, faction = tableID:match("^(.-)(_[AH])$")
    local candidate = base and (base .. suffix .. faction) or (tableID .. suffix)
    if AtlasLoot_TableNames and AtlasLoot_TableNames[candidate] then return candidate end
    return tableID
end

local function FactionVariant(tableID)
    local faction = UnitFactionGroup("player") == "Horde" and "_H" or "_A"
    if tableID:match("_[AH]$") then
        local candidate = tableID:gsub("_[AH]$", faction)
        if AtlasLoot_TableNames and AtlasLoot_TableNames[candidate] then return candidate end
    end
    return tableID
end

function CW:GetInstanceTables(entry, difficulty)
    local result = {}
    if not entry then return result end
    if entry.kind == "Submenu" and AtlasLoot_DewDropDown_SubTables then
        local submenu = AtlasLoot_DewDropDown_SubTables[entry.key]
        for _, data in ipairs(submenu or {}) do
            local tableID = FactionVariant(data[2])
            tableID = DifficultyVariant(tableID, difficulty)
            result[#result + 1] = { id = tableID, label = data[1] }
        end
    else
        local tableID, visited = entry.key, {}
        while tableID and not visited[tableID] do
            visited[tableID] = true
            tableID = DifficultyVariant(FactionVariant(tableID), difficulty)
            result[#result + 1] = { id = tableID }
            if not EnsureTable(tableID) then break end
            local data = AtlasLoot_Data[tableID]
            tableID = data and data.Next
        end
    end
    return result
end

-- Filtre par maîtrises de classe, sans examiner les caractéristiques : toutes
-- les spécialisations restent donc possibles.
function CW:IsClassItem(itemID)
    if not self.db.classFilter or self:GetPriority(itemID) > 0 then return true end
    if currency[itemID] then return false end
    local name, link, quality, _, _, itemType, itemSubType, _, equipLoc = GetItemInfo(itemID)
    if not name then
        if self.cacheTooltip then
            self.cacheTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            self.cacheTooltip:SetHyperlink("item:" .. itemID .. ":0:0:0:0:0:0:0")
        end
        return true -- affiché provisoirement pendant la mise en cache
    end
    if equipLoc and equipLoc ~= "" then
        local classAllowed
        if universalSlots[equipLoc] then
            classAllowed = true
        elseif equipLoc == "INVTYPE_HOLDABLE" then
            classAllowed = self.allowHeldInOffHand
        else
            classAllowed = self:IsAllowedSubType(itemSubType)
        end
        return classAllowed and self:IsStatRelevant(link or ("item:" .. itemID))
    end
    -- Les jetons de tier n'ont pas d'emplacement équipé. Leur tooltip indique
    -- toutefois les classes autorisées : on respecte cette restriction.
    if self.cacheTooltip and ITEM_CLASSES_ALLOWED then
        self.cacheTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        self.cacheTooltip:SetHyperlink(link or ("item:" .. itemID))
        local prefix = ITEM_CLASSES_ALLOWED:gsub("%%s", "")
        local localizedClass = UnitClass("player")
        for line = 1, self.cacheTooltip:NumLines() do
            local region = _G["ChromieWishlistCacheTooltipTextLeft" .. line]
            local text = region and region:GetText()
            if text and prefix ~= "" and text:find(prefix, 1, true) then
                return text:find(localizedClass, 1, true) and true or false
            end
        end
    end
    -- Garde les jetons épiques/légendaires (souvent sans emplacement), élimine
    -- les monnaies, recettes et objets ordinaires sans rapport avec la classe.
    return (quality or 0) >= 4 and itemType ~= TRADE_GOODS and itemType ~= RECIPE
end

local function BossName(tableID, fallback)
    if fallback and fallback ~= "" then return fallback end
    if AtlasLoot_TableNames and AtlasLoot_TableNames[tableID] then
        return AtlasLoot_TableNames[tableID][1]
    end
    return tableID
end

function CW:BuildRows(instanceName, difficulty)
    wipe(self.rows)
    local entry = self:FindInstance(instanceName)
    self.currentEntry = entry
    self.currentInstance = instanceName
    self.currentDifficulty = difficulty
    if not entry then return false end

    for _, ref in ipairs(self:GetInstanceTables(entry, difficulty)) do
        if EnsureTable(ref.id) then
            local boss = BossName(ref.id, ref.label)
            local items, duplicate = {}, {}
            for _, data in ipairs(AtlasLoot_Data[ref.id] or {}) do
                local itemID = tonumber(data[2])
                if itemID and itemID > 0 and not duplicate[itemID] and self:IsClassItem(itemID) then
                    duplicate[itemID] = true
                    items[#items + 1] = {
                        kind = "item", itemID = itemID, boss = boss,
                        instance = instanceName, tableID = ref.id, raw = data,
                    }
                end
            end
            self.rows[#self.rows + 1] = { kind = "boss", text = boss }
            if #items == 0 then
            self.rows[#self.rows + 1] = { kind = "empty", text = self:Text("noClassItem") }
            else
                for _, row in ipairs(items) do self.rows[#self.rows + 1] = row end
            end
        end
    end
    return true
end

local function SearchableItemText(itemID, raw)
    local name = GetItemInfo(itemID)
    local text = name or (raw and raw[4]) or ""
    text = tostring(text):gsub("=%a%d=", ""):gsub("#%w+#", "")
    return text:lower()
end

function CW:SearchLoot(query)
    query = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then self:Print(self:Text("searchPrompt")); return end
    local needle = query:lower()
    local numericID = tonumber(query)
    local results, seen = {}, {}

    for _, entry in ipairs(self.instanceIndex) do
        for _, difficulty in ipairs({ 3, 4, 5, 6 }) do
            for _, ref in ipairs(self:GetInstanceTables(entry, difficulty)) do
                if EnsureTable(ref.id) then
                    local boss = BossName(ref.id, ref.label)
                    for _, data in ipairs(AtlasLoot_Data[ref.id] or {}) do
                        local itemID = tonumber(data[2])
                        local key = itemID and (itemID .. "|" .. entry.key .. "|" .. boss)
                        if itemID and itemID > 0 and not seen[key]
                           and (numericID == itemID or SearchableItemText(itemID, data):find(needle, 1, true))
                           and self:IsClassItem(itemID) then
                            seen[key] = true
                            results[#results + 1] = {
                                kind = "item", itemID = itemID,
                                instance = entry.name, boss = boss, tableID = ref.id, raw = data,
                            }
                        end
                    end
                end
            end
        end
    end

    table.sort(results, function(a, b)
        if a.instance ~= b.instance then return tostring(a.instance) < tostring(b.instance) end
        if a.boss ~= b.boss then return tostring(a.boss) < tostring(b.boss) end
        return a.itemID < b.itemID
    end)
    wipe(self.rows)
    self.viewMode = "search"
    self.searchQuery = query
    self.rows[#self.rows + 1] = { kind = "boss", text = self:Text("searchTitle") .. " : " .. query .. " (" .. #results .. ")" }
    if #results == 0 then
        self.rows[#self.rows + 1] = { kind = "empty", text = self:Text("noResult") }
    else
        for _, row in ipairs(results) do self.rows[#self.rows + 1] = row end
    end
    if self.SetTitle then self:SetTitle(self:Text("searchTitle")) end
    if self.Refresh then self:Refresh() end
    if self.frame then self.frame:Show() end
end

function CW:FindItemSource(wantedID, preferredTableID)
    wantedID = tonumber(wantedID)
    if not wantedID then return nil end
    for _, entry in ipairs(self.instanceIndex) do
        for _, difficulty in ipairs({ 3, 4, 5, 6 }) do
            for _, ref in ipairs(self:GetInstanceTables(entry, difficulty)) do
                if (not preferredTableID or ref.id == preferredTableID) and EnsureTable(ref.id) then
                    for _, data in ipairs(AtlasLoot_Data[ref.id] or {}) do
                        if tonumber(data[2]) == wantedID then
                            return {
                                instance = entry.name,
                                boss = BossName(ref.id, ref.label),
                                tableID = ref.id,
                            }
                        end
                    end
                end
            end
        end
    end
end

function CW:BrowseInstance(entry, difficulty)
    if not entry then return end
    difficulty = tonumber(difficulty) or self.db.browseDifficulty or 3
    self.db.browseDifficulty = difficulty
    self.browsedEntry = entry
    self.currentInstance = nil
    if self:BuildRows(entry.name, difficulty) then
        self.viewMode = "browse"
        self.browsedEntry = entry
        self.cacheRefreshUntil = GetTime() + 8
        self.cacheRefreshAt = GetTime() + 1.5
        if self.SetTitle then self:SetTitle(entry.name) end
        if self.UpdateBrowserControls then self:UpdateBrowserControls() end
        if self.Refresh then self:Refresh() end
        if self.frame then self.frame:Show() end
    end
end

function CW:BuildWishlistRows()
    self.viewMode = "wishlist"
    self.cacheRefreshUntil = nil
    wipe(self.rows)
    self.rows[#self.rows + 1] = { kind = "boss", text = self:Text("wishlist") }
    local list = {}
    for id, saved in pairs(self.db.wishlist) do
        local priority = type(saved) == "table" and saved.priority or saved
        if type(saved) ~= "table" or (not saved.instance and not saved.sourceChecked) then
            local source = self:FindItemSource(id)
            saved = type(saved) == "table" and saved or { priority = tonumber(priority) or 3 }
            if source then
                saved.instance, saved.boss, saved.tableID = source.instance, source.boss, source.tableID
            end
            saved.sourceChecked = true
            self.db.wishlist[tostring(id)] = saved
        end
        list[#list + 1] = {
            itemID = tonumber(id), priority = tonumber(priority) or 3,
            instance = type(saved) == "table" and saved.instance or nil,
            boss = type(saved) == "table" and saved.boss or nil,
            tableID = type(saved) == "table" and saved.tableID or nil,
        }
    end
    table.sort(list, function(a, b)
        if a.priority ~= b.priority then return a.priority < b.priority end
        return a.itemID < b.itemID
    end)
    if #list == 0 then
        self.rows[#self.rows + 1] = { kind = "empty", text = self:Text("emptyWishlist") }
    else
        for _, item in ipairs(list) do
            self.rows[#self.rows + 1] = {
                kind = "item", itemID = item.itemID,
                instance = item.instance,
                boss = item.boss or self:Text("unknownSource"),
                tableID = item.tableID,
            }
        end
    end
end

function CW:RefreshActiveLoot()
    if self.viewMode == "browse" and self.browsedEntry then
        self:BrowseInstance(self.browsedEntry, self.db.browseDifficulty)
    elseif self.viewMode == "zone" then
        self.currentInstance = nil
        self:UpdateZone(true)
    elseif self.viewMode == "search" and self.searchQuery then
        self:SearchLoot(self.searchQuery)
    end
end

function CW:Alert(itemID, link, masterLink)
    itemID = tonumber(itemID)
    if not itemID or self:GetPriority(itemID) == 0 then return end
    link = link or select(2, GetItemInfo(itemID)) or ("objet " .. itemID)
    local message = "WISHLIST P" .. self:GetPriority(itemID) .. " : " .. link
    self:Print(message)
    if RaidNotice_AddMessage and RaidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
    end
    self:PlayAlertSound(false)
end

function CW:CheckLink(link, masterLink)
    local id = ItemID(link)
    if id then self:Alert(id, link, masterLink) end
end

function CW:ScanMessageLinks(message, masterLink)
    if type(message) ~= "string" then return end
    local found = false
    for link in message:gmatch("(|c%x+|Hitem:.-|h%[.-%]|h|r)") do
        found = true
        self:CheckLink(link, masterLink)
    end
    -- Certains addons de master loot envoient un lien sans code couleur.
    if not found then
        for link in message:gmatch("(|Hitem:.-|h%[.-%]|h)") do self:CheckLink(link, masterLink) end
    end
end

local function ShortName(name)
    if type(name) ~= "string" then return nil end
    return name:match("^([^-]+)"):lower()
end

function CW:IsMasterLooterSender(sender)
    local senderName = ShortName(sender)
    if not senderName or not GetLootMethod then return false end
    local method, partyMaster, raidMaster = GetLootMethod()
    if method ~= "master" then return false end

    local masterName
    if raidMaster and raidMaster > 0 then
        masterName = UnitName("raid" .. raidMaster)
    end
    -- Repli fiable pour les cores où raidMaster n'est pas correctement rempli.
    if not masterName and GetNumRaidMembers and GetRaidRosterInfo then
        for index = 1, GetNumRaidMembers() do
            local name, _, _, _, _, _, _, _, _, _, isML = GetRaidRosterInfo(index)
            if isML then masterName = name; break end
        end
    end
    if not masterName and partyMaster ~= nil then
        if partyMaster == 0 then masterName = UnitName("player")
        elseif partyMaster > 0 then masterName = UnitName("party" .. partyMaster) end
    end
    return ShortName(masterName) == senderName
end

function CW:ScanLootWindow()
    if not GetNumLootItems or not GetLootSlotLink then return end
    for slot = 1, GetNumLootItems() do self:CheckLink(GetLootSlotLink(slot)) end
end

function CW:UpdateZone(force)
    local name, instanceType, difficulty = GetInstanceInfo()
    local inside = IsInInstance and select(1, IsInInstance())
    if not inside or (instanceType ~= "party" and instanceType ~= "raid") then return end
    if not force and not self.db.autoOpen then return end
    if not force and self.currentInstance == name and self.currentDifficulty == difficulty then return end
    if self:BuildRows(name, difficulty) then
        self.viewMode = "zone"
        self.browsedEntry = nil
        self.cacheRefreshUntil = GetTime() + 8
        self.cacheRefreshAt = GetTime() + 1.5
        if self.SetTitle then self:SetTitle(name) end
        if self.UpdateBrowserControls then self:UpdateBrowserControls() end
        if self.Refresh then self:Refresh() end
        if self.db.autoOpen and self.frame then self.frame:Show() end
    else
        self:Print("Aucune table AtlasLoot trouvée pour " .. tostring(name) .. ".")
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("CHAT_MSG_RAID")
eventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
eventFrame:RegisterEvent("CHAT_MSG_PARTY")
eventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
eventFrame:RegisterEvent("START_LOOT_ROLL")
local masterLinkEvents = {
    CHAT_MSG_RAID = true,
    CHAT_MSG_RAID_LEADER = true,
    CHAT_MSG_RAID_WARNING = true,
    CHAT_MSG_PARTY = true,
    CHAT_MSG_PARTY_LEADER = true,
}
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and (...) == ADDON_NAME then
        local characterKey = (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
        -- La version 1 était enregistrée au niveau du compte. On repart une
        -- seule fois d'une table vide afin de ne pas propager cette wishlist
        -- partagée dans le fichier propre au personnage.
        if type(ChromieWishlistDB) ~= "table"
           or ChromieWishlistDB.storageVersion ~= 2
           or (ChromieWishlistDB.characterKey and ChromieWishlistDB.characterKey ~= characterKey) then
            ChromieWishlistDB = { storageVersion = 2, characterKey = characterKey }
        end
        ChromieWishlistDB.characterKey = characterKey
        CopyDefaults(defaults, ChromieWishlistDB)
        CW.db = ChromieWishlistDB
        CW.cacheTooltip = CreateFrame("GameTooltip", "ChromieWishlistCacheTooltip", nil, "GameTooltipTemplate")
        CW:BuildInstanceIndex()
        CW:BuildClassFilter()
        if CW.CreateUI then CW:CreateUI() end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        if CW.db then CW:UpdateZone(false) end
    elseif event == "LOOT_OPENED" then
        CW:ScanLootWindow()
    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        CW:ScanMessageLinks(message, false)
    elseif masterLinkEvents[event] then
        local message, sender = ...
        -- Les systèmes de loot de raid font souvent annoncer les objets par
        -- un assistant ou le chef plutôt que par le master looter retourné
        -- par GetLootMethod(). Un RW / message du chef est donc considéré
        -- comme fiable. Dans le canal raid/groupe ordinaire, on conserve la
        -- vérification stricte du master looter pour éviter les faux positifs.
        local trustedAnnouncement = event == "CHAT_MSG_RAID_WARNING"
            or event == "CHAT_MSG_RAID_LEADER"
            or event == "CHAT_MSG_PARTY_LEADER"
        if trustedAnnouncement or CW:IsMasterLooterSender(sender) then
            CW:ScanMessageLinks(message, true)
        end
    elseif event == "START_LOOT_ROLL" then
        local rollID = ...
        if GetLootRollItemLink then CW:CheckLink(GetLootRollItemLink(rollID)) end
    end
end)
eventFrame:SetScript("OnUpdate", function()
    if not CW.cacheRefreshUntil or GetTime() < (CW.cacheRefreshAt or 0) then return end
    if GetTime() >= CW.cacheRefreshUntil then
        CW.cacheRefreshUntil = nil
        return
    end
    CW.cacheRefreshAt = GetTime() + 1.5
    if CW.currentInstance and CW.currentEntry then
        CW:BuildRows(CW.currentInstance, CW.currentDifficulty)
        if CW.Refresh then CW:Refresh() end
    end
end)

SLASH_CHROMIEWISHLIST1 = "/cw"
SLASH_CHROMIEWISHLIST2 = "/chromiewishlist"
SlashCmdList.CHROMIEWISHLIST = function(message)
    if not CW.db then return end
    message = (message or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local command, rest = message:match("^(%S+)%s*(.-)$")
    command = (command or ""):lower()
    if command == "add" then
        local id = ItemID(rest)
        local priority = tonumber(rest:match("%s([123])%s*$")) or 1
        if id then CW:SetPriority(id, priority); CW:Print("Objet " .. id .. " ajouté en P" .. priority .. ".") end
    elseif command == "remove" or command == "del" then
        local id = ItemID(rest)
        if id then CW:SetPriority(id, 0); CW:Print("Objet " .. id .. " retiré.") end
    elseif command == "wishlist" or command == "list" then
        CW:BuildWishlistRows(); CW:SetTitle(CW:Text("wishlist")); CW:Refresh(); CW.frame:Show()
    elseif command == "import" then
        CW:ShowAtlasImport()
    elseif command == "importsound" then
        CW:ShowSoundImport()
    elseif command == "sound" then
        CW.db.sound = not CW.db.sound
        if CW.UpdateSoundControls then CW:UpdateSoundControls() end
        CW:Print("Son " .. (CW.db.sound and "activé." or "désactivé."))
    elseif command == "auto" then
        CW.db.autoOpen = not CW.db.autoOpen; CW:Print("Ouverture automatique " .. (CW.db.autoOpen and "activée." or "désactivée."))
    elseif command == "filter" then
        CW.db.classFilter = not CW.db.classFilter
        if CW.UpdateFilterControls then CW:UpdateFilterControls() end
        CW:Print("Filtre de classe " .. (CW.db.classFilter and "activé." or "désactivé."))
        CW:RefreshActiveLoot()
    elseif command == "stats" then
        CW.db.statFilter = not CW.db.statFilter
        CW:Print("Filtre de caractéristiques " .. (CW.db.statFilter and "activé." or "désactivé."))
        CW:RefreshActiveLoot()
    elseif command == "test" then
        CW:PlayAlertSound(true)
        CW:Print("Test du son : " .. CW:GetSoundLabel(CW:GetSoundOption()) .. ".")
    elseif command == "refresh" then
        CW.currentInstance = nil; CW:UpdateZone(true)
    elseif command == "browse" then
        CW.frame:Show()
    elseif command == "search" then
        CW:SearchLoot(rest)
    elseif command == "" or command == "show" then
        if CW.frame:IsShown() then CW.frame:Hide() else CW.frame:Show() end
    else
        CW:Print("/cw - ouvrir/fermer | browse | wishlist | import | importsound | add/remove | filter | stats | auto | sound | test | refresh")
    end
end
