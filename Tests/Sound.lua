-- Exécuter depuis le dossier de l'addon avec Lua 5.1 : lua Tests/Sound.lua
-- Ce fichier n'est pas chargé en jeu.
local checks = 0
local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

local function widget(name)
    return setmetatable({ name = name, scripts = {} }, { __index = function(_, key)
        if key == "SetScript" then return function(self, event, fn) self.scripts[event] = fn end end
        if key == "GetName" then return function(self) return self.name end end
        if key == "CreateFontString" then return function() return widget() end end
        if key == "SetText" then return function(self, text) self.text = text end end
        if key == "GetText" then return function(self) return self.text end end
        if key == "SetFocus" then return function(self) self.focus = true end end
        if key == "ClearFocus" then return function(self) self.focus = false end end
        if key == "Show" then return function(self) self.shown = true end end
        if key == "Hide" then return function(self)
            self.shown = false
            if self.scripts.OnHide then self.scripts.OnHide(self) end
        end end
        return function() end
    end })
end

CreateFrame = function(_, name) return widget(name) end
SlashCmdList = {}
local now, sounds, messages = 100, {}, {}
GetTime = function() return now end
PlaySoundFile = function(path) sounds[#sounds + 1] = path end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) messages[#messages + 1] = text end }
UIDropDownMenu_SetSelectedValue = function(frame, value) frame.value = value end
UIDropDownMenu_SetText = function(frame, text) frame.text = text end

assert(loadfile("Core.lua"))("ChromieWishlist")
assert(loadfile("UI.lua"))()
local CW = ChromieWishlist
local prefix = "Interface\\AddOns\\ChromieWishlist\\Media\\"
CW.db = { language = "fr", sound = true, soundChoice = "custom", soundDelay = 5 }
CW.frame = widget("MainFrame")
CW.soundDropDown = widget("SoundDropDown")

check(CW:GetSoundOption().path == prefix .. "sound_addon.ogg", "existing saves retain original sound")
check(CW:NormalizeSoundFile("  Alertes/Mon son.OGG  ") == "Alertes\\Mon son.OGG", "trim and normalize relative paths")
check(CW:NormalizeSoundFile("loot.wav") == "loot.wav", "wav accepted")
check(CW:NormalizeSoundFile("loot.mp3") == "loot.mp3", "mp3 accepted")
for _, value in ipairs({ "", "   ", "../loot.ogg", "Alertes/../loot.ogg", "C:\\loot.ogg",
    "\\loot.ogg", "//server/loot.ogg", "loot.txt", "loot.ogg.exe", "loot.ogg/", "loot.ogg\ninvalid",
    "a|b.ogg", "a*b.ogg", "a?b.ogg", 'a"b.ogg', "./loot.ogg", "A//loot.ogg", "A. /loot.ogg",
    string.rep("a", 241) .. ".ogg" }) do
    check(CW:NormalizeSoundFile(value) == nil, "invalid path rejected: " .. value)
end
check(CW:NormalizeSoundFile(false) == nil, "non-string rejected")
check(CW:NormalizeSoundFile(nil) == nil, "missing filename rejected")

check(CW:ImportSoundFile(" Alertes/loot.ogg "), "relative file imported")
check(CW.db.customSoundFile == "Alertes\\loot.ogg", "normalized filename saved")
check(CW.db.soundChoice == "custom" and CW.soundDropDown.value == "custom", "custom sound selected and UI updated")
check(sounds[#sounds] == prefix .. "Alertes\\loot.ogg", "import previews chosen file")
check(CW.soundOptions[1].path == prefix .. "sound_addon.ogg", "bundled definition unchanged")
local count = #sounds
check(not CW:ImportSoundFile("C:\\invalid.ogg"), "bad import fails")
check(CW.db.customSoundFile == "Alertes\\loot.ogg" and #sounds == count, "bad import does not change or play sound")
CW:SetSoundChoice("raid", false)
check(CW:PreviewSoundFile("other.wav"), "preview succeeds")
check(sounds[#sounds] == prefix .. "other.wav" and CW.db.soundChoice == "raid", "preview does not change choice")
check(CW.db.customSoundFile == "Alertes\\loot.ogg", "preview does not change saved file")
count = #sounds
check(not CW:PreviewSoundFile("invalid.exe") and #sounds == count, "invalid preview rejected")
CW:SetSoundChoice("custom", false)
CW:PlayAlertSound(false)
check(CW.lastAlertSoundTime == 100 and sounds[#sounds] == prefix .. "Alertes\\loot.ogg", "alert uses imported sound")
count = #sounds
now = 102
CW:PlayAlertSound(false)
check(#sounds == count, "alert cooldown preserved")
CW:PreviewSoundFile("preview.mp3")
check(#sounds == count + 1 and CW.lastAlertSoundTime == 100, "preview bypasses and preserves cooldown")
now = 105
CW:PlayAlertSound(false)
check(#sounds == count + 2, "alert resumes after delay")
CW.db.sound = false
count = #sounds
CW:PlayAlertSound(false)
check(#sounds == count, "disabled alert stays silent")
CW:PlayAlertSound(true)
check(#sounds == count + 1, "forced test works when disabled")
check(CW:GetSoundOption("unknown").path == prefix .. "Alertes\\loot.ogg", "unknown choice falls back to custom")
CW.db.customSoundFile = "../invalid.ogg"
check(CW:GetSoundOption("custom").path == prefix .. "sound_addon.ogg", "corrupt saved path falls back to original")
CW.db.customSoundFile = "Alertes\\loot.ogg"

CW.importFrame = widget("AtlasImport")
CW.importFrame:Show()
SlashCmdList.CHROMIEWISHLIST("importsound")
check(CW.frame.shown and CW.soundImportFrame.shown and not CW.importFrame.shown, "command opens dialog and hides Atlas import")
check(CW.soundFileBox.text == "Alertes\\loot.ogg" and CW.soundFileBox.focus, "dialog loads saved name and focuses input")
check(CW.soundImportTitle.text == CW:Text("soundImport"), "localized title")
CW.soundFileBox:SetText("draft.wav")
CW.soundImportTest.scripts.OnClick()
check(sounds[#sounds] == prefix .. "draft.wav" and CW.db.customSoundFile == "Alertes\\loot.ogg", "dialog test does not save")
CW.soundImportCancel.scripts.OnClick()
check(not CW.soundImportFrame.shown and not CW.soundFileBox.focus, "cancel hides dialog and clears focus")
CW:ShowSoundImport()
check(CW.soundFileBox.text == "Alertes\\loot.ogg", "cancel discards unsaved input")
CW.soundFileBox:SetText("bad.exe")
CW.soundImportSave.scripts.OnClick()
check(CW.soundImportFrame.shown, "invalid file keeps dialog open")
CW.soundFileBox:SetText("new.mp3")
CW.soundFileBox.scripts.OnEnterPressed()
check(CW.db.customSoundFile == "new.mp3" and not CW.soundImportFrame.shown, "enter saves and closes dialog")
check(CW.db.sound == false, "import preserves disabled setting")
CW:ShowSoundImport()
CW.soundImportDefault.scripts.OnClick()
check(CW.soundFileBox.text == "sound_addon.ogg" and CW.db.customSoundFile == "new.mp3", "original button only edits draft")
CW.soundImportSave.scripts.OnClick()
check(CW.db.customSoundFile == "sound_addon.ogg", "original sound can be restored")
CW.db.language = "en"
CW:ShowSoundImport()
check(CW.soundImportSave.text == "Use this sound", "English dialog")
CW.soundFileBox.scripts.OnEscapePressed()
check(not CW.soundImportFrame.shown, "escape closes dialog")

print("OK - " .. checks .. " sound checks (Lua " .. _VERSION:match("[%d.]+") .. ")")
