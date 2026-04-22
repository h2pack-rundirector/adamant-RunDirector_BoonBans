local internal = RunDirectorBoonBans_Internal
local uiData = internal.ui

local HAMMER_ROOT_KEYS = {
    "Staff",
    "Dagger",
    "Axe",
    "Torch",
    "Lob",
    "Suit",
}

local function BuildHammerRoots()
    local roots = {}
    for _, rootKey in ipairs(HAMMER_ROOT_KEYS) do
        roots[#roots + 1] = uiData.BuildTierRoot(rootKey, {
            hasRarity = false,
        })
    end
    return roots
end

internal.uiLeanState = internal.uiLeanState or {}
internal.uiLeanState.activeHammerRoot = internal.uiLeanState.activeHammerRoot or "Staff"
internal.uiLeanState.activeHammerViewByRoot = internal.uiLeanState.activeHammerViewByRoot or {}

local function IsHammerCustomized(root, session)
    for _, scope in ipairs(root.scopes) do
        local banned = uiData.GetScopeSummary(scope.key, session)
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

local function GetHammerNavLabel(root, session)
    local label = root.label
    if IsHammerEquipped(root) then
        label = "» " .. label .. " «"
    end
    if IsHammerCustomized(root, session) then
        label = label .. " *"
    end
    return label
end

local function GetActiveHammerRoot()
    for _, root in ipairs(BuildHammerRoots()) do
        if root.id == internal.uiLeanState.activeHammerRoot then
            return root
        end
    end
    return uiData.BuildTierRoot(HAMMER_ROOT_KEYS[1], { hasRarity = false })
end

local function DrawHammerForceRow(ui, session, scope)
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
        selectionMode = "singleDisabled",
        noneLabel = "None",
        multipleLabel = "Multiple",
        displayValues = uiData.BuildPackedBanDisplayValues(scope.key),
        valueColors = uiData.BuildPackedBanValueColors(scope.key),
        controlWidth = 200,
    })
end

local function DrawHammerForcePanel(ui, session, root)
    lib.widgets.text(ui, "Force")
    lib.widgets.separator(ui)
    for _, scope in ipairs(root.scopes) do
        DrawHammerForceRow(ui, session, scope)
    end
end

local function DrawHammerBanPanel(ui, session, scope)
    internal.DrawBanSearchControls(ui, session, scope.key)
    ui.SameLine()
    ui.SetCursorPosX(ui.GetCursorPosX() + 100)

    lib.widgets.button(ui, "Ban All", {
        id = "hammer_ban_all_" .. scope.key,
        onClick = function()
            internal.BanAllGodBans(scope.key, session)
        end,
    })
    ui.SameLine()
    lib.widgets.button(ui, "Reset", {
        id = "hammer_reset_" .. scope.key,
        onClick = function()
            internal.ResetGodBans(scope.key, session)
        end,
    })

    lib.widgets.separator(ui)
    internal.DrawFilteredPackedBanList(ui, session, scope.key)
end

function internal.DrawHammersTab(ui, session)
    local tabs = {}
    for _, root in ipairs(BuildHammerRoots()) do
        tabs[#tabs + 1] = {
            key = root.id,
            label = GetHammerNavLabel(root, session),
            color = uiData.GetSourceColor(root.primaryScopeKey),
        }
    end

    internal.uiLeanState.activeHammerRoot = lib.nav.verticalTabs(ui, {
        id = "BoonBansHammersTabs",
        navWidth = uiData.ROOT_NAV_WIDTH,
        tabs = tabs,
        activeKey = internal.uiLeanState.activeHammerRoot,
    })

    local root = GetActiveHammerRoot()
    local activeView = internal.uiLeanState.activeHammerViewByRoot[root.id] or "force"

    ui.BeginChild("BoonBansHammersDetail", 0, 0, false)
    if ui.BeginTabBar("BoonBansHammersViews##" .. root.id) then
        if ui.BeginTabItem("Force") then
            internal.uiLeanState.activeHammerViewByRoot[root.id] = "force"
            DrawHammerForcePanel(ui, session, root)
            ui.EndTabItem()
        end
        for _, scope in ipairs(root.scopes) do
            if ui.BeginTabItem(scope.label) then
                internal.uiLeanState.activeHammerViewByRoot[root.id] = scope.key
                DrawHammerBanPanel(ui, session, scope)
                ui.EndTabItem()
            end
        end
        ui.EndTabBar()
    elseif activeView == "force" then
        DrawHammerForcePanel(ui, session, root)
    else
        for _, scope in ipairs(root.scopes) do
            if scope.key == activeView then
                DrawHammerBanPanel(ui, session, scope)
                break
            end
        end
    end
    ui.EndChild()
end
