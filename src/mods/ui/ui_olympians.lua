local internal = RunDirectorBoonBans_Internal
local uiData = internal.ui

local OLYMPIAN_ROOTS = {
    { id = "Aphrodite", label = "Aphrodite" },
    { id = "Apollo", label = "Apollo" },
    { id = "Ares", label = "Ares" },
    { id = "Demeter", label = "Demeter" },
    { id = "Hephaestus", label = "Hephaestus" },
    { id = "Hera", label = "Hera", hasBridalGlow = true },
    { id = "Hestia", label = "Hestia" },
    { id = "Poseidon", label = "Poseidon" },
    { id = "Zeus", label = "Zeus" },
}

for _, root in ipairs(OLYMPIAN_ROOTS) do
    root.primaryScopeKey = root.id
    root.hasRarity = true
    root.scopes = {
        { key = root.id, label = "1st" },
        { key = root.id .. "2", label = "2nd" },
        { key = root.id .. "3", label = "3rd" },
        { key = root.id .. "4", label = "4th" },
        { key = root.id .. "5", label = "5th" },
    }
end

internal.uiLeanState = internal.uiLeanState or {}
internal.uiLeanState.activeOlympianRoot = internal.uiLeanState.activeOlympianRoot or "Aphrodite"
internal.uiLeanState.activeOlympianViewByRoot = internal.uiLeanState.activeOlympianViewByRoot or {}

local function IsRootCustomized(root, session)
    for _, scope in ipairs(root.scopes) do
        local banned = uiData.GetScopeSummary(scope.key, session)
        if banned > 0 then
            return true
        end
    end
    return false
end

local function GetVisibleOlympianRoots()
    local godPoolFiltering, godPool = uiData.IsGodPoolFilteringActive()
    local roots = {}
    for _, root in ipairs(OLYMPIAN_ROOTS) do
        if not godPoolFiltering or uiData.IsGodVisibleInGodPool(root.id, godPool) then
            roots[#roots + 1] = root
        end
    end
    return roots, godPoolFiltering
end

local function GetNavLabel(root, session)
    local label = root.label
    if IsRootCustomized(root, session) then
        label = label .. " *"
    end
    return label
end

local function GetActiveRoot(visibleRoots)
    for _, root in ipairs(visibleRoots) do
        if root.id == internal.uiLeanState.activeOlympianRoot then
            return root
        end
    end
    return visibleRoots[1]
end

local function DrawForceRow(ui, session, scope)
    local bindAlias = internal.GetBanRootAlias(scope.key)
    if not bindAlias then
        return
    end

    ui.AlignTextToFramePadding()
    ui.Text(scope.label)
    ui.SameLine()
    ui.SetCursorPosX(80)
    lib.widgets.packedDropdown(ui, session, bindAlias, internal.store, {
        label = "",
        selectionMode = "singleRemaining",
        noneLabel = "None",
        multipleLabel = "Multiple",
        displayValues = uiData.BuildPackedBanDisplayValues(scope.key),
        valueColors = uiData.BuildPackedBanValueColors(scope.key),
        controlWidth = 220,
    })
end

local function DrawForcePanel(ui, session, root)
    lib.widgets.text(ui, "Force")
    lib.widgets.separator(ui)
    for _, scope in ipairs(root.scopes) do
        DrawForceRow(ui, session, scope)
    end
end

local function DrawBanPanel(ui, session, scope)
    internal.DrawBanSearchControls(ui, session, scope.key)
    ui.SameLine()
    ui.SetCursorPosX(ui.GetCursorPosX() + 100)

    lib.widgets.button(ui, "Ban All", {
        id = "olympians_ban_all_" .. scope.key,
        onClick = function()
            internal.BanAllGodBans(scope.key, session)
        end,
    })
    ui.SameLine()
    lib.widgets.button(ui, "Reset", {
        id = "olympians_reset_" .. scope.key,
        onClick = function()
            internal.ResetGodBans(scope.key, session)
        end,
    })

    lib.widgets.separator(ui)
    internal.DrawFilteredPackedBanList(ui, session, scope.key)
end

local function DrawRarityPanel(ui, session, root)
    for _, boon in ipairs(uiData.GetScopeBoons(root.primaryScopeKey)) do
        if uiData.IsRarityEligibleBoon(boon) then
            local rarityAlias = internal.GetRarityAlias(root.primaryScopeKey, boon.Key)
            if rarityAlias then
                ui.AlignTextToFramePadding()
                ui.Text(uiData.GetBoonText(boon))
                ui.SameLine()
                ui.SetCursorPosX(220)
                lib.widgets.dropdown(ui, session, rarityAlias, {
                    label = "",
                    values = { 0, 1, 2, 3 },
                    displayValues = uiData.RARITY_LABELS,
                    valueColors = uiData.RARITY_COLORS,
                    controlWidth = 120,
                })
            end
        end
    end
end

local function GetBridalGlowEligibleRoots()
    if uiData.bridalGlowEligibleRoots then
        return uiData.bridalGlowEligibleRoots
    end

    local visibleRoots = GetVisibleOlympianRoots()
    local cached = {}
    for _, root in ipairs(visibleRoots) do
        cached[#cached + 1] = root
    end
    uiData.bridalGlowEligibleRoots = cached
    return cached
end

local function GetBridalGlowEligibleBoons(root)
    if not root then
        return uiData.EMPTY_LIST
    end

    local cached = uiData.bridalGlowBoonsByRoot[root.id]
    if cached then
        return cached
    end

    local boons = {}
    for _, boon in ipairs(uiData.GetScopeBoons(root.primaryScopeKey)) do
        if uiData.IsBridalGlowEligibleBoon(boon) then
            boon.BridalGlowLabel = boon.BridalGlowLabel or uiData.GetBoonText(boon)
            boons[#boons + 1] = boon
        end
    end
    uiData.bridalGlowBoonsByRoot[root.id] = boons
    return boons
end

local function FindBridalGlowRootForTarget(roots, selectedBoonKey)
    if not selectedBoonKey or selectedBoonKey == "" then
        return nil
    end

    for _, root in ipairs(roots) do
        local boon = uiData.FindBoonByKey(root.primaryScopeKey, selectedBoonKey)
        if boon and uiData.IsBridalGlowEligibleBoon(boon) then
            return root
        end
    end
    return nil
end

local function EnsureBridalGlowRootSelection(roots, selectedBoonKey)
    local transientRootKey = uiData.bridalGlowSelection.rootKey
    if transientRootKey then
        for _, root in ipairs(roots) do
            if root.id == transientRootKey then
                return root
            end
        end
    end

    local matchedRoot = FindBridalGlowRootForTarget(roots, selectedBoonKey)
    if matchedRoot then
        uiData.bridalGlowSelection.rootKey = matchedRoot.id
        return matchedRoot
    end

    local fallback = roots[1]
    uiData.bridalGlowSelection.rootKey = fallback and fallback.id or nil
    return fallback
end

local function DrawBridalGlowPanel(ui, session)
    local selectedBoonKey = session.view.BridalGlowTargetBoon or ""
    local eligibleRoots = GetBridalGlowEligibleRoots()

    lib.widgets.text(ui, "Choose the Olympian god and boon pool Bridal Glow can target.")
    lib.widgets.text(ui, uiData.GetCurrentBridalGlowTargetText(session))
    lib.widgets.separator(ui)

    if #eligibleRoots == 0 then
        lib.widgets.text(ui, "No eligible Olympian gods are currently available.", {
            color = uiData.MUTED_TEXT_COLOR,
        })
        return
    end

    local selectedRoot = EnsureBridalGlowRootSelection(eligibleRoots, selectedBoonKey)
    local selectedRootId = selectedRoot and selectedRoot.id or nil
    local eligibleBoons = GetBridalGlowEligibleBoons(selectedRoot)

    ui.BeginChild("BoonBansBridalGlowGods", 220, 220, true)
    lib.widgets.text(ui, "Eligible Gods", {
        color = uiData.MUTED_TEXT_COLOR,
    })
    lib.widgets.separator(ui)
    for _, root in ipairs(eligibleRoots) do
        if ui.Selectable(root.label, root.id == selectedRootId) then
            uiData.bridalGlowSelection.rootKey = root.id
            selectedRoot = root
            selectedRootId = root.id
            eligibleBoons = GetBridalGlowEligibleBoons(selectedRoot)
        end
    end
    ui.EndChild()

    ui.SameLine()

    ui.BeginChild("BoonBansBridalGlowBoons", 0, 220, true)
    lib.widgets.text(ui, "Eligible Boons", {
        color = uiData.MUTED_TEXT_COLOR,
    })
    lib.widgets.separator(ui)
    if ui.Selectable("Random", selectedBoonKey == "") then
        internal.SetBridalGlowTargetBoonKey(nil, session)
        selectedBoonKey = ""
    end
    for _, boon in ipairs(eligibleBoons) do
        if ui.Selectable(boon.BridalGlowLabel, boon.Key == selectedBoonKey) then
            internal.SetBridalGlowTargetBoonKey(boon.Key, session)
            selectedBoonKey = boon.Key
        end
    end
    ui.EndChild()
end

function internal.DrawOlympiansTab(ui, session)
    local visibleRoots, godPoolFiltering = GetVisibleOlympianRoots()
    if #visibleRoots == 0 then
        lib.widgets.text(ui, "No Olympians are currently available.", {
            color = uiData.MUTED_TEXT_COLOR,
        })
        return
    end

    local tabs = {}
    for _, root in ipairs(visibleRoots) do
        tabs[#tabs + 1] = {
            key = root.id,
            label = GetNavLabel(root, session),
            color = uiData.GetSourceColor(root.primaryScopeKey),
        }
    end

    internal.uiLeanState.activeOlympianRoot = lib.nav.verticalTabs(ui, {
        id = "BoonBansOlympiansTabs",
        navWidth = 260,
        tabs = tabs,
        activeKey = internal.uiLeanState.activeOlympianRoot,
    })

    local root = GetActiveRoot(visibleRoots)

    ui.BeginChild("BoonBansOlympiansDetail", 0, 0, false)
    if godPoolFiltering then
        lib.widgets.text(ui, string.format("Showing %d Olympians enabled in God Pool.", #visibleRoots), {
            color = uiData.MUTED_TEXT_COLOR,
        })
        ui.Spacing()
    end

    if ui.BeginTabBar("BoonBansOlympiansViews##" .. root.id) then
        if ui.BeginTabItem("Force") then
            internal.uiLeanState.activeOlympianViewByRoot[root.id] = "force"
            DrawForcePanel(ui, session, root)
            ui.EndTabItem()
        end
        for _, scope in ipairs(root.scopes) do
            if ui.BeginTabItem(scope.label) then
                internal.uiLeanState.activeOlympianViewByRoot[root.id] = scope.key
                DrawBanPanel(ui, session, scope)
                ui.EndTabItem()
            end
        end
        if ui.BeginTabItem("Rarity") then
            internal.uiLeanState.activeOlympianViewByRoot[root.id] = "rarity"
            DrawRarityPanel(ui, session, root)
            ui.EndTabItem()
        end
        if root.hasBridalGlow and ui.BeginTabItem("Bridal Glow Target") then
            internal.uiLeanState.activeOlympianViewByRoot[root.id] = "bridal_glow"
            DrawBridalGlowPanel(ui, session)
            ui.EndTabItem()
        end
        ui.EndTabBar()
    end
    ui.EndChild()
end
