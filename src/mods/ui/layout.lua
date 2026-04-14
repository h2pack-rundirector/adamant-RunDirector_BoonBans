local internal = RunDirectorBoonBans_Internal
local uiData = internal.ui

local function GetActiveRootState(uiState)
    local mainTabsNode = uiData.GetMainTabsNode(uiState)
    if not mainTabsNode then
        return nil, nil
    end

    local activeTabName = mainTabsNode._activeTabKey
    local tabState = nil
    if type(activeTabName) == "string" and mainTabsNode._tabStateByKey then
        tabState = mainTabsNode._tabStateByKey[activeTabName]
    end
    if activeTabName == "Settings" then
        return mainTabsNode, nil
    end
    local activeRootAlias = type(activeTabName) == "string" and uiData.GetSelectedRootAlias(activeTabName) or nil
    local activeRootId = activeRootAlias and uiState.get(activeRootAlias) or nil
    local selectedRoot = (type(activeRootId) == "string" and activeRootId ~= "")
        and uiData.GetRootById(activeRootId)
        or (tabState and tabState.selectedRoot or nil)

    return mainTabsNode, selectedRoot
end

function uiData.DrawMainContent(ui, uiState)
    local mainTabsNode = uiData.GetMainTabsNode(uiState)
    if mainTabsNode then
        return lib.ui.drawNode(ui, mainTabsNode, uiState, nil, internal.definition.customTypes)
    end
    return false
end

function uiData.AfterMainContent(uiState, changed)
    local _, selectedRoot = GetActiveRootState(uiState)
    if not selectedRoot then
        return
    end

    if uiData.banFilterState.rootId ~= selectedRoot.id then
        uiData.ResetBanFilter(selectedRoot.id, uiState)
    end
    if selectedRoot.id == "Hera" and uiData.activeBridalGlowRootId ~= selectedRoot.id then
        uiData.InvalidateBridalGlowRootCache()
        uiData.activeBridalGlowRootId = selectedRoot.id
    end

    if changed then
        for _, scope in ipairs(selectedRoot.scopes or uiData.EMPTY_LIST) do
            internal.UpdateGodStats(scope.key, uiState)
        end
    end
end

function internal.BeforeDrawTab(_, uiState)
    uiData.RefreshFrameState(uiState)
end

function internal.DrawTab(ui, uiState)
    return uiData.DrawMainContent(ui, uiState)
end

function internal.AfterDrawTab(_, uiState, _, changed)
    uiData.AfterMainContent(uiState, changed == true)
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
    lib.ui.drawNode(ui, uiData.GetQuickResetNode(), uiState, nil, internal.definition.customTypes)
end
