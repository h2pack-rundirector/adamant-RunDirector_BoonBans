local internal = RunDirectorBoonBans_Internal
local uiData = internal.ui

local HAMMER_ROOTS = {
    {
        id = "Staff",
        label = "Staff",
        primaryScopeKey = "Staff",
        scopes = {
            { key = "Staff", label = "1st" },
            { key = "Staff2", label = "2nd" },
            { key = "Staff3", label = "3rd" },
        },
    },
    {
        id = "Dagger",
        label = "Blades",
        primaryScopeKey = "Dagger",
        scopes = {
            { key = "Dagger", label = "1st" },
            { key = "Dagger2", label = "2nd" },
            { key = "Dagger3", label = "3rd" },
        },
    },
    {
        id = "Axe",
        label = "Axe",
        primaryScopeKey = "Axe",
        scopes = {
            { key = "Axe", label = "1st" },
            { key = "Axe2", label = "2nd" },
            { key = "Axe3", label = "3rd" },
        },
    },
    {
        id = "Torch",
        label = "Torch",
        primaryScopeKey = "Torch",
        scopes = {
            { key = "Torch", label = "1st" },
            { key = "Torch2", label = "2nd" },
            { key = "Torch3", label = "3rd" },
        },
    },
    {
        id = "Lob",
        label = "Skull",
        primaryScopeKey = "Lob",
        scopes = {
            { key = "Lob", label = "1st" },
            { key = "Lob2", label = "2nd" },
            { key = "Lob3", label = "3rd" },
        },
    },
    {
        id = "Suit",
        label = "Coat",
        primaryScopeKey = "Suit",
        scopes = {
            { key = "Suit", label = "1st" },
            { key = "Suit2", label = "2nd" },
            { key = "Suit3", label = "3rd" },
        },
    },
}

internal.uiLeanState = internal.uiLeanState or {}
internal.uiLeanState.activeHammerRoot = internal.uiLeanState.activeHammerRoot or "Staff"
internal.uiLeanState.activeHammerViewByRoot = internal.uiLeanState.activeHammerViewByRoot or {}

local function IsHammerCustomized(root, uiState)
    for _, scope in ipairs(root.scopes) do
        local banned = uiData.GetScopeSummary(scope.key, uiState)
        if banned > 0 then
            return true
        end
    end
    return false
end

local function IsHammerEquipped(root)
    local equippedWeapon = GetEquippedWeapon and (GetEquippedWeapon() or "") or ""
    return equippedWeapon ~= "" and equippedWeapon:find(root.id, 1, true) ~= nil
end

local function GetHammerNavLabel(root, uiState)
    local label = root.label
    if IsHammerEquipped(root) then
        label = "» " .. label .. " «"
    end
    if IsHammerCustomized(root, uiState) then
        label = label .. " *"
    end
    return label
end

local function GetActiveHammerRoot()
    for _, root in ipairs(HAMMER_ROOTS) do
        if root.id == internal.uiLeanState.activeHammerRoot then
            return root
        end
    end
    return HAMMER_ROOTS[1]
end

local function DrawHammerForceRow(ui, uiState, scope)
    local bindAlias = internal.GetBanRootAlias(scope.key)
    if not bindAlias then
        return
    end

    ui.AlignTextToFramePadding()
    ui.Text(scope.label)
    ui.SameLine()
    ui.SetCursorPosX(80)
    lib.widgets.packedDropdown(ui, uiState, bindAlias, store, {
        label = "",
        selectionMode = "singleRemaining",
        noneLabel = "None",
        multipleLabel = "Multiple",
        displayValues = uiData.BuildPackedBanDisplayValues(scope.key),
        valueColors = uiData.BuildPackedBanValueColors(scope.key),
        controlWidth = 200,
    })
end

local function DrawHammerForcePanel(ui, uiState, root)
    lib.widgets.text(ui, "Force")
    lib.widgets.separator(ui)
    for _, scope in ipairs(root.scopes) do
        DrawHammerForceRow(ui, uiState, scope)
    end
end

local function DrawHammerBanPanel(ui, uiState, scope)
    internal.DrawBanSearchControls(ui, uiState, scope.key)
    ui.SameLine()
    ui.SetCursorPosX(ui.GetCursorPosX() + 100)

    lib.widgets.button(ui, "Ban All", {
        id = "hammer_ban_all_" .. scope.key,
        onClick = function()
            internal.BanAllGodBans(scope.key, uiState)
        end,
    })
    ui.SameLine()
    lib.widgets.button(ui, "Reset", {
        id = "hammer_reset_" .. scope.key,
        onClick = function()
            internal.ResetGodBans(scope.key, uiState)
        end,
    })

    lib.widgets.separator(ui)
    internal.DrawFilteredPackedBanList(ui, uiState, scope.key)
end

function internal.DrawHammersTab(ui, uiState)
    local tabs = {}
    for _, root in ipairs(HAMMER_ROOTS) do
        tabs[#tabs + 1] = {
            key = root.id,
            label = GetHammerNavLabel(root, uiState),
            color = uiData.GetSourceColor(root.primaryScopeKey),
        }
    end

    internal.uiLeanState.activeHammerRoot = lib.nav.verticalTabs(ui, {
        id = "BoonBansHammersTabs",
        navWidth = 220,
        tabs = tabs,
        activeKey = internal.uiLeanState.activeHammerRoot,
    })

    local root = GetActiveHammerRoot()
    local activeView = internal.uiLeanState.activeHammerViewByRoot[root.id] or "force"

    ui.BeginChild("BoonBansHammersDetail", 0, 0, false)
    if ui.BeginTabBar("BoonBansHammersViews##" .. root.id) then
        if ui.BeginTabItem("Force") then
            internal.uiLeanState.activeHammerViewByRoot[root.id] = "force"
            DrawHammerForcePanel(ui, uiState, root)
            ui.EndTabItem()
        end
        for _, scope in ipairs(root.scopes) do
            if ui.BeginTabItem(scope.label) then
                internal.uiLeanState.activeHammerViewByRoot[root.id] = scope.key
                DrawHammerBanPanel(ui, uiState, scope)
                ui.EndTabItem()
            end
        end
        ui.EndTabBar()
    elseif activeView == "force" then
        DrawHammerForcePanel(ui, uiState, root)
    else
        for _, scope in ipairs(root.scopes) do
            if scope.key == activeView then
                DrawHammerBanPanel(ui, uiState, scope)
                break
            end
        end
    end
    ui.EndChild()
end
