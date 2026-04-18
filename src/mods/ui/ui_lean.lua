local internal = RunDirectorBoonBans_Internal

internal.ui = internal.ui or {}
local uiData = internal.ui

import("mods/ui/ui_shared.lua")
import("mods/ui/ui_olympians.lua")
import("mods/ui/ui_hammers.lua")
import("mods/ui/ui_npcs.lua")
import("mods/ui/ui_other_gods.lua")

function internal.DrawBanSearchControls(ui, uiState, idSuffix)
    idSuffix = tostring(idSuffix or "")

    ui.AlignTextToFramePadding()
    ui.Text("Filter:")
    ui.SameLine()
    lib.widgets.inputText(ui, uiState, uiData.BAN_FILTER_TEXT_ALIAS, {
        label = "",
        controlWidth = 180,
    })
    ui.SameLine()
    lib.widgets.button(ui, "Clear", {
        id = "boon_bans_filter_clear_" .. idSuffix,
        onClick = function()
            uiState.reset(uiData.BAN_FILTER_TEXT_ALIAS)
        end,
    })
end

function internal.DrawFilteredPackedBanList(ui, uiState, scopeKey, opts)
    opts = opts or {}
    local filterText = tostring(uiState and uiState.view and uiState.view[uiData.BAN_FILTER_TEXT_ALIAS] or "")

    lib.widgets.packedCheckboxList(ui, uiState, internal.GetBanRootAlias(scopeKey), store, {
        valueColors = opts.valueColors or uiData.BuildPackedBanValueColors(scopeKey),
        slotCount = opts.slotCount or #(uiData.GetScopeBoons(scopeKey) or uiData.EMPTY_LIST),
        filterText = filterText,
    })

    if uiData.GetVisibleBanCount(scopeKey, uiState) == 0 then
        lib.widgets.text(ui, "No boons match the current filter.", {
            color = uiData.MUTED_TEXT_COLOR,
        })
    end
end

function internal.ResetAllControls(uiState)
    local bansChanged = internal.ResetAllBans(uiState)
    internal.ResetAllRarity(uiState)
    if bansChanged then
        internal.RecalculateBannedCounts(uiState)
    end
end

local function DrawSettingsTab(ui, uiState)
    lib.widgets.checkbox(ui, uiState, "EnablePadding", {
        label = "Enable Padding",
    })

    if uiState.view.EnablePadding == true then
        lib.widgets.dropdown(ui, uiState, "Padding_PrioritizeCoreForFirstN", {
            label = "Prioritize Core Boons for First Picks",
            values = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
            controlWidth = 60,
        })
        lib.widgets.checkbox(ui, uiState, "Padding_AvoidFutureAllowed", {
            label = "Avoid 'Future Allowed' Items",
        })
        lib.widgets.checkbox(ui, uiState, "Padding_AllowDuos", {
            label = "Allow Banned Duos/Legendaries",
        })
    end

    ui.Spacing()
    lib.widgets.dropdown(ui, uiState, "ImproveFirstNBoonRarity", {
        label = "Force First N Boons to Be Epic",
        values = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
        controlWidth = 60,
    })

    ui.Spacing()
    lib.widgets.confirmButton(ui, "boon_bans_reset_all_bans", "RESET ALL BANS (Global)", {
        confirmLabel = "Confirm RESET ALL BANS",
        onConfirm = function()
            local bansChanged = internal.ResetAllBans(uiState)
            if bansChanged then
                internal.RecalculateBannedCounts(uiState)
            end
        end,
    })
    lib.widgets.confirmButton(ui, "boon_bans_reset_all_rarity", "RESET ALL RARITY (Global)", {
        confirmLabel = "Confirm RESET ALL RARITY",
        onConfirm = function()
            internal.ResetAllRarity(uiState)
        end,
    })
end

function internal.DrawTab(ui, uiState)
    if not ui.BeginTabBar("BoonBansLeanTabs") then
        return false
    end

    if ui.BeginTabItem("Olympians") then
        internal.DrawOlympiansTab(ui, uiState)
        ui.EndTabItem()
    end

    if ui.BeginTabItem("Other Gods") then
        internal.DrawOtherGodsTab(ui, uiState)
        ui.EndTabItem()
    end

    if ui.BeginTabItem("Hammers") then
        internal.DrawHammersTab(ui, uiState)
        ui.EndTabItem()
    end

    if ui.BeginTabItem("NPCs") then
        internal.DrawNpcsTab(ui, uiState)
        ui.EndTabItem()
    end

    if ui.BeginTabItem("Settings") then
        DrawSettingsTab(ui, uiState)
        ui.EndTabItem()
    end

    ui.EndTabBar()
    return false
end

function internal.DrawQuickContent(ui, uiState)
    lib.widgets.checkbox(ui, uiState, "EnablePadding", {
        label = "Padding Enabled",
    })

    lib.widgets.confirmButton(ui, "boon_bans_quick_reset_all", "Reset To Default", {
        confirmLabel = "Confirm Reset All",
        onConfirm = function()
            internal.ResetAllControls(uiState)
        end,
    })
end
