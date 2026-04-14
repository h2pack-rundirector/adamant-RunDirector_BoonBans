local internal = RunDirectorBoonBans_Internal
local godMeta = internal.godMeta
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
uiData.TAB_BY_GROUP = {
    Core = "Olympians",
    Bonus = "Other Gods",
    Hammers = "Hammers",
    ["UW NPC"] = "NPCs",
    ["SF NPC"] = "NPCs",
    Keepsakes = "NPCs",
}
uiData.GROUP_ORDER = {
    Core = 1,
    Bonus = 2,
    Hammers = 3,
    ["UW NPC"] = 4,
    ["SF NPC"] = 5,
    Keepsakes = 6,
}
uiData.BAN_FILTER_MODES = {
    { id = "all", label = "All" },
    { id = "checked", label = "Banned" },
    { id = "unchecked", label = "Allowed" },
}
uiData.BAN_FILTER_MODE_SET = {
    all = true,
    checked = true,
    unchecked = true,
}
uiData.BAN_FILTER_TEXT_ALIAS = "BanFilterText"
uiData.BAN_FILTER_MODE_ALIAS = "BanFilterMode"
uiData.BRIDAL_GLOW_TARGET_TEXT_ALIAS = "Ui_BridalGlowCurrentTargetText"
uiData.NPC_VIEW_REGION_ALIAS = "NpcViewRegion"
uiData.DIRECT_BANS_VIEW_ID = "__bans__"
uiData.FORCE_VIEW_ID = "__force__"
uiData.RARITY_VIEW_ID = "__rarity__"
uiData.CONFIRM_TIMEOUT = 5.0
uiData.BAN_LABEL_START = 28

uiData.rootDescriptors = nil
uiData.rootsByMainTab = nil
uiData.rootIdByScopeKey = nil
uiData.visibleRootsByMainTab = {}
uiData.bridalGlowEligibleRoots = nil
uiData.rarityRowsByRoot = {}
uiData.bridalGlowBoonsByRoot = {}
uiData.banFilterState = {
    rootId = nil,
}
uiData.cachedEquippedWeaponName = ""
uiData.bridalGlowSelection = {
    rootKey = nil,
}
uiData.activeBridalGlowRootId = nil
uiData.derivedTextEntries = nil
uiData.derivedTextCache = {}

function uiData.GetBanSummaryAlias(scopeKey)
    return "Ui_BanSummary_" .. tostring(scopeKey)
end

function uiData.GetBanEmptyStateAlias(scopeKey)
    return "Ui_BanEmptyState_" .. tostring(scopeKey)
end

function uiData.GetSelectedRootAlias(tabName)
    return "SelectedRoot_" .. tostring(tabName)
end

function uiData.GetThemeColors(theme)
    return (theme and theme.colors) or uiData.DEFAULT_THEME_COLORS
end

function uiData.DrawColoredText(ui, color, text)
    ui.TextColored(color[1], color[2], color[3], color[4], text)
end

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
    if group == "UW NPC" then
        return regionValue == 2
    end
    if group == "SF NPC" then
        return regionValue == 3
    end
    return true
end

function uiData.IsSpecialBoon(boon)
    return boon.IsSpecial == true
end

function uiData.IsRarityEligibleBoon(boon)
    return boon.IsRarityEligible ~= false
end

function uiData.IsBridalGlowEligibleBoon(boon)
    return boon.IsBridalGlowEligible == true
end

function uiData.FormatCountLabel(banned, total)
    return string.format("(%d/%d Banned)", banned, total)
end

function uiData.GetBanLabelStart()
    return uiData.BAN_LABEL_START
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

function uiData.FindAnyBoonByKey(boonKey)
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

function uiData.GetForcedBoonSelection(scopeKey, packedMask)
    local boons = uiData.GetScopeBoons(scopeKey)
    local allowedBoon = nil
    local banned = 0
    local total = 0

    for _, boon in ipairs(boons) do
        total = total + 1
        if bit32.band(packedMask or 0, boon.Mask) ~= 0 then
            banned = banned + 1
        else
            allowedBoon = boon
        end
    end

    if banned == 0 then
        return nil, true, false
    end
    if total == 0 or banned ~= (total - 1) then
        return nil, false, true
    end
    return allowedBoon, false, false
end

function uiData.GetForcedBoonDisplayLabel(boon)
    if not boon then
        return ""
    end
    return boon.SpecialDisplayLabel or uiData.GetBoonText(boon)
end

function uiData.GetBoonMarkerColor(boon)
    return type(boon) == "table" and boon.SpecialBadgeColor or nil
end

function uiData.BuildPackedBanValueColors(scopeKey)
    local colors = {}
    local rootAlias = internal.GetBanRootAlias(scopeKey)
    if type(rootAlias) ~= "string" or rootAlias == "" then
        return colors
    end

    for _, boon in ipairs(uiData.GetScopeBoons(scopeKey)) do
        local color = uiData.GetBoonMarkerColor(boon)
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
            displayValues[childAlias] = uiData.GetForcedBoonDisplayLabel(boon)
        end
    end

    return displayValues
end

function uiData.GetRootMeta(rootKey)
    return godMeta[rootKey]
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

function uiData.GetEquippedWeaponName()
    if GetEquippedWeapon then
        return GetEquippedWeapon() or ""
    end
    return ""
end

function uiData.GetCurrentBridalGlowTargetText(uiState)
    local selectedBoonKey = uiState and uiState.view and uiState.view.BridalGlowTargetBoon or ""
    if selectedBoonKey == nil or selectedBoonKey == "" then
        return "Current Target: Random"
    end

    local boon = uiData.FindAnyBoonByKey(selectedBoonKey)
    if boon and uiData.IsBridalGlowEligibleBoon(boon) then
        return "Current Target: " .. (boon.BridalGlowLabel or uiData.GetBoonText(boon))
    end

    return "Current Target: Random"
end

local function BuildDerivedTextEntries()
    local entries = {}
    local scopeKeys = {}
    for scopeKey, entry in pairs(internal.godInfo or {}) do
        if type(scopeKey) == "string" and type(entry) == "table" and type(entry.boons) == "table" then
            scopeKeys[#scopeKeys + 1] = scopeKey
        end
    end
    table.sort(scopeKeys)

    for _, scopeKey in ipairs(scopeKeys) do
        entries[#entries + 1] = {
            alias = uiData.GetBanSummaryAlias(scopeKey),
            signature = function(uiState)
                local banned, total = uiData.GetScopeSummary(scopeKey, uiState)
                return tostring(banned) .. "/" .. tostring(total)
            end,
            compute = function(uiState)
                local banned, total = uiData.GetScopeSummary(scopeKey, uiState)
                return uiData.FormatCountLabel(banned, total)
            end,
        }
        entries[#entries + 1] = {
            alias = uiData.GetBanEmptyStateAlias(scopeKey),
            signature = function(uiState)
                local currentBans = internal.GetBanConfig(scopeKey, uiState) or 0
                local filterText = tostring(uiState and uiState.view and uiState.view[uiData.BAN_FILTER_TEXT_ALIAS] or ""):lower()
                local filterMode = uiData.GetNormalizedBanFilterMode(uiState)
                return tostring(currentBans) .. "|" .. filterText .. "|" .. filterMode
            end,
            compute = function(uiState)
                if uiData.GetVisibleBanCount(scopeKey, uiState) == 0 then
                    return "No boons match the current filter."
                end
                return ""
            end,
        }
    end

    entries[#entries + 1] = {
        alias = uiData.BRIDAL_GLOW_TARGET_TEXT_ALIAS,
        signature = function(uiState)
            local selectedBoonKey = uiState and uiState.view and uiState.view.BridalGlowTargetBoon or ""
            return tostring(selectedBoonKey)
        end,
        compute = function(uiState)
            return uiData.GetCurrentBridalGlowTargetText(uiState)
        end,
    }

    return entries
end

function uiData.RefreshFrameState(uiState)
    uiData.cachedEquippedWeaponName = uiData.GetEquippedWeaponName()
    if not uiData.derivedTextEntries then
        uiData.derivedTextEntries = BuildDerivedTextEntries()
    end
    lib.special.runDerivedText(uiState, uiData.derivedTextEntries, uiData.derivedTextCache)
end

function uiData.InvalidateBridalGlowRootCache()
    uiData.bridalGlowEligibleRoots = nil
end

function uiData.GetRootDisplayLabel(rootKey, meta)
    local display = meta.displayTextKey or rootKey
    if meta.maxTiers then
        display = display:gsub("^1st%s+", "")
    end
    return display
end
