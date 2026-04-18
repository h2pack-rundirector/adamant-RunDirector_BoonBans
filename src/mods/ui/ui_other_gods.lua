local internal = RunDirectorBoonBans_Internal
local uiData = internal.ui

local OTHER_GOD_ROOTS = {
    {
        id = "Hermes",
        label = "Hermes",
        primaryScopeKey = "Hermes",
        hasRarity = true,
        scopes = {
            { key = "Hermes", label = "1st" },
            { key = "Hermes2", label = "2nd" },
        },
    },
    {
        id = "Selene",
        label = "Selene",
        primaryScopeKey = "Selene",
        hasRarity = false,
        scopes = {
            { key = "Selene", label = "Bans" },
        },
    },
    {
        id = "Artemis",
        label = "Artemis",
        primaryScopeKey = "Artemis",
        hasRarity = true,
        scopes = {
            { key = "Artemis", label = "Bans" },
        },
    },
    {
        id = "Athena",
        label = "Athena",
        primaryScopeKey = "Athena",
        hasRarity = true,
        scopes = {
            { key = "Athena", label = "Bans" },
        },
    },
    {
        id = "ChaosBuffs",
        label = "Chaos Buffs",
        primaryScopeKey = "ChaosBuffs",
        hasRarity = false,
        scopes = {
            { key = "ChaosBuffs", label = "Bans" },
        },
    },
    {
        id = "ChaosCurses",
        label = "Chaos Curses",
        primaryScopeKey = "ChaosCurses",
        hasRarity = false,
        scopes = {
            { key = "ChaosCurses", label = "Bans" },
        },
    },
    {
        id = "Judgement1",
        label = "First Biome Judgement",
        primaryScopeKey = "Judgement1",
        hasRarity = false,
        scopes = {
            { key = "Judgement1", label = "Bans" },
        },
    },
    {
        id = "Judgement2",
        label = "Second Biome Judgement",
        primaryScopeKey = "Judgement2",
        hasRarity = false,
        scopes = {
            { key = "Judgement2", label = "Bans" },
        },
    },
    {
        id = "Judgement3",
        label = "Third Biome Judgement",
        primaryScopeKey = "Judgement3",
        hasRarity = false,
        scopes = {
            { key = "Judgement3", label = "Bans" },
        },
    },
}

internal.uiLeanState = internal.uiLeanState or {}
internal.uiLeanState.activeOtherGodRoot = internal.uiLeanState.activeOtherGodRoot or "Hermes"
internal.uiLeanState.activeOtherGodViewByRoot = internal.uiLeanState.activeOtherGodViewByRoot or {}

local function IsRootCustomized(root, uiState)
    for _, scope in ipairs(root.scopes) do
        local banned = uiData.GetScopeSummary(scope.key, uiState)
        if banned > 0 then
            return true
        end
    end
    return false
end

local function GetNavLabel(root, uiState)
    local label = root.label
    if IsRootCustomized(root, uiState) then
        label = label .. " *"
    end
    return label
end

local function GetActiveRoot()
    for _, root in ipairs(OTHER_GOD_ROOTS) do
        if root.id == internal.uiLeanState.activeOtherGodRoot then
            return root
        end
    end
    return OTHER_GOD_ROOTS[1]
end

local function DrawForceRow(ui, uiState, scope)
    local bindAlias = internal.GetBanRootAlias(scope.key)
    if not bindAlias then
        return
    end

    ui.AlignTextToFramePadding()
    ui.Text(scope.label == "Bans" and "Force 1" or scope.label)
    ui.SameLine()
    ui.SetCursorPosX(80)
    lib.widgets.packedDropdown(ui, uiState, bindAlias, store, {
        label = "",
        selectionMode = "singleRemaining",
        noneLabel = "None",
        multipleLabel = "Multiple",
        displayValues = uiData.BuildPackedBanDisplayValues(scope.key),
        valueColors = uiData.BuildPackedBanValueColors(scope.key),
        controlWidth = 220,
    })
end

local function DrawForcePanel(ui, uiState, root)
    lib.widgets.text(ui, "Force")
    lib.widgets.separator(ui)
    for _, scope in ipairs(root.scopes) do
        DrawForceRow(ui, uiState, scope)
    end
end

local function DrawBanPanel(ui, uiState, _, scope)
    internal.DrawBanSearchControls(ui, uiState, scope.key)
    ui.SameLine()
    ui.SetCursorPosX(ui.GetCursorPosX() + 100)

    lib.widgets.button(ui, "Ban All", {
        id = "other_gods_ban_all_" .. scope.key,
        onClick = function()
            internal.BanAllGodBans(scope.key, uiState)
        end,
    })
    ui.SameLine()
    lib.widgets.button(ui, "Reset", {
        id = "other_gods_reset_" .. scope.key,
        onClick = function()
            internal.ResetGodBans(scope.key, uiState)
        end,
    })

    lib.widgets.separator(ui)
    internal.DrawFilteredPackedBanList(ui, uiState, scope.key)
end

local function DrawRarityPanel(ui, uiState, root)
    for _, boon in ipairs(uiData.GetScopeBoons(root.primaryScopeKey)) do
        if uiData.IsRarityEligibleBoon(boon) then
            local rarityAlias = internal.GetRarityAlias(root.primaryScopeKey, boon.Key)
            if rarityAlias then
                ui.AlignTextToFramePadding()
                ui.Text(uiData.GetBoonText(boon))
                ui.SameLine()
                ui.SetCursorPosX(220)
                lib.widgets.dropdown(ui, uiState, rarityAlias, {
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

function internal.DrawOtherGodsTab(ui, uiState)
    local tabs = {}
    for _, root in ipairs(OTHER_GOD_ROOTS) do
        tabs[#tabs + 1] = {
            key = root.id,
            label = GetNavLabel(root, uiState),
            color = uiData.GetSourceColor(root.primaryScopeKey),
        }
    end

    internal.uiLeanState.activeOtherGodRoot = lib.nav.verticalTabs(ui, {
        id = "BoonBansOtherGodsTabs",
        navWidth = 260,
        tabs = tabs,
        activeKey = internal.uiLeanState.activeOtherGodRoot,
    })

    local root = GetActiveRoot()

    ui.BeginChild("BoonBansOtherGodsDetail", 0, 0, false)
    if ui.BeginTabBar("BoonBansOtherGodsViews##" .. root.id) then
        if #root.scopes > 1 and ui.BeginTabItem("Force") then
            internal.uiLeanState.activeOtherGodViewByRoot[root.id] = "force"
            DrawForcePanel(ui, uiState, root)
            ui.EndTabItem()
        end
        for _, scope in ipairs(root.scopes) do
            if ui.BeginTabItem(scope.label) then
                internal.uiLeanState.activeOtherGodViewByRoot[root.id] = scope.key
                DrawBanPanel(ui, uiState, root, scope)
                ui.EndTabItem()
            end
        end
        if root.hasRarity and ui.BeginTabItem("Rarity") then
            internal.uiLeanState.activeOtherGodViewByRoot[root.id] = "rarity"
            DrawRarityPanel(ui, uiState, root)
            ui.EndTabItem()
        end
        ui.EndTabBar()
    end
    ui.EndChild()
end
