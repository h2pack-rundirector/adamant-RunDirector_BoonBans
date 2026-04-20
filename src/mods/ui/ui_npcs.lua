local internal = RunDirectorBoonBans_Internal
local uiData = internal.ui

local NPC_ROOTS = {
    { id = "Arachne", label = "Arachne", group = "Underworld", primaryScopeKey = "Arachne", hasRarity = false },
    { id = "Narcissus", label = "Narcissus", group = "Underworld", primaryScopeKey = "Narcissus", hasRarity = false },
    { id = "Echo", label = "Echo", group = "Underworld", primaryScopeKey = "Echo", hasRarity = false },
    { id = "Hades", label = "Hades", group = "Underworld", primaryScopeKey = "Hades", hasRarity = false },
    { id = "Medea", label = "Medea", group = "Surface", primaryScopeKey = "Medea", hasRarity = false },
    { id = "Circe", label = "Circe", group = "Surface", primaryScopeKey = "Circe", hasRarity = false },
    { id = "Icarus", label = "Icarus", group = "Surface", primaryScopeKey = "Icarus", hasRarity = false },
    { id = "Dionysus", label = "Dionysus", group = "Surface", primaryScopeKey = "Dionysus", hasRarity = true },
    { id = "CirceBNB", label = "Black Night Banishment", group = "Surface", primaryScopeKey = "CirceBNB", hasRarity = false },
    { id = "CirceCRD", label = "Red Citrine Divination", group = "Surface", primaryScopeKey = "CirceCRD", hasRarity = false },
    { id = "HadesKeepsake", label = "Jeweled Pom", group = "Keepsakes", primaryScopeKey = "HadesKeepsake", hasRarity = false },
}

for _, root in ipairs(NPC_ROOTS) do
    root.scopes = {
        { key = root.primaryScopeKey, label = "Bans" },
    }
end

internal.uiLeanState = internal.uiLeanState or {}
internal.uiLeanState.activeNpcRoot = internal.uiLeanState.activeNpcRoot or "Arachne"
internal.uiLeanState.activeNpcViewByRoot = internal.uiLeanState.activeNpcViewByRoot or {}

local function IsRootCustomized(root, session)
    local banned = uiData.GetScopeSummary(root.primaryScopeKey, session)
    return banned > 0
end

local function GetVisibleNpcRoots(session)
    local regionValue = session and session.view and session.view[uiData.NPC_VIEW_REGION_ALIAS] or 4
    local roots = {}
    for _, root in ipairs(NPC_ROOTS) do
        if uiData.IsRegionMatch(root.group, regionValue) then
            roots[#roots + 1] = root
        end
    end
    return roots
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
        if root.id == internal.uiLeanState.activeNpcRoot then
            return root
        end
    end
    return visibleRoots[1]
end

local function DrawRegionFilter(ui, session)
    local displayValues = {}
    local values = {}
    for _, option in ipairs(uiData.NPC_REGION_OPTIONS) do
        values[#values + 1] = option.value
        displayValues[option.value] = option.label
    end

    ui.AlignTextToFramePadding()
    ui.Text("Filter NPC Sources:")
    ui.SameLine()
    lib.widgets.radio(ui, session, uiData.NPC_VIEW_REGION_ALIAS, {
        label = "",
        values = values,
        displayValues = displayValues,
        optionGap = 20,
    })
end

local function DrawBanPanel(ui, session, root)
    internal.DrawBanSearchControls(ui, session, root.primaryScopeKey)
    ui.SameLine()
    ui.SetCursorPosX(ui.GetCursorPosX() + 100)

    lib.widgets.button(ui, "Ban All", {
        id = "npcs_ban_all_" .. root.primaryScopeKey,
        onClick = function()
            internal.BanAllGodBans(root.primaryScopeKey, session)
        end,
    })
    ui.SameLine()
    lib.widgets.button(ui, "Reset", {
        id = "npcs_reset_" .. root.primaryScopeKey,
        onClick = function()
            internal.ResetGodBans(root.primaryScopeKey, session)
        end,
    })

    lib.widgets.separator(ui)
    internal.DrawFilteredPackedBanList(ui, session, root.primaryScopeKey)
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

function internal.DrawNpcsTab(ui, session)
    DrawRegionFilter(ui, session)
    ui.Spacing()

    local visibleRoots = GetVisibleNpcRoots(session)
    if #visibleRoots == 0 then
        lib.widgets.text(ui, "No NPC sources match the current filter.", {
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
            group = root.group,
        }
    end

    internal.uiLeanState.activeNpcRoot = lib.nav.verticalTabs(ui, {
        id = "BoonBansNpcsTabs",
        navWidth = 260,
        tabs = tabs,
        activeKey = internal.uiLeanState.activeNpcRoot,
    })

    local root = GetActiveRoot(visibleRoots)

    ui.BeginChild("BoonBansNpcsDetail", 0, 0, false)
    if ui.BeginTabBar("BoonBansNpcsViews##" .. root.id) then
        if ui.BeginTabItem("Bans") then
            internal.uiLeanState.activeNpcViewByRoot[root.id] = "bans"
            DrawBanPanel(ui, session, root)
            ui.EndTabItem()
        end
        if root.hasRarity and ui.BeginTabItem("Rarity") then
            internal.uiLeanState.activeNpcViewByRoot[root.id] = "rarity"
            DrawRarityPanel(ui, session, root)
            ui.EndTabItem()
        end
        ui.EndTabBar()
    end
    ui.EndChild()
end
