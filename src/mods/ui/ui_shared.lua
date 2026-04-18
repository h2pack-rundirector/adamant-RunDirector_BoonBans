local internal = RunDirectorBoonBans_Internal
local godInfo = internal.godInfo
local uiData = internal.ui

uiData.EMPTY_LIST = {}

uiData.DEFAULT_GOD_COLOR = { 1, 1, 1, 1 }
uiData.DEFAULT_THEME_COLORS = {
    info = { 1, 1, 1, 1 },
    success = { 0.2, 1.0, 0.2, 1.0 },
    warning = { 1.0, 0.8, 0.0, 1.0 },
    error = { 1.0, 0.3, 0.3, 1.0 },
}
uiData.MUTED_TEXT_COLOR = { 0.6, 0.6, 0.6, 1.0 }
uiData.BADGE_COLORS = {
    duo = { 0.82, 1.0, 0.38, 1.0 },
    legendary = { 1.0, 0.56, 0.0, 1.0 },
    infusion = { 1.0, 0.29, 1.0, 1.0 },
}
uiData.RARITY_COLORS = {
    [0] = { 0.7, 0.7, 0.7, 1.0 },
    [1] = { 1.0, 1.0, 1.0, 1.0 },
    [2] = { 0.0, 0.54, 1.0, 1.0 },
    [3] = { 0.62, 0.07, 1.0, 1.0 },
}
uiData.RARITY_LABELS = {
    [0] = "Auto",
    [1] = "Comm",
    [2] = "Rare",
    [3] = "Epic",
}
uiData.NPC_REGION_OPTIONS = {
    { label = "Neither", value = 1 },
    { label = "Underworld", value = 2 },
    { label = "Surface", value = 3 },
    { label = "Both", value = 4 },
}
uiData.BRIDAL_GLOW_VIEW_ID = "__bridal_glow__"
uiData.BAN_FILTER_TEXT_ALIAS = "BanFilterText"
uiData.NPC_VIEW_REGION_ALIAS = "NpcViewRegion"
uiData.DIRECT_BANS_VIEW_ID = "__bans__"
uiData.FORCE_VIEW_ID = "__force__"
uiData.RARITY_VIEW_ID = "__rarity__"

uiData.bridalGlowEligibleRoots = nil
uiData.rarityRowsByRoot = {}
uiData.bridalGlowBoonsByRoot = {}
uiData.bridalGlowSelection = {
    rootKey = nil,
}

function uiData.GetOrdinal(n)
    local s = tostring(n)
    if n % 100 == 11 or n % 100 == 12 or n % 100 == 13 then return s .. "th" end
    local last = n % 10
    if last == 1 then return s .. "st" end
    if last == 2 then return s .. "nd" end
    if last == 3 then return s .. "rd" end
    return s .. "th"
end

function uiData.IsRegionMatch(group, regionValue)
    if regionValue == 4 then return true end
    if group == "Underworld" then
        return regionValue == 2
    end
    if group == "Surface" then
        return regionValue == 3
    end
    return true
end

function uiData.IsRarityEligibleBoon(boon)
    return boon.IsRarityEligible ~= false
end

function uiData.IsBridalGlowEligibleBoon(boon)
    return boon.IsBridalGlowEligible == true
end

function uiData.GetScopeBoons(scopeKey)
    local entry = godInfo[scopeKey]
    if entry and entry.boons then
        return entry.boons
    end
    return uiData.EMPTY_LIST
end

function uiData.FindBoonByKey(scopeKey, boonKey)
    local entry = godInfo[scopeKey]
    if entry and entry.boonByKey then
        return entry.boonByKey[boonKey]
    end

    for _, boon in ipairs(uiData.GetScopeBoons(scopeKey)) do
        if boon.Key == boonKey then
            return boon
        end
    end
end

local function FindAnyBoonByKey(boonKey)
    if type(boonKey) ~= "string" or boonKey == "" then
        return nil
    end

    for _, entry in pairs(godInfo) do
        if type(entry) == "table" and type(entry.boonByKey) == "table" then
            local boon = entry.boonByKey[boonKey]
            if boon then
                return boon
            end
        end
    end
end

local function GetForcedBoonDisplayLabel(boon)
    if not boon then
        return ""
    end
    return boon.SpecialDisplayLabel or uiData.GetBoonText(boon)
end

local function GetBoonMarkerColor(boon)
    return type(boon) == "table" and boon.SpecialBadgeColor or nil
end

function uiData.BuildPackedBanValueColors(scopeKey)
    local colors = {}
    local rootAlias = internal.GetBanRootAlias(scopeKey)
    if type(rootAlias) ~= "string" or rootAlias == "" then
        return colors
    end
    local rootKey = internal.GetRootKey and internal.GetRootKey(scopeKey) or scopeKey
    local rootMeta = internal.godMeta and internal.godMeta[rootKey] or nil
    if type(rootMeta) == "table" and rootMeta.showPackedValueColors == false then
        return colors
    end

    for _, boon in ipairs(uiData.GetScopeBoons(scopeKey)) do
        local color = GetBoonMarkerColor(boon)
        local childAlias = internal.MakeBanAlias(rootAlias, boon.Key)
        if type(childAlias) == "string" and childAlias ~= "" and type(color) == "table" then
            colors[childAlias] = color
        end
    end

    return colors
end

function uiData.BuildPackedBanDisplayValues(scopeKey)
    local displayValues = {}
    local rootAlias = internal.GetBanRootAlias(scopeKey)
    if type(rootAlias) ~= "string" or rootAlias == "" then
        return displayValues
    end

    for _, boon in ipairs(uiData.GetScopeBoons(scopeKey)) do
        local childAlias = internal.MakeBanAlias(rootAlias, boon.Key)
        if type(childAlias) == "string" and childAlias ~= "" then
            displayValues[childAlias] = GetForcedBoonDisplayLabel(boon)
        end
    end

    return displayValues
end

function uiData.GetBoonText(boon)
    return boon.Name or boon.Key or ""
end

function uiData.GetScopeSummary(scopeKey, uiState)
    if uiState then
        local total = 0
        local banned = 0
        local currentBans = internal.GetBanConfig(scopeKey, uiState)
        for _, boon in ipairs(uiData.GetScopeBoons(scopeKey)) do
            total = total + 1
            if bit32.band(currentBans, boon.Mask) ~= 0 then
                banned = banned + 1
            end
        end
        return banned, total
    end

    local entry = godInfo[scopeKey]
    if entry and type(entry.banned) == "number" and type(entry.total) == "number" then
        return entry.banned, entry.total
    end

    local total = 0
    local banned = 0
    local currentBans = internal.GetBanConfig(scopeKey)
    for _, boon in ipairs(uiData.GetScopeBoons(scopeKey)) do
        total = total + 1
        if bit32.band(currentBans, boon.Mask) ~= 0 then
            banned = banned + 1
        end
    end
    return banned, total
end

function uiData.GetVisibleBanCount(scopeKey, uiState)
    if type(scopeKey) ~= "string" or scopeKey == "" then
        return 0
    end

    local filterText = tostring(uiState and uiState.view and uiState.view[uiData.BAN_FILTER_TEXT_ALIAS] or ""):lower()
    local visibleCount = 0

    for _, boon in ipairs(uiData.GetScopeBoons(scopeKey)) do
        local boonText = (boon.NameLower or string.lower(uiData.GetBoonText(boon)))
        local matchesText = filterText == "" or boonText:find(filterText, 1, true) ~= nil
        if matchesText then
            visibleCount = visibleCount + 1
        end
    end

    return visibleCount
end

function uiData.GetSourceColor(scopeKey)
    local entry = godInfo[scopeKey]
    if entry and type(entry.color) == "table" then
        return entry.color
    end
    return uiData.DEFAULT_GOD_COLOR
end

function uiData.IsGodPoolFilteringActive()
    local godPool = rom.mods["adamant-RunDirector_GodPool"]
    if not godPool or not godPool.store or not godPool.definition or type(godPool.isGodEnabledInPool) ~= "function" then
        return false, nil
    end
    if not lib.coordinator.isEnabled(godPool.store, godPool.definition.modpack) then
        return false, nil
    end
    return true, godPool
end

function uiData.IsGodVisibleInGodPool(godKey, godPool)
    local root = internal.GetRootKey and internal.GetRootKey(godKey) or godKey
    return godPool.isGodEnabledInPool(root)
end

function uiData.GetCurrentBridalGlowTargetText(uiState)
    local selectedBoonKey = uiState and uiState.view and uiState.view.BridalGlowTargetBoon or ""
    if selectedBoonKey == nil or selectedBoonKey == "" then
        return "Current Target: Random"
    end

    local boon = FindAnyBoonByKey(selectedBoonKey)
    if boon and uiData.IsBridalGlowEligibleBoon(boon) then
        return "Current Target: " .. (boon.BridalGlowLabel or uiData.GetBoonText(boon))
    end

    return "Current Target: Random"
end

function uiData.GetRootDisplayLabel(rootKey, meta)
    local display = meta.displayTextKey or rootKey
    if meta.maxTiers then
        display = display:gsub("^1st%s+", "")
    end
    return display
end
