local CW = _G.ChromieWishlist

-- Les listes natives (pas les pages d'affichage AtlasLoot) contiennent les
-- objets aux indices numériques et leurs métadonnées dans la clé "info".
function CW:GetAtlasWishlists()
    local result = {}
    local database = AtlasLootWishList
    if type(database) ~= "table" then return result end
    local player = UnitName("player")
    for _, group in ipairs({ "Own", "Shared" }) do
        local owners = database[group]
        if type(owners) == "table" then
            for owner, lists in pairs(owners) do
                if type(lists) == "table" then
                    for key, list in pairs(lists) do
                        if type(list) == "table" and type(list.info) == "table" then
                            local name = tostring(list.info[1] or key)
                            local label = tostring(owner) .. " - " .. name
                            if group == "Shared" then label = self:Text("importShared") .. " : " .. label end
                            result[#result + 1] = {
                                group = group, owner = owner, key = key, name = name, label = label,
                                order = group == "Shared" and 3 or (owner == player and 1 or 2),
                            }
                        end
                    end
                end
            end
        end
    end
    table.sort(result, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        if a.label ~= b.label then return a.label < b.label end
        return tostring(a.key) < tostring(b.key)
    end)
    return result
end

local function ImportItemID(value)
    local id
    if type(value) == "number" then
        id = value
    elseif type(value) == "string" then
        id = tonumber(value) or tonumber(value:match("item:(%d+)"))
    end
    -- AtlasLoot peut aussi contenir des sorts ("s123"), titres et séparateurs.
    if id and id > 0 and id < math.huge and id == math.floor(id) then return id end
end

function CW:GetAtlasImportSource(data, itemID)
    local tableID = type(data[8]) == "string" and data[8]:match("^([^|]+)") or nil
    local source = self:FindItemSource(itemID, tableID)
    if not source and tableID then source = self:FindItemSource(itemID) end
    if source then return source end
    -- Les objets hors des tables d'instances restent importables, même si
    -- GetItemInfo ne les connaît pas encore (pas de filtrage par classe).
    local boss = type(data[5]) == "string" and data[5] or nil
    if boss then
        boss = boss:gsub("=%a%d=", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        if boss == "" then boss = nil end
    end
    return { tableID = tableID, boss = boss }
end

function CW:ImportAtlasWishlist(selection)
    if not self.db or type(selection) ~= "table" then return nil end
    local database = AtlasLootWishList
    local owners = type(database) == "table" and database[selection.group]
    local lists = type(owners) == "table" and owners[selection.owner]
    local list = type(lists) == "table" and lists[selection.key]
    if type(list) ~= "table" or type(list.info) ~= "table" then
        self:Print(self:Text("importMissing"))
        return nil
    end

    local added, duplicates, invalid = 0, 0, 0
    for index, data in pairs(list) do
        if type(index) == "number" and index > 0 and index == math.floor(index) then
            local itemID = type(data) == "table" and ImportItemID(data[2])
            if not itemID then
                invalid = invalid + 1
            elseif self.db.wishlist[tostring(itemID)] ~= nil then
                duplicates = duplicates + 1
            else
                local source = self:GetAtlasImportSource(data, itemID)
                -- Ajout groupé : un seul rafraîchissement à la fin de l'import.
                self.db.wishlist[tostring(itemID)] = {
                    priority = 3, instance = source.instance, boss = source.boss,
                    tableID = source.tableID, sourceChecked = true,
                }
                added = added + 1
            end
        end
    end
    self:BuildWishlistRows()
    if self.SetTitle then self:SetTitle(self:Text("wishlist")) end
    if self.scroll then
        FauxScrollFrame_SetOffset(self.scroll, 0)
        local scrollBar = _G[self.scroll:GetName() .. "ScrollBar"]
        if scrollBar then scrollBar:SetValue(0) end
    end
    if self.Refresh then self:Refresh() end
    if self.frame then self.frame:Show() end
    self:Print(self:Text("importResult", tostring(list.info[1] or selection.key), added, duplicates, invalid))
    return added, duplicates, invalid
end
