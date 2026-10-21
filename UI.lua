local CW = _G.ChromieWishlist
local ROW_HEIGHT, VISIBLE_ROWS = 25, 15
local expansionNames = { [1] = "Classic", [2] = "Burning Crusade", [3] = "Wrath of the Lich King" }
local difficultyOptions = {
    { value = 3, labelKey = "mode10" },
    { value = 4, labelKey = "mode25" },
    { value = 5, labelKey = "mode10h" },
    { value = 6, labelKey = "mode25h" },
}
local classNames = {
    fr = { MAGE = "Mage", PRIEST = "Prêtre", WARLOCK = "Démoniste", DRUID = "Druide", ROGUE = "Voleur", HUNTER = "Chasseur", SHAMAN = "Chaman", PALADIN = "Paladin", WARRIOR = "Guerrier", DEATHKNIGHT = "Chevalier de la mort" },
    en = { MAGE = "Mage", PRIEST = "Priest", WARLOCK = "Warlock", DRUID = "Druid", ROGUE = "Rogue", HUNTER = "Hunter", SHAMAN = "Shaman", PALADIN = "Paladin", WARRIOR = "Warrior", DEATHKNIGHT = "Death Knight" },
}

local function ItemLink(itemID)
    return select(2, GetItemInfo(itemID)) or ("item:" .. itemID)
end

function CW:SetTitle(text)
    if self.title then self.title:SetText("Chromie Wishlist — " .. tostring(text or "")) end
end

function CW:CreateUI()
    local frame = CreateFrame("Frame", "ChromieWishlistFrame", UIParent)
    self.frame = frame
    frame:SetWidth(760); frame:SetHeight(600)
    frame:SetPoint(self.db.point, UIParent, self.db.relativePoint, self.db.x, self.db.y)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, 0.96)
    frame:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
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
        if CW.viewMode == "wishlist" then
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
            info.checked = CW.db.soundChoice == key
            info.func = function()
                CW:SetSoundChoice(key, true)
            end
            UIDropDownMenu_AddButton(info)
        end
        local info = UIDropDownMenu_CreateInfo()
        info.text = CW:Text("soundImport")
        info.notCheckable = true
        info.func = function() CloseDropDownMenus(); CW:ShowSoundImport() end
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
        if CW.db.sound then CW:PlayAlertSound(true) end
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
        for _, mode in ipairs(difficultyOptions) do
            local value, labelKey = mode.value, mode.labelKey
            local info = UIDropDownMenu_CreateInfo()
            info.text = CW:Text(labelKey); info.value = value
            info.checked = CW.db.browseDifficulty == value
            info.func = function()
                CW.db.browseDifficulty = value
                CW:UpdateBrowserControls()
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
        row.bg:SetAllPoints(); row.bg:SetTexture(1, 1, 1, index % 2 == 0 and 0.035 or 0)
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetWidth(21); row.icon:SetHeight(21); row.icon:SetPoint("LEFT", 2, 0)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", 30, 0); row.name:SetWidth(395); row.name:SetJustifyH("LEFT")
        row.boss = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.boss:SetPoint("LEFT", 420, 0); row.boss:SetWidth(190); row.boss:SetJustifyH("LEFT")
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
    self:UpdateSoundControls()
    self:UpdateFilterControls()
    self:UpdateBrowserControls()
    self:ApplyLanguage()
    self:CreateMinimapButton()
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

function CW:ShowSoundImport()
    self.frame:Show()
    if self.importFrame then self.importFrame:Hide() end
    if not self.soundImportFrame then self:CreateSoundImportUI() end
    self.soundImportTitle:SetText(self:Text("soundImport"))
    self.soundImportHelp:SetText(self:Text("soundImportHelp"))
    self.soundFileLabel:SetText(self:Text("soundFile"))
    self.soundImportTest:SetText(self:Text("soundTest"))
    self.soundImportDefault:SetText(self:Text("soundDefault"))
    self.soundImportSave:SetText(self:Text("soundSave"))
    self.soundImportCancel:SetText(self:Text("cancel"))
    self.soundFileBox:SetText(self.db.customSoundFile or "sound_addon.ogg")
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
        if CW:ImportSoundFile(box:GetText()) then frame:Hide() end
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
        local option = self:GetSoundOption()
        UIDropDownMenu_SetSelectedValue(self.soundDropDown, option.key)
        UIDropDownMenu_SetText(self.soundDropDown, self:GetSoundLabel(option))
    end
    if self.soundEnabled then self.soundEnabled:SetChecked(self.db.sound and 1 or nil) end
    if self.soundDelayDropDown then
        UIDropDownMenu_SetSelectedValue(self.soundDelayDropDown, self.db.soundDelay)
        UIDropDownMenu_SetText(self.soundDelayDropDown, self:GetSoundDelayLabel(self.db.soundDelay))
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
        local selected = difficultyOptions[1]
        for _, mode in ipairs(difficultyOptions) do
            if mode.value == self.db.browseDifficulty then selected = mode; break end
        end
        UIDropDownMenu_SetSelectedValue(self.difficultyDropDown, selected.value)
        UIDropDownMenu_SetText(self.difficultyDropDown, self:Text(selected.labelKey))
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
    self:UpdateSoundControls()
    self:UpdateBrowserControls()
    self:Refresh()
end

function CW:Refresh()
    if not self.frame then return end
    local total = #self.rows
    FauxScrollFrame_Update(self.scroll, total, VISIBLE_ROWS, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(self.scroll)
    for index = 1, VISIBLE_ROWS do
        local widget, data = self.rowFrames[index], self.rows[offset + index]
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
                widget.name:SetWidth(395); widget.name:SetFontObject(GameFontHighlightSmall)
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
