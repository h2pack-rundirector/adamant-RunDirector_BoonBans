local internal = RunDirectorBoonBans_Internal
local uiData = internal.ui

local ImGuiCol = rom.ImGuiCol

function uiData.DrawRootSelector(ui, tabName, visibleRoots, uiState, headingColor)
    local selectedRoot = uiData.GetRootById(uiData.selectedRootByMainTab[tabName])
    local lastGroup = nil

    for _, root in ipairs(visibleRoots) do
        if tabName == "NPCs" and root.group ~= lastGroup then
            if lastGroup ~= nil then
                ui.Spacing()
            end
            uiData.DrawColoredText(ui, headingColor, root.group)
            lastGroup = root.group
        end

        local label = uiData.GetSelectorLabel(root, uiState)
        local rootColor = uiData.GetSourceColor(root.primaryScopeKey)
        ui.PushID(root.id)
        ui.PushStyleColor(ImGuiCol.Header, rootColor[1], rootColor[2], rootColor[3], 0.18)
        ui.PushStyleColor(ImGuiCol.HeaderHovered, rootColor[1], rootColor[2], rootColor[3], 0.28)
        ui.PushStyleColor(ImGuiCol.HeaderActive, rootColor[1], rootColor[2], rootColor[3], 0.38)
        ui.PushStyleColor(ImGuiCol.Text, rootColor[1], rootColor[2], rootColor[3], rootColor[4])
        if ui.Selectable(label, selectedRoot and selectedRoot.id == root.id) then
            uiData.SelectRoot(tabName, root.id)
            selectedRoot = root
        end
        ui.PopStyleColor(4)
        ui.PopID()
    end
end

function uiData.DrawRootDetail(ui, root, uiState)
    if not root then
        ui.TextDisabled("No selection.")
        return
    end

    local rootColor = uiData.GetSourceColor(root.primaryScopeKey)
    uiData.DrawColoredText(ui, rootColor, root.displayLabel)
    local headerSummary = uiData.GetRootHeaderSummary(root, uiState)
    if headerSummary then
        ui.SameLine()
        ui.TextDisabled(headerSummary)
    end
    ui.Separator()

    if root.isTiered or root.hasRarity then
        if ui.BeginTabBar("RootViews##" .. root.id) then
            for _, view in ipairs(root.views) do
                if ui.BeginTabItem(view.label) then
                    if view.kind == "force" then
                        uiData.DrawForceView(ui, root, uiState)
                    elseif view.kind == "bans" then
                        uiData.DrawBansView(ui, root, view.scopeKey, uiState)
                    elseif view.kind == "bridal_glow" then
                        if uiData.activeBridalGlowRootId ~= root.id then
                            uiData.InvalidateBridalGlowRootCache()
                            uiData.activeBridalGlowRootId = root.id
                        end
                        uiData.DrawBridalGlowControls(ui, uiState)
                    else
                        uiData.DrawRarityView(ui, root, uiState)
                    end
                    ui.EndTabItem()
                end
            end
            ui.EndTabBar()
        end
    else
        uiData.DrawBansView(ui, root, root.primaryScopeKey, uiState)
    end
end

function uiData.DrawDomainTab(ui, uiState, tabName, headingColor)
    if tabName == "NPCs" then
        uiData.DrawNpcRegionFilter(ui)
        ui.Separator()
    end

    local visibleRoots, totalCount, godPoolFiltering = uiData.GetVisibleRoots(tabName)
    if tabName == "Olympians" and godPoolFiltering then
        ui.TextDisabled(string.format("Showing %d/%d Olympians enabled in God Pool.", #visibleRoots, totalCount))
        ui.Separator()
    end

    local selectedRoot = uiData.EnsureSelectedRoot(tabName, visibleRoots)
    if not selectedRoot then
        ui.TextDisabled("No entries available.")
        return
    end

    local totalW = ui.GetWindowWidth()
    local sidebarW = totalW * uiData.SIDEBAR_RATIO

    ui.BeginChild("BoonBansSidebar##" .. tabName, sidebarW, 0, true)
    uiData.DrawRootSelector(ui, tabName, visibleRoots, uiState, headingColor)
    ui.EndChild()

    ui.SameLine()

    ui.BeginChild("BoonBansDetail##" .. tabName, 0, 0, true)
    uiData.DrawRootDetail(ui, uiData.GetRootById(uiData.selectedRootByMainTab[tabName]) or selectedRoot, uiState)
    ui.EndChild()
end

function uiData.DrawMainContent(ui, uiState, headingColor)
    if ui.BeginTabBar("BoonSubTabs") then
        for _, tabName in ipairs(uiData.MAIN_TABS) do
            if ui.BeginTabItem(tabName) then
                if tabName == "Settings" then
                    uiData.DrawSettingsTab(ui, uiState)
                else
                    uiData.DrawDomainTab(ui, uiState, tabName, headingColor)
                end
                ui.EndTabItem()
            end
        end
        ui.EndTabBar()
    end
end

function internal.DrawTab(ui, uiState, theme)
    local colors = uiData.GetThemeColors(theme)
    uiData.RefreshFrameState()
    uiData.DrawMainContent(ui, uiState, colors.info)
end

function internal.DrawQuickContent(ui, uiState, theme)
    local colors = uiData.GetThemeColors(theme)
    local totalBans = internal.GetTotalBansConfigured()
    local customizedRoots = uiData.GetCustomizedRootCount(uiState)
    uiData.DrawColoredText(ui, colors.info, "Boon Bans")
    ui.Text(string.format("%d total bans configured", totalBans))
    ui.Text(string.format("%d roots customized", customizedRoots))
    local padVal, padChanged = ui.Checkbox("Padding Enabled##QuickBoonBans", uiState.view.EnablePadding == true)
    if padChanged then
        uiState.set("EnablePadding", padVal)
    end
    uiData.DrawDangerAction(ui, "quick_reset_all", "Reset All", "Confirm Reset All", function()
        local bansChanged = internal.ResetAllBans(uiState)
        internal.ResetAllRarity(uiState)
        if bansChanged then
            internal.RecalculateBannedCounts(uiState)
        end
    end)
end
