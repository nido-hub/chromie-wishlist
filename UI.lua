local CW = _G.ChromieWishlist
local ROW_HEIGHT, VISIBLE_ROWS = 32, 13
local expansionNames = { [1] = "Classic", [2] = "Burning Crusade", [3] = "Wrath of the Lich King" }
local classNames = {
    fr = { MAGE = "Mage", PRIEST = "Prêtre", WARLOCK = "Démoniste", DRUID = "Druide", ROGUE = "Voleur", HUNTER = "Chasseur", SHAMAN = "Chaman", PALADIN = "Paladin", WARRIOR = "Guerrier", DEATHKNIGHT = "Chevalier de la mort" },
    en = { MAGE = "Mage", PRIEST = "Priest", WARLOCK = "Warlock", DRUID = "Druid", ROGUE = "Rogue", HUNTER = "Hunter", SHAMAN = "Shaman", PALADIN = "Paladin", WARRIOR = "Warrior", DEATHKNIGHT = "Death Knight" },
}

local function ItemLink(itemID)
    return select(2, GetItemInfo(itemID)) or ("item:" .. itemID)
end

function CW:SetTitle(text)
    if self.title then self.title:SetText("Chromie Wishlist " .. self.version .. " — " .. tostring(text or "")) end
end

function CW:CreateUI()
    local frame = CreateFrame("Frame", "ChromieWishlistFrame", UIParent)
    self.frame = frame
    table.insert(UISpecialFrames, "ChromieWishlistFrame")
    frame:SetWidth(900); frame:SetHeight(640)
    frame:SetClampedToScreen(true)
    frame:SetPoint(self.db.point, UIParent, self.db.relativePoint, self.db.x, self.db.y)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.055, 0.045, 0.035, 0.98)
    frame:SetBackdropBorderColor(0.62, 0.46, 0.22, 1)
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        CW.db.point, CW.db.relativePoint, CW.db.x, CW.db.y = point, relativePoint, x, y
    end)
    frame:Hide()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.title = title
    title:SetPoint("TOPLEFT", 22, -17); title:SetPoint("TOPRIGHT", -115, -17)
    title:SetJustifyH("LEFT"); title:SetText("Chromie Wishlist")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -7, -7)

    local languageButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.languageButton = languageButton
    languageButton:SetWidth(52); languageButton:SetHeight(22)
    languageButton:SetPoint("TOPRIGHT", close, "TOPLEFT", 2, -3)
    languageButton:SetScript("OnClick", function()
        CW.db.language = CW.db.language == "en" and "fr" or "en"
        CW:ApplyLanguage()
        if CW.activeTab == "sounds" then
            CW:SetTitle(CW:Text("tabSounds"))
        elseif CW.viewMode == "wishlist" then
            CW:BuildWishlistRows(); CW:SetTitle(CW:Text("wishlist")); CW:Refresh()
        else
            CW:RefreshActiveLoot()
        end
    end)

    local info = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.infoText = info
    info:SetPoint("TOPLEFT", 22, -44)
    info:SetText("Bouton priorite : P3 > P2 > P1 > retirer. P1 est la priorite maximale.")

    local soundLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.soundLabel = soundLabel
    soundLabel:SetPoint("TOPLEFT", 22, -73); soundLabel:SetText("SON :")

    local soundDropDown = CreateFrame("Frame", "ChromieWishlistSoundDropDown", frame, "UIDropDownMenuTemplate")
    self.soundDropDown = soundDropDown
    soundDropDown:SetPoint("TOPLEFT", soundLabel, "TOPRIGHT", -10, 18)
    UIDropDownMenu_SetWidth(soundDropDown, 125)
    UIDropDownMenu_Initialize(soundDropDown, function()
        for _, option in ipairs(CW.soundOptions) do
            local key = option.key
            local info = UIDropDownMenu_CreateInfo()
            info.text = CW:GetSoundLabel(option)
            info.value = key
            info.checked = CW:GetSoundProfile(CW.editSoundPriority).soundChoice == key
            info.func = function()
                CW:SetSoundChoice(key, true, CW.editSoundPriority)
            end
            UIDropDownMenu_AddButton(info)
        end
        local info = UIDropDownMenu_CreateInfo()
        info.text = CW:Text("soundImport")
        info.notCheckable = true
        info.func = function() CloseDropDownMenus(); CW:ShowSoundImport(CW.editSoundPriority) end
        UIDropDownMenu_AddButton(info)
    end)

    local soundEnabled = CreateFrame("CheckButton", "ChromieWishlistSoundEnabled", frame, "UICheckButtonTemplate")
    self.soundEnabled = soundEnabled
    soundEnabled:SetPoint("LEFT", soundDropDown, "RIGHT", -8, 2)
    soundEnabled:SetWidth(24); soundEnabled:SetHeight(24)
    local soundEnabledText = _G[soundEnabled:GetName() .. "Text"]
    self.soundEnabledText = soundEnabledText
    if soundEnabledText then soundEnabledText:SetText("Actif") end
    soundEnabled:SetScript("OnClick", function(self)
        CW.db.sound = self:GetChecked() and true or false
        if CW.db.sound then CW:PlayAlertSound(true, CW.editSoundPriority) end
    end)

    local classFilter = CreateFrame("CheckButton", "ChromieWishlistClassFilter", frame, "UICheckButtonTemplate")
    self.classFilterButton = classFilter
    classFilter:SetPoint("TOPLEFT", 300, -61)
    classFilter:SetWidth(24); classFilter:SetHeight(24)
    local classFilterText = _G[classFilter:GetName() .. "Text"]
    self.classFilterText = classFilterText
    local localizedClass = UnitClass("player") or "classe"
    if classFilterText then classFilterText:SetText("Filtre " .. localizedClass) end
    classFilter:SetScript("OnClick", function(self)
        CW.db.classFilter = self:GetChecked() and true or false
        if CW.db.classFilter then CW.db.statFilter = true end
        CW:RefreshActiveLoot()
        CW:Print("Filtre " .. localizedClass .. " " .. (CW.db.classFilter and "activé." or "désactivé."))
    end)
    classFilter:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(CW:Text("filterTitle"), 1, 0.82, 0)
        GameTooltip:AddLine(CW:Text("filterOnTip"), 1, 1, 1, true)
        GameTooltip:AddLine(CW:Text("filterOffTip"), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    classFilter:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local soundDelayLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.soundDelayLabel = soundDelayLabel
    soundDelayLabel:SetPoint("TOPLEFT", 480, -73)
    soundDelayLabel:SetText(self:Text("soundDelay"))

    local soundDelayDropDown = CreateFrame("Frame", "ChromieWishlistSoundDelayDropDown", frame, "UIDropDownMenuTemplate")
    self.soundDelayDropDown = soundDelayDropDown
    soundDelayDropDown:SetPoint("TOPLEFT", soundDelayLabel, "TOPRIGHT", -10, 18)
    UIDropDownMenu_SetWidth(soundDelayDropDown, 95)
    UIDropDownMenu_Initialize(soundDelayDropDown, function()
        for _, delay in ipairs(CW.soundDelayOptions) do
            local value = delay
            local info = UIDropDownMenu_CreateInfo()
            info.text = CW:GetSoundDelayLabel(value)
            info.value = value
            info.checked = CW.db.soundDelay == value
            info.func = function()
                CW.db.soundDelay = value
                CW:UpdateSoundControls()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local browserLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.browserLabel = browserLabel
    browserLabel:SetPoint("TOPLEFT", 22, -102); browserLabel:SetText("PARCOURIR :")

    local browserDropDown = CreateFrame("Frame", "ChromieWishlistBrowserDropDown", frame, "UIDropDownMenuTemplate")
    self.browserDropDown = browserDropDown
    browserDropDown:SetPoint("TOPLEFT", browserLabel, "TOPRIGHT", -8, 18)
    UIDropDownMenu_SetWidth(browserDropDown, 235)
    UIDropDownMenu_Initialize(browserDropDown, function(_, level)
        level = level or 1
        if level == 1 then
            for expansion = 1, 3 do
                local info = UIDropDownMenu_CreateInfo()
                info.text = expansionNames[expansion]
                info.value = expansion
                info.hasArrow = true
                info.notCheckable = true
                UIDropDownMenu_AddButton(info, level)
            end
        elseif level == 2 then
            local expansion = UIDROPDOWNMENU_MENU_VALUE
            for _, entry in ipairs(CW:GetInstancesByExpansion(expansion)) do
                local selectedEntry = entry
                local info = UIDropDownMenu_CreateInfo()
                info.text = entry.name
                info.value = entry.key
                info.checked = CW.browsedEntry and CW.browsedEntry.key == entry.key
                info.func = function() CW:BrowseInstance(selectedEntry, CW.db.browseDifficulty) end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)

    local difficultyDropDown = CreateFrame("Frame", "ChromieWishlistDifficultyDropDown", frame, "UIDropDownMenuTemplate")
    self.difficultyDropDown = difficultyDropDown
    difficultyDropDown:SetPoint("LEFT", browserDropDown, "RIGHT", -15, 0)
    UIDropDownMenu_SetWidth(difficultyDropDown, 105)
    UIDropDownMenu_Initialize(difficultyDropDown, function()
        for _, mode in ipairs(CW:GetDifficultyOptions(CW.browsedEntry)) do
            local value, labelKey = mode.value, mode.labelKey
            local info = UIDropDownMenu_CreateInfo()
            info.text = CW:Text(labelKey); info.value = value
            info.checked = CW.db.browseDifficulty == value
            info.func = function()
                if CW.browsedEntry then CW:BrowseInstance(CW.browsedEntry, value) end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local wishlist = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.wishlistButton = wishlist
    wishlist:SetWidth(95); wishlist:SetHeight(22); wishlist:SetPoint("TOPRIGHT", -48, -92)
    wishlist:SetText("Wishlist")
    wishlist:SetScript("OnClick", function()
        CW:BuildWishlistRows(); CW:SetTitle(CW:Text("wishlist")); CW:Refresh()
    end)

    local current = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.currentButton = current
    current:SetWidth(95); current:SetHeight(22); current:SetPoint("RIGHT", wishlist, "LEFT", -5, 0)
    current:SetText("Zone actuelle")
    current:SetScript("OnClick", function() CW.currentInstance = nil; CW:UpdateZone(true) end)

    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.searchLabel = searchLabel
    searchLabel:SetPoint("TOPLEFT", 22, -139); searchLabel:SetText("RECHERCHE :")
    local searchBox = CreateFrame("EditBox", "ChromieWishlistSearchBox", frame, "InputBoxTemplate")
    self.searchBox = searchBox
    searchBox:SetWidth(270); searchBox:SetHeight(22)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 10, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus(); CW:SearchLoot(self:GetText())
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local searchButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.searchButton = searchButton
    searchButton:SetWidth(85); searchButton:SetHeight(22)
    searchButton:SetPoint("LEFT", searchBox, "RIGHT", 8, 0)
    searchButton:SetText("Chercher")
    searchButton:SetScript("OnClick", function() CW:SearchLoot(searchBox:GetText()) end)

    local importButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.importAtlasButton = importButton
    importButton:SetWidth(210); importButton:SetHeight(22)
    importButton:SetPoint("TOPRIGHT", -22, -130)
    importButton:SetText(self:Text("importAtlas"))
    importButton:SetScript("OnClick", function() CW:ShowAtlasImport() end)

    local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.itemHeader = header
    header:SetPoint("TOPLEFT", 55, -177); header:SetText("OBJET")
    local headerBoss = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.sourceHeader = headerBoss
    headerBoss:SetPoint("TOPLEFT", 445, -177); headerBoss:SetText("INSTANCE / BOSS")
    local headerPriority = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.priorityHeader = headerPriority
    headerPriority:SetPoint("TOPRIGHT", -42, -177); headerPriority:SetText("PRIORITÉ")

    local scroll = CreateFrame("ScrollFrame", "ChromieWishlistScrollFrame", frame, "FauxScrollFrameTemplate")
    self.scroll = scroll
    scroll:SetPoint("TOPLEFT", 20, -193); scroll:SetPoint("BOTTOMRIGHT", -36, 22)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function() CW:Refresh() end)
    end)

    self.rowFrames = {}
    for index = 1, VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, frame)
        self.rowFrames[index] = row
        row:SetHeight(ROW_HEIGHT); row:SetPoint("LEFT", 23, 0); row:SetPoint("RIGHT", -40, 0)
        if index == 1 then row:SetPoint("TOP", scroll, "TOP", 0, 0)
        else row:SetPoint("TOP", self.rowFrames[index - 1], "BOTTOM", 0, 0) end

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(); row.bg:SetTexture(0.65, 0.48, 0.24, index % 2 == 0 and 0.09 or 0.035)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetWidth(27); row.icon:SetHeight(27); row.icon:SetPoint("LEFT", 2, 0)
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", 38, 0); row.name:SetWidth(420); row.name:SetJustifyH("LEFT")
        row.boss = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.boss:SetPoint("LEFT", 470, 0); row.boss:SetWidth(265); row.boss:SetJustifyH("LEFT")
        row.priority = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.priority:SetWidth(58); row.priority:SetHeight(21); row.priority:SetPoint("RIGHT", -2, 0)
        row.priority:SetScript("OnClick", function(self)
            if self.itemID then CW:CyclePriority(self.itemID, self.source) end
        end)
        row:SetScript("OnEnter", function(self)
            if self.itemID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. self.itemID)
                if self.sourceText and self.sourceText ~= "" then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(CW:Text("tooltipSource") .. self.sourceText, 1, 0.82, 0, true)
                    GameTooltip:Show()
                end
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self)
            if self.itemID and IsModifiedClick("CHATLINK") then HandleModifiedItemClick(ItemLink(self.itemID)) end
        end)
    end
    self:CreateTabbedLayout()
    self:UpdateSoundControls()
    self:UpdateFilterControls()
    self:UpdateBrowserControls()
    self:ApplyLanguage()
    self:CreateMinimapButton()
end

local function Place(widget, parent, x, y)
    widget:SetParent(parent)
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
end

function CW:CreateTabbedLayout()
    local frame = self.frame
    local banner = frame:CreateTexture(nil, "BACKGROUND")
    banner:SetTexture(0.28, 0.18, 0.07, 0.55)
    banner:SetPoint("TOPLEFT", 8, -8); banner:SetPoint("TOPRIGHT", -8, -8); banner:SetHeight(34)
    self.tabs = {}
    for index, key in ipairs({ "wishlist", "explore", "sounds" }) do
        local tab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        self.tabs[key] = tab
        tab:SetWidth(160); tab:SetHeight(28); tab:SetPoint("TOPLEFT", 22 + (index - 1) * 166, -58)
        tab:SetScript("OnClick", function() CW:SelectTab(key) end)
    end
    self.lootPanel = CreateFrame("Frame", nil, frame)
    self.lootPanel:SetAllPoints(frame)
    self.wishlistTools = CreateFrame("Frame", nil, frame)
    self.wishlistTools:SetAllPoints(frame)
    self.exploreTools = CreateFrame("Frame", nil, frame)
    self.exploreTools:SetAllPoints(frame)
    self.soundPanel = CreateFrame("Frame", nil, frame)
    self.soundPanel:SetAllPoints(frame)
    -- Toolbars stay above the shared loot panel; only their active controls are shown.
    self.wishlistTools:SetFrameLevel(self.lootPanel:GetFrameLevel() + 1)
    self.exploreTools:SetFrameLevel(self.lootPanel:GetFrameLevel() + 1)
    Place(self.infoText, frame, 24, -610)
    Place(self.classFilterButton, frame, 664, -59)
    Place(self.itemHeader, self.lootPanel, 61, -158)
    Place(self.sourceHeader, self.lootPanel, 493, -158)
    Place(self.priorityHeader, self.lootPanel, 790, -158)
    Place(self.scroll, self.lootPanel, 20, -180)
    self.scroll:SetPoint("BOTTOMRIGHT", self.lootPanel, "BOTTOMRIGHT", -36, 44)
    for _, row in ipairs(self.rowFrames) do
        row:SetParent(self.lootPanel)
    end
    Place(self.importAtlasButton, self.wishlistTools, 657, -109)
    self.wishlistButton:Hide()
    self.priorityFilters = {}
    for priority = 0, 3 do
        local value = priority
        local button = CreateFrame("Button", nil, self.wishlistTools, "UIPanelButtonTemplate")
        self.priorityFilters[priority] = button
        button:SetWidth(priority == 0 and 180 or 82); button:SetHeight(25)
        button:SetPoint("TOPLEFT", priority == 0 and 23 or 212 + (priority - 1) * 90, -109)
        button:SetScript("OnClick", function()
            if value == 0 then CW.wishlistPriority = nil else CW.wishlistPriority = value end
            FauxScrollFrame_SetOffset(CW.scroll, 0)
            CW.scroll:SetVerticalScroll(0)
            CW:Refresh()
        end)
    end
    self.browserLabel:Hide(); self.searchLabel:Hide()
    Place(self.browserDropDown, self.exploreTools, 5, -99)
    UIDropDownMenu_SetWidth(self.browserDropDown, 255)
    Place(self.difficultyDropDown, self.exploreTools, 290, -99)
    Place(self.currentButton, self.exploreTools, 450, -102)
    self.currentButton:SetWidth(125)
    Place(self.searchBox, self.exploreTools, 596, -102)
    self.searchBox:SetWidth(170)
    Place(self.searchButton, self.exploreTools, 778, -102)
    self.editSoundPriority = 1
    local settingsBackground = self.soundPanel:CreateTexture(nil, "BACKGROUND")
    settingsBackground:SetTexture(0.16, 0.12, 0.075, 0.65)
    settingsBackground:SetPoint("TOPLEFT", 215, -103); settingsBackground:SetPoint("BOTTOMRIGHT", -24, 70)
    self.soundPriorityButtons = {}
    for priority = 1, 3 do
        local value = priority
        local button = CreateFrame("Button", nil, self.soundPanel, "UIPanelButtonTemplate")
        self.soundPriorityButtons[priority] = button
        button:SetWidth(170); button:SetHeight(30); button:SetPoint("TOPLEFT", 24, -113 - (priority - 1) * 39)
        button:SetText("P" .. priority)
        button:SetScript("OnClick", function() CW:SelectSoundPriority(value) end)
        self:GetSoundProfile(priority)
    end
    self.soundProfileTitle = self.soundPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.soundProfileTitle:SetPoint("TOPLEFT", 233, -116)
    Place(self.soundLabel, self.soundPanel, 235, -166)
    Place(self.soundDropDown, self.soundPanel, 275, -150)
    UIDropDownMenu_SetWidth(self.soundDropDown, 195)
    Place(self.soundEnabled, self.soundPanel, 540, -151)
    Place(self.soundDelayLabel, self.soundPanel, 235, -212)
    Place(self.soundDelayDropDown, self.soundPanel, 400, -196)
    self.soundTestButton = CreateFrame("Button", nil, self.soundPanel, "UIPanelButtonTemplate")
    self.soundTestButton:SetWidth(100); self.soundTestButton:SetHeight(24)
    self.soundTestButton:SetPoint("TOPLEFT", 677, -155)
    self.soundTestButton:SetScript("OnClick", function() CW:PlayAlertSound(true, CW.editSoundPriority) end)
    self.randomTitle = self.soundPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.randomTitle:SetPoint("TOPLEFT", 235, -273)
    self.randomHelp = self.soundPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.randomHelp:SetPoint("TOPLEFT", 235, -299); self.randomHelp:SetWidth(600); self.randomHelp:SetJustifyH("LEFT")
    self.soundSharedHelp = self.soundPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.soundSharedHelp:SetPoint("TOPLEFT", 235, -523); self.soundSharedHelp:SetWidth(600); self.soundSharedHelp:SetJustifyH("LEFT")
    self.randomChecks = {}
    for index, option in ipairs(self.soundOptions) do
        if option.key ~= "random" then
            local key = option.key
            local check = CreateFrame("CheckButton", "ChromieWishlistRandom" .. key, self.soundPanel, "UICheckButtonTemplate")
            self.randomChecks[key] = check
            check:SetWidth(24); check:SetHeight(24); check:SetPoint("TOPLEFT", 235, -323 - (index - 1) * 32)
            check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            check.label:SetPoint("LEFT", check, "RIGHT", 6, 0)
            check:SetScript("OnClick", function(self)
                local profile = CW:GetSoundProfile(CW.editSoundPriority)
                if not profile.randomSounds then
                    profile.randomSounds = {}
                    for _, candidate in ipairs(CW.soundOptions) do
                        if candidate.key ~= "random" then profile.randomSounds[candidate.key] = true end
                    end
                end
                profile.randomSounds[key] = self:GetChecked() and true or nil
            end)
        end
    end
    self.activeTab = "wishlist"
    self:BuildWishlistRows()
    self:ActivateTab("wishlist")
    self:SetTitle(self:Text("wishlist"))
end

function CW:ActivateTab(key)
    if not self.tabs then return end
    if key == "wishlist" and self.viewMode and self.viewMode ~= "wishlist" then
        local rows = {}
        for index, data in ipairs(self.rows) do rows[index] = data end
        self.explorerState = { rows = rows, viewMode = self.viewMode }
    end
    self.activeTab = key
    if self.scroll and self.lastLootTab ~= key and key ~= "sounds" then
        FauxScrollFrame_SetOffset(self.scroll, 0)
        self.scroll:SetVerticalScroll(0)
        self.lastLootTab = key
    end
    CloseDropDownMenus()
    for name, button in pairs(self.tabs) do
        button:SetButtonState(name == key and "PUSHED" or "NORMAL", name == key)
    end
    self.lootPanel:Hide(); self.wishlistTools:Hide(); self.exploreTools:Hide(); self.soundPanel:Hide()
    if key == "sounds" then self.soundPanel:Show()
    else
        self.lootPanel:Show()
        if key == "wishlist" then self.wishlistTools:Show() else self.exploreTools:Show() end
    end
    if self.searchBox then self.searchBox:ClearFocus() end
end

function CW:SelectTab(key)
    self:ActivateTab(key)
    if key == "wishlist" then
        self:BuildWishlistRows(); self:SetTitle(self:Text("wishlist"))
    elseif key == "explore" then
        if self.viewMode == "wishlist" and self.explorerState then
            self.rows = self.explorerState.rows
            self.viewMode = self.explorerState.viewMode
        elseif self.viewMode == "wishlist" then
            self.viewMode = "browse"
            self.cacheRefreshUntil = nil
            self.rows = { { kind = "empty", text = self:Text("exploreHelp") } }
        end
        local title = self:Text("tabExplore")
        if self.viewMode == "search" then title = self:Text("searchTitle")
        elseif self.viewMode == "zone" then title = self.currentInstance or title
        elseif self.browsedEntry then title = self.browsedEntry.name end
        self:SetTitle(title)
    else self:SetTitle(self:Text("tabSounds")) end
    self:Refresh()
end

function CW:SelectSoundPriority(priority)
    self.editSoundPriority = priority
    CloseDropDownMenus()
    self:UpdateSoundControls()
end

function CW:UpdateMinimapButtonPosition()
    if not self.minimapButton then return end
    local angle = math.rad(tonumber(self.db.minimapAngle) or 225)
    local radius = 80
    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

function CW:CreateMinimapButton()
    if self.minimapButton then return end
    local button = CreateFrame("Button", "ChromieWishlistMinimapButton", Minimap)
    self.minimapButton = button
    button:SetFrameStrata("MEDIUM")
    button:SetWidth(32); button:SetHeight(32)
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20); icon:SetHeight(20); icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Note_06")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetWidth(53); border:SetHeight(53); border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            CW:BuildWishlistRows(); CW:SetTitle(CW:Text("wishlist")); CW:Refresh(); CW.frame:Show()
        elseif CW.frame:IsShown() then
            CW.frame:Hide()
        else
            CW.frame:Show()
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Chromie Wishlist", 1, 0.82, 0)
        GameTooltip:AddLine(CW:Text("leftClick"), 1, 1, 1)
        GameTooltip:AddLine(CW:Text("rightClick"), 1, 1, 1)
        GameTooltip:AddLine(CW:Text("drag"), 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local function UpdateDragPosition()
        local cursorX, cursorY = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        cursorX, cursorY = cursorX / scale, cursorY / scale
        local centerX, centerY = Minimap:GetCenter()
        CW.db.minimapAngle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
        CW:UpdateMinimapButtonPosition()
    end
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", UpdateDragPosition)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        UpdateDragPosition()
    end)

    self:UpdateMinimapButtonPosition()
end

function CW:ShowAtlasImport()
    local lists = self:GetAtlasWishlists()
    if #lists == 0 then self:Print(self:Text("importUnavailable")); return end
    self.frame:Show()
    if self.soundImportFrame then self.soundImportFrame:Hide() end
    if not self.importFrame then self:CreateAtlasImportUI() end
    self.importLists = lists
    self.importSelection = lists[1]
    self.importTitle:SetText(self:Text("importAtlas"))
    self.importHelp:SetText(self:Text("importHelp"))
    self.importConfirm:SetText(self:Text("importButton"))
    self.importCancel:SetText(self:Text("cancel"))
    UIDropDownMenu_SetText(self.importDropDown, self.importSelection.label)
    self.importFrame:Show()
end

function CW:CreateAtlasImportUI()
    local frame = CreateFrame("Frame", "ChromieWishlistImportFrame", self.frame)
    self.importFrame = frame
    frame:SetWidth(480); frame:SetHeight(205)
    frame:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, 1)
    frame:SetScript("OnHide", function() CloseDropDownMenus() end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.importTitle = title
    title:SetPoint("TOPLEFT", 20, -20)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    local help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.importHelp = help
    help:SetPoint("TOPLEFT", 20, -50); help:SetWidth(440); help:SetJustifyH("LEFT")

    local dropdown = CreateFrame("Frame", "ChromieWishlistImportDropDown", frame, "UIDropDownMenuTemplate")
    self.importDropDown = dropdown
    dropdown:SetPoint("TOPLEFT", 5, -100)
    UIDropDownMenu_SetWidth(dropdown, 410)
    UIDropDownMenu_Initialize(dropdown, function()
        for _, entry in ipairs(CW.importLists or {}) do
            local selected = entry
            local info = UIDropDownMenu_CreateInfo()
            info.text = entry.label
            info.checked = CW.importSelection == entry
            info.func = function()
                CW.importSelection = selected
                UIDropDownMenu_SetText(dropdown, selected.label)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    local confirm = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.importConfirm = confirm
    confirm:SetWidth(120); confirm:SetHeight(24)
    confirm:SetPoint("BOTTOMRIGHT", -150, 20)
    confirm:SetScript("OnClick", function()
        if CW:ImportAtlasWishlist(CW.importSelection) ~= nil then frame:Hide() end
    end)
    local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.importCancel = cancel
    cancel:SetWidth(120); cancel:SetHeight(24)
    cancel:SetPoint("BOTTOMRIGHT", -20, 20)
    cancel:SetScript("OnClick", function() frame:Hide() end)
end

function CW:ShowSoundImport(priority)
    self.soundImportPriority = priority
    self.frame:Show()
    if self.importFrame then self.importFrame:Hide() end
    if not self.soundImportFrame then self:CreateSoundImportUI() end
    self.soundImportTitle:SetText(self:Text("soundImport"))
    if priority then self.soundImportTitle:SetText("P" .. priority .. " — " .. self:Text("soundImport")) end
    self.soundImportHelp:SetText(self:Text("soundImportHelp"))
    self.soundFileLabel:SetText(self:Text("soundFile"))
    self.soundImportTest:SetText(self:Text("soundTest"))
    self.soundImportDefault:SetText(self:Text("soundDefault"))
    self.soundImportSave:SetText(self:Text("soundSave"))
    self.soundImportCancel:SetText(self:Text("cancel"))
    self.soundFileBox:SetText(self:GetSoundProfile(priority).customSoundFile or "sound_addon.ogg")
    self.soundImportFrame:Show()
    self.soundFileBox:SetFocus()
    self.soundFileBox:HighlightText()
end

function CW:CreateSoundImportUI()
    local frame = CreateFrame("Frame", "ChromieWishlistSoundImportFrame", self.frame)
    self.soundImportFrame = frame
    frame:SetWidth(540); frame:SetHeight(270)
    frame:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, 1)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.soundImportTitle = title
    title:SetPoint("TOPLEFT", 20, -20)
    local help = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.soundImportHelp = help
    help:SetPoint("TOPLEFT", 20, -52); help:SetWidth(500); help:SetJustifyH("LEFT")
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.soundFileLabel = label
    label:SetPoint("TOPLEFT", 20, -133)
    local box = CreateFrame("EditBox", "ChromieWishlistSoundFileBox", frame, "InputBoxTemplate")
    self.soundFileBox = box
    box:SetPoint("TOPLEFT", 25, -154)
    box:SetWidth(490); box:SetHeight(24)
    box:SetAutoFocus(false); box:SetMaxLetters(240)
    box:SetScript("OnEscapePressed", function() frame:Hide() end)
    local function Save()
        if CW:ImportSoundFile(box:GetText(), CW.soundImportPriority) then frame:Hide() end
    end
    box:SetScript("OnEnterPressed", Save)
    frame:SetScript("OnHide", function() box:ClearFocus() end)

    local test = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.soundImportTest = test
    test:SetWidth(85); test:SetHeight(24); test:SetPoint("BOTTOMLEFT", 20, 20)
    test:SetScript("OnClick", function() CW:PreviewSoundFile(box:GetText()) end)
    local original = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.soundImportDefault = original
    original:SetWidth(120); original:SetHeight(24); original:SetPoint("LEFT", test, "RIGHT", 8, 0)
    original:SetScript("OnClick", function() box:SetText("sound_addon.ogg") end)
    local save = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.soundImportSave = save
    save:SetWidth(135); save:SetHeight(24); save:SetPoint("BOTTOMRIGHT", -122, 20)
    save:SetScript("OnClick", Save)
    local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.soundImportCancel = cancel
    cancel:SetWidth(94); cancel:SetHeight(24); cancel:SetPoint("BOTTOMRIGHT", -20, 20)
    cancel:SetScript("OnClick", function() frame:Hide() end)
end

function CW:UpdateSoundControls()
    if self.soundDropDown then
        local option = self:GetSoundOption(nil, self.editSoundPriority)
        UIDropDownMenu_SetSelectedValue(self.soundDropDown, option.key)
        UIDropDownMenu_SetText(self.soundDropDown, self:GetSoundLabel(option))
    end
    if self.soundEnabled then self.soundEnabled:SetChecked(self.db.sound and 1 or nil) end
    if self.soundDelayDropDown then
        UIDropDownMenu_SetSelectedValue(self.soundDelayDropDown, self.db.soundDelay)
        UIDropDownMenu_SetText(self.soundDelayDropDown, self:GetSoundDelayLabel(self.db.soundDelay))
    end
    if self.soundProfileTitle then
        self.soundProfileTitle:SetText(self:Text("soundProfile", self.editSoundPriority))
        for priority, button in ipairs(self.soundPriorityButtons) do
            button:SetButtonState(priority == self.editSoundPriority and "PUSHED" or "NORMAL", priority == self.editSoundPriority)
        end
        local profile = self:GetSoundProfile(self.editSoundPriority)
        for key, check in pairs(self.randomChecks) do
            check:SetChecked((not profile.randomSounds or profile.randomSounds[key]) and 1 or nil)
            check.label:SetText(self:GetSoundLabel(self:GetSoundOption(key, self.editSoundPriority)))
        end
    end
end

function CW:UpdateFilterControls()
    if self.classFilterButton then
        self.classFilterButton:SetChecked(self.db.classFilter and 1 or nil)
    end
end

function CW:UpdateBrowserControls()
    if self.browserDropDown then
        UIDropDownMenu_SetText(self.browserDropDown, self.browsedEntry and self.browsedEntry.name or self:Text("chooseInstance"))
    end
    if self.difficultyDropDown then
        local options = self:GetDifficultyOptions(self.browsedEntry)
        local selected = options[1]
        for _, mode in ipairs(options) do
            if mode.value == self.db.browseDifficulty then selected = mode; break end
        end
        UIDropDownMenu_SetSelectedValue(self.difficultyDropDown, selected and selected.value)
        UIDropDownMenu_SetText(self.difficultyDropDown, self:Text(selected and selected.labelKey or "chooseInstance"))
        if selected then UIDropDownMenu_EnableDropDown(self.difficultyDropDown)
        else UIDropDownMenu_DisableDropDown(self.difficultyDropDown) end
    end
end

function CW:ApplyLanguage()
    local language = self.db.language == "en" and "en" or "fr"
    self.db.language = language
    if self.languageButton then self.languageButton:SetText(language:upper()) end
    if self.infoText then self.infoText:SetText(self:Text("priorityHelp")) end
    if self.soundLabel then self.soundLabel:SetText(self:Text("sound")) end
    if self.soundEnabledText then self.soundEnabledText:SetText(self:Text("active")) end
    if self.soundDelayLabel then self.soundDelayLabel:SetText(self:Text("soundDelay")) end
    if self.classFilterText then
        local class = classNames[language][self.playerClass] or (UnitClass("player") or "Class")
        self.classFilterText:SetText(self:Text("classFilter", class))
    end
    if self.browserLabel then self.browserLabel:SetText(self:Text("browse")) end
    if self.wishlistButton then self.wishlistButton:SetText(self:Text("wishlist")) end
    if self.currentButton then self.currentButton:SetText(self:Text("currentZone")) end
    if self.searchLabel then self.searchLabel:SetText(self:Text("search")) end
    if self.searchButton then self.searchButton:SetText(self:Text("searchButton")) end
    if self.importAtlasButton then self.importAtlasButton:SetText(self:Text("importAtlas")) end
    if self.importFrame then self.importFrame:Hide() end
    if self.soundImportFrame then self.soundImportFrame:Hide() end
    if self.itemHeader then self.itemHeader:SetText(self:Text("item")) end
    if self.sourceHeader then self.sourceHeader:SetText(self:Text("source")) end
    if self.priorityHeader then self.priorityHeader:SetText(self:Text("priority")) end
    if self.tabs then
        self.tabs.wishlist:SetText(self:Text("tabWishlist"))
        self.tabs.explore:SetText(self:Text("tabExplore"))
        self.tabs.sounds:SetText(self:Text("tabSounds"))
        self.priorityFilters[0]:SetText(self:Text("priorityAll"))
        for priority = 1, 3 do self.priorityFilters[priority]:SetText("P" .. priority) end
        self.soundTestButton:SetText(self:Text("soundTest"))
        self.randomTitle:SetText(self:Text("randomPool"))
        self.randomHelp:SetText(self:Text("randomHelp"))
        self.soundSharedHelp:SetText(self:Text("soundShared"))
    end
    self:UpdateSoundControls()
    self:UpdateBrowserControls()
    self:Refresh()
end

function CW:Refresh()
    if not self.frame then return end
    if self.viewMode == "wishlist" then self:BuildWishlistRows(true) end
    local rows = self.rows
    if self.viewMode == "wishlist" and self.wishlistPriority then
        rows = {}
        for _, data in ipairs(self.rows) do
            if data.kind ~= "item" or self:GetPriority(data.itemID) == self.wishlistPriority then rows[#rows + 1] = data end
        end
        if #rows == 1 then rows[2] = { kind = "empty", text = self:Text("emptyPriority") } end
    end
    if self.priorityFilters then
        for priority, button in pairs(self.priorityFilters) do
            local selected = priority == (self.wishlistPriority or 0)
            button:SetButtonState(selected and "PUSHED" or "NORMAL", selected)
        end
    end
    local total = #rows
    FauxScrollFrame_Update(self.scroll, total, VISIBLE_ROWS, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(self.scroll)
    for index = 1, VISIBLE_ROWS do
        local widget, data = self.rowFrames[index], rows[offset + index]
        if not data then
            widget:Hide()
        else
            widget:Show(); widget.itemID = nil; widget.sourceText = nil; widget.priority.source = nil
            widget.icon:Hide(); widget.boss:SetText(""); widget.priority:Hide()
            if data.kind == "boss" then
                widget.name:SetWidth(660); widget.name:SetFontObject(GameFontNormal)
                widget.name:SetText("- " .. tostring(data.text) .. " -")
            elseif data.kind == "empty" then
                widget.name:SetWidth(660); widget.name:SetFontObject(GameFontDisableSmall)
                widget.name:SetText("  " .. tostring(data.text))
            else
                local name, link, quality, _, _, _, _, _, _, texture = GetItemInfo(data.itemID)
                widget.itemID = data.itemID
                widget.name:SetWidth(420); widget.name:SetFontObject(GameFontHighlightSmall)
                widget.name:SetText(link or name or ("Objet #" .. data.itemID .. " (chargement...)"))
                widget.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark"); widget.icon:Show()
                local source = data.boss or ""
                if data.instance and data.instance ~= "" then source = data.instance .. " - " .. source end
                widget.boss:SetText(source)
                widget.sourceText = source
                local priority = self:GetPriority(data.itemID)
                widget.priority.itemID = data.itemID; widget.priority.source = data; widget.priority:Show()
                if priority > 0 then
                    widget.priority:SetText("P" .. priority)
                    if priority == 1 then widget.priority:GetFontString():SetTextColor(1, .25, .25)
                    elseif priority == 2 then widget.priority:GetFontString():SetTextColor(1, .75, .1)
                    else widget.priority:GetFontString():SetTextColor(.3, 1, .3) end
                else
                    widget.priority:SetText(self:Text("add")); widget.priority:GetFontString():SetTextColor(.7, .7, .7)
                end
            end
        end
    end
end
