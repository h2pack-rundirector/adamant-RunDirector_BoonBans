local internal = RunDirectorBoonBans_Internal
local uiData = internal.ui

internal.uiNodes = {
    banPanels = {},
    bridalGlowPanels = {},
    mainTabs = nil,
    domainTabs = {},
    rootViewTabs = {},
    rarityPanels = {},
    rarityBadges = {},
    forceRarityBadges = {},
    forcePanels = {},
    npcRegionFilterPanel = nil,
    settingsPanel = nil,
    quickResetNode = nil,
}
local nodeCache = internal.uiNodes

local BANS_CONTROL_COLUMNS = {
    { name = "summary", start = 0, width = 120 },
    { name = "primary", start = 132, width = 88 },
    { name = "secondary", start = 228, width = 88 },
    { name = "filterLabel", start = 0, width = 48 },
    { name = "filterInput", start = 56, width = 180 },
    { name = "filterClear", start = 244, width = 72 },
    { name = "filterMode", start = 328 },
}

local BANS_PANEL_COLUMNS = {
    { name = "content", start = 0 },
}

local BRIDAL_GLOW_COLUMNS = {
    { name = "content", start = 0 },
}

local RARITY_COLUMNS = {
    { name = "label", start = 0 },
    { name = "control", start = 300, width = 120 },
}

local FORCE_COLUMNS = {
    { name = "label", start = 0 },
    { name = "control", start = 84, width = 200 },
    { name = "status", start = 296, width = 140 },
}

local SETTINGS_COLUMNS = {
    { name = "content", start = 0 },
}

local NPC_FILTER_COLUMNS = {
    { name = "content", start = 0 },
}

local ROOT_DETAIL_HEADER_COLUMNS = {
    { name = "title", start = 0 },
    { name = "summary", start = 220 },
}

local function PrepareNode(node, label)
    lib.prepareUiNode(
        node,
        label,
        internal.definition.storage,
        internal.definition.customTypes)
    return node
end

local function BuildRarityBadgeSpec(alias)
    if type(alias) ~= "string" or alias == "" then
        return nil
    end

    return {
        type = "stepper",
        binds = { value = alias },
        label = "",
        min = 0,
        max = 3,
        step = 1,
        displayValues = uiData.RARITY_LABELS,
        valueColors = uiData.RARITY_COLORS,
        geometry = {
            slots = {
                { name = "decrement", start = 0 },
                { name = "value", start = 10, width = 100, align = "center" },
                { name = "increment", start = 100 },
            },
        },
    }
end

function uiData.GetRarityBadgeNode(alias)
    if type(alias) ~= "string" or alias == "" then
        return nil
    end

    local node = nodeCache.rarityBadges[alias]
    if node then
        return node
    end

    node = PrepareNode(BuildRarityBadgeSpec(alias), "BoonBans rarityBadge " .. alias)
    nodeCache.rarityBadges[alias] = node
    return node
end

function uiData.GetForceRarityBadgeNode(alias)
    if type(alias) ~= "string" or alias == "" then
        return nil
    end

    local node = nodeCache.forceRarityBadges[alias]
    if node then
        return node
    end

    node = PrepareNode(BuildRarityBadgeSpec(alias), "BoonBans forceRarityBadge " .. alias)
    nodeCache.forceRarityBadges[alias] = node
    return node
end

function uiData.GetRarityPanelNode(root)
    if type(root) ~= "table" or type(root.id) ~= "string" or root.id == "" then
        return nil
    end

    local node = nodeCache.rarityPanels[root.id]
    if node then
        return node
    end

    local children = {}
    for lineIndex, row in ipairs(uiData.GetRarityRows(root)) do
        if type(row.alias) == "string" and row.alias ~= "" then
            children[#children + 1] = {
                type = "text",
                text = row.name or row.key or row.alias,
                panel = { column = "label", line = lineIndex },
            }
            local rarityNode = uiData.GetRarityBadgeNode(row.alias)
            if rarityNode then
                rarityNode.panel = { column = "control", line = lineIndex }
                children[#children + 1] = rarityNode
            end
        end
    end

    node = PrepareNode({
        type = "panel",
        columns = RARITY_COLUMNS,
        children = children,
    }, "BoonBans rarityPanel " .. root.id)
    nodeCache.rarityPanels[root.id] = node
    return node
end


local function BuildBanControlsPanelSpec(scopeKey)
    local displayValues = {}
    for _, filterMode in ipairs(uiData.BAN_FILTER_MODES) do
        displayValues[filterMode.id] = filterMode.label
    end

    return {
        type = "panel",
        columns = BANS_CONTROL_COLUMNS,
        children = {
            {
                type = "text",
                binds = { value = uiData.GetBanSummaryAlias(scopeKey) },
                color = uiData.MUTED_TEXT_COLOR,
                panel = { column = "summary", line = 1 },
            },
            {
                type = "button",
                label = "Ban All",
                onClick = function(uiState)
                    internal.BanAllGodBans(scopeKey, uiState)
                end,
                panel = { column = "primary", line = 1 },
            },
            {
                type = "button",
                label = "Reset",
                onClick = function(uiState)
                    internal.ResetGodBans(scopeKey, uiState)
                end,
                panel = { column = "secondary", line = 1 },
            },
            {
                type = "text",
                text = "Filter:",
                panel = { column = "filterLabel", line = 2 },
            },
            {
                type = "inputText",
                binds = { value = uiData.BAN_FILTER_TEXT_ALIAS },
                label = "",
                geometry = {
                    slots = {
                        { name = "control", width = 180 },
                    },
                },
                panel = { column = "filterInput", line = 2 },
            },
            {
                type = "button",
                label = "Clear",
                onClick = function(uiState)
                    uiState.reset(uiData.BAN_FILTER_TEXT_ALIAS)
                    uiState.reset(uiData.BAN_FILTER_MODE_ALIAS)
                end,
                panel = { column = "filterClear", line = 2 },
            },
            {
                type = "radio",
                binds = { value = uiData.BAN_FILTER_MODE_ALIAS },
                label = "",
                values = { "all", "checked", "unchecked" },
                displayValues = displayValues,
                geometry = {
                    slots = {
                        { name = "option:1", line = 1, start = 0 },
                        { name = "option:2", line = 1, start = 56 },
                        { name = "option:3", line = 1, start = 136 },
                    },
                },
                panel = { column = "filterMode", line = 2 },
            },
        },
    }
end

function uiData.GetBanPanelNode(scopeKey)
    if type(scopeKey) ~= "string" or scopeKey == "" then
        return nil
    end

    local node = nodeCache.banPanels[scopeKey]
    if node then
        return node
    end

    local children = {}
    children[#children + 1] = BuildBanControlsPanelSpec(scopeKey)
    children[#children].panel = { column = "content", line = 1 }
    children[#children + 1] = {
        type = "separator",
        panel = { column = "content", line = 2 },
    }
    children[#children + 1] = {
        type = "packedCheckboxList",
        binds = {
            value = internal.GetBanRootAlias(scopeKey),
            filterText = uiData.BAN_FILTER_TEXT_ALIAS,
            filterMode = uiData.BAN_FILTER_MODE_ALIAS,
        },
        valueColors = uiData.BuildPackedBanValueColors(scopeKey),
        slotCount = #(uiData.GetScopeBoons(scopeKey) or uiData.EMPTY_LIST),
        panel = { column = "content", line = 3 },
    }
    children[#children + 1] = {
        type = "text",
        binds = { value = uiData.GetBanEmptyStateAlias(scopeKey) },
        color = uiData.MUTED_TEXT_COLOR,
        visibleIf = { alias = uiData.GetBanEmptyStateAlias(scopeKey), value = "No boons match the current filter." },
        panel = { column = "content", line = 4 },
    }

    node = PrepareNode({
        type = "panel",
        columns = BANS_PANEL_COLUMNS,
        children = children,
    }, "BoonBans banPanel " .. scopeKey)
    nodeCache.banPanels[scopeKey] = node
    return node
end

function uiData.GetBridalGlowPanelNode(root)
    if type(root) ~= "table" or type(root.id) ~= "string" or root.id == "" then
        return nil
    end

    local node = nodeCache.bridalGlowPanels[root.id]
    if node then
        return node
    end

    node = PrepareNode({
        type = "panel",
        columns = BRIDAL_GLOW_COLUMNS,
        children = {
            {
                type = "text",
                text = "Choose the Olympian god and boon pool Bridal Glow can target.",
                panel = { column = "content", line = 1 },
            },
            {
                type = "text",
                binds = { value = uiData.BRIDAL_GLOW_TARGET_TEXT_ALIAS },
                panel = { column = "content", line = 2 },
            },
            {
                type = "bridalGlowPicker",
                panel = { column = "content", line = 3 },
            },
        },
    }, "BoonBans bridalGlowPanel " .. root.id)
    nodeCache.bridalGlowPanels[root.id] = node
    return node
end

function uiData.GetRootViewsTabsNode(root)
    if type(root) ~= "table" or type(root.id) ~= "string" or root.id == "" then
        return nil
    end

    local node = nodeCache.rootViewTabs[root.id]
    if node then
        return node
    end

    local children = {}
    for index, view in ipairs(root.views or {}) do
        local child = nil
        if view.kind == "force" then
            child = uiData.GetForcePanelNode(root)
        elseif view.kind == "bans" then
            child = uiData.GetBanPanelNode(view.scopeKey or root.primaryScopeKey)
        elseif view.kind == "bridal_glow" then
            child = uiData.GetBridalGlowPanelNode(root)
        elseif view.kind == "rarity" then
            local rarityRows = uiData.GetRarityRows(root)
            if #rarityRows == 0 then
                child = {
                    type = "text",
                    text = "No rarity-configurable boons for this root.",
                    color = uiData.MUTED_TEXT_COLOR,
                }
            elseif root.isTiered then
                child = {
                    type = "group",
                    children = {
                        {
                            type = "text",
                            text = "Rarity applies across all tiers for this root.",
                            color = uiData.MUTED_TEXT_COLOR,
                        },
                        {
                            type = "separator",
                        },
                        uiData.GetRarityPanelNode(root),
                    },
                }
            else
                child = uiData.GetRarityPanelNode(root)
            end
        end

        if child then
            child.tabLabel = view.label
            child.tabId = tostring(index) .. "::" .. tostring(view.kind or view.label or "view")
            children[#children + 1] = child
        end
    end

    node = PrepareNode({
        type = "horizontalTabs",
        id = "RootViews##" .. root.id,
        children = children,
    }, "BoonBans rootViewsTabs " .. root.id)
    nodeCache.rootViewTabs[root.id] = node
    return node
end

function uiData.GetForcePanelNode(root)
    if type(root) ~= "table" or type(root.id) ~= "string" or root.id == "" then
        return nil
    end

    local node = nodeCache.forcePanels[root.id]
    if node then
        return node
    end

    local children = {}
    for _, scope in ipairs(root.scopes or {}) do
        local bindAlias = internal.GetBanRootAlias(scope.key)
        if bindAlias then
            local rowChildren = {}
            rowChildren[#rowChildren + 1] = {
                type = "text",
                text = scope.label,
                panel = { column = "label", line = 1 },
            }
            rowChildren[#rowChildren + 1] = {
                type = "packedDropdown",
                binds = { value = bindAlias },
                label = "",
                selectionMode = "singleRemaining",
                noneLabel = "None",
                multipleLabel = "Multiple",
                displayValues = uiData.BuildPackedBanDisplayValues(scope.key),
                valueColors = uiData.BuildPackedBanValueColors(scope.key),
                geometry = {
                    slots = {
                        { name = "control", width = 200 },
                    },
                },
                panel = { column = "control", line = 1 },
            }
              if root.hasRarity then
                  rowChildren[#rowChildren + 1] = {
                     type = "forceRarityStatus",
                     binds = { value = bindAlias },
                     forceScopeKey = scope.key,
                     rarityScopeKey = root.primaryScopeKey,
                     panel = { column = "status", line = 1 },
                  }
              end
            children[#children + 1] = {
                type = "panel",
                columns = FORCE_COLUMNS,
                children = rowChildren,
            }
        end
    end

    node = PrepareNode({
        type = "group",
        children = children,
    }, "BoonBans forcePanel " .. root.id)
    nodeCache.forcePanels[root.id] = node
    return node
end

function uiData.GetSettingsPanelNode()
    if nodeCache.settingsPanel then
        return nodeCache.settingsPanel
    end

    local node = PrepareNode({
        type = "panel",
        columns = SETTINGS_COLUMNS,
        children = {
            {
                type = "checkbox",
                binds = { value = "EnablePadding" },
                label = "Enable Padding",
                panel = { column = "content", line = 1 },
            },
            {
                type = "text",
                text = "Fills up menus to ensure enough options are available.",
                color = uiData.MUTED_TEXT_COLOR,
                panel = { column = "content", line = 2 },
            },
            {
                type = "group",
                visibleIf = "EnablePadding",
                panel = { column = "content", line = 3 },
                children = {
                    {
                        type = "stepper",
                        binds = { value = "Padding_PrioritizeCoreForFirstN" },
                        label = "Prioritize Core Boons for First N",
                        min = 0,
                        max = 15,
                        step = 1,
                    },
                    {
                        type = "text",
                        text = "(0 = disabled, N = prefer core boons in padding for the first N picks from each god.)",
                        color = uiData.MUTED_TEXT_COLOR,
                    },
                    {
                        type = "checkbox",
                        binds = { value = "Padding_AvoidFutureAllowed" },
                        label = "Avoid 'Future Allowed' Items",
                    },
                    {
                        type = "checkbox",
                        binds = { value = "Padding_AllowDuos" },
                        label = "Allow Banned Duos/Legendaries",
                    },
                },
            },
            {
                type = "separator",
                panel = { column = "content", line = 4 },
            },
            {
                type = "stepper",
                binds = { value = "ImproveFirstNBoonRarity" },
                label = "Improve N Boon Rarity to Epic",
                min = 0,
                max = 15,
                step = 1,
                panel = { column = "content", line = 5 },
            },
            {
                type = "text",
                text = "(Improve the rarity of offered boons unless specifically forced by config.)",
                color = uiData.MUTED_TEXT_COLOR,
                panel = { column = "content", line = 6 },
            },
            {
                type = "separator",
                panel = { column = "content", line = 7 },
            },
            {
                type = "confirmButton",
                label = "RESET ALL BANS (Global)",
                confirmLabel = "Confirm RESET ALL BANS",
                timeoutSeconds = uiData.CONFIRM_TIMEOUT,
                onConfirm = function(uiState)
                    if internal.ResetAllBans(uiState) then
                        internal.RecalculateBannedCounts(uiState)
                    end
                end,
                panel = { column = "content", line = 8 },
            },
            {
                type = "confirmButton",
                label = "RESET ALL RARITY (Global)",
                confirmLabel = "Confirm RESET ALL RARITY",
                timeoutSeconds = uiData.CONFIRM_TIMEOUT,
                onConfirm = function(uiState)
                    internal.ResetAllRarity(uiState)
                end,
                panel = { column = "content", line = 9 },
            },
        },
    }, "BoonBans settingsPanel")
    nodeCache.settingsPanel = node
    return node
end

function uiData.GetNpcRegionFilterPanelNode()
    if nodeCache.npcRegionFilterPanel then
        return nodeCache.npcRegionFilterPanel
    end

    local displayValues = {}
    for _, option in ipairs(uiData.NPC_REGION_OPTIONS) do
        displayValues[option.value] = option.label
    end

    local node = PrepareNode({
        type = "panel",
        columns = NPC_FILTER_COLUMNS,
        children = {
            {
                type = "radio",
                binds = { value = uiData.NPC_VIEW_REGION_ALIAS },
                label = "Filter NPC Sources:",
                values = { 1, 2, 3, 4 },
                displayValues = displayValues,
                geometry = {
                    slots = {
                        { name = "option:1", line = 1, start = 140 },
                        { name = "option:2", line = 1, start = 240 },
                        { name = "option:3", line = 1, start = 340 },
                        { name = "option:4", line = 1, start = 440 },
                    },
                },
                panel = { column = "content", line = 1 },
            },
        },
    }, "BoonBans npcRegionFilterPanel")
    nodeCache.npcRegionFilterPanel = node
    return node
end

function uiData.GetQuickResetNode()
    if nodeCache.quickResetNode then
        return nodeCache.quickResetNode
    end

    local node = PrepareNode({
        type = "confirmButton",
        label = "Reset All",
        confirmLabel = "Confirm Reset All",
        timeoutSeconds = uiData.CONFIRM_TIMEOUT,
        onConfirm = function(uiState)
            local bansChanged = internal.ResetAllBans(uiState)
            internal.ResetAllRarity(uiState)
            if bansChanged then
                internal.RecalculateBannedCounts(uiState)
            end
        end,
    }, "BoonBans quickResetNode")
    nodeCache.quickResetNode = node
    return node
end

function uiData.GetMainTabsNode()
    if nodeCache.mainTabs then
        return nodeCache.mainTabs
    end

    local children = {}
    for _, tabName in ipairs(uiData.MAIN_TABS) do
        children[#children + 1] = {
            type = "mainTabContent",
            tabName = tabName,
            tabLabel = tabName,
            tabId = tabName,
        }
    end

    local node = PrepareNode({
        type = "horizontalTabs",
        id = "BoonSubTabs",
        children = children,
    }, "BoonBans mainTabs")
    nodeCache.mainTabs = node
    return node
end

local function BuildRootDetailHeaderSpec(root, uiState)
    local headerChildren = {
        {
            type = "text",
            text = root.displayLabel,
            color = uiData.GetSourceColor(root.primaryScopeKey),
            panel = { column = "title", line = 1 },
        },
    }

    local headerSummary = uiData.GetRootHeaderSummary(root, uiState)
    if type(headerSummary) == "string" and headerSummary ~= "" then
        headerChildren[#headerChildren + 1] = {
            type = "text",
            text = headerSummary,
            color = uiData.MUTED_TEXT_COLOR,
            panel = { column = "summary", line = 1 },
        }
    end

    return {
        type = "panel",
        columns = ROOT_DETAIL_HEADER_COLUMNS,
        children = headerChildren,
    }
end

local function BuildRootDetailSpec(root, uiState)
    local children = {
        BuildRootDetailHeaderSpec(root, uiState),
        { type = "separator" },
    }

    if root.isTiered or root.hasRarity then
        children[#children + 1] = uiData.GetRootViewsTabsNode(root)
    else
        children[#children + 1] = uiData.GetBanPanelNode(root.primaryScopeKey)
    end

    return {
        type = "group",
        tabLabel = uiData.GetSelectorLabel(root, uiState),
        tabId = root.id,
        tabLabelColor = uiData.GetSourceColor(root.primaryScopeKey),
        children = children,
    }
end

function uiData.GetDomainTabsNode(tabName, visibleRoots, uiState)
    if type(tabName) ~= "string" or tabName == "" then
        return nil
    end

    local signatureParts = { tabName }
    for _, root in ipairs(visibleRoots or uiData.EMPTY_LIST) do
        signatureParts[#signatureParts + 1] = root.id
        signatureParts[#signatureParts + 1] = uiData.GetSelectorLabel(root, uiState)
        signatureParts[#signatureParts + 1] = uiData.GetRootHeaderSummary(root, uiState) or ""
    end
    local signature = table.concat(signatureParts, "|")

    local cached = nodeCache.domainTabs[tabName]
    if cached and cached.signature == signature then
        return cached.node
    end

    local children = {}
    for _, root in ipairs(visibleRoots or uiData.EMPTY_LIST) do
        children[#children + 1] = BuildRootDetailSpec(root, uiState)
    end

    local node = PrepareNode({
        type = "verticalTabs",
        id = "BoonBansDomain##" .. tabName,
        sidebarWidth = 260,
        children = children,
    }, "BoonBans domainTabs " .. tabName)

    nodeCache.domainTabs[tabName] = {
        signature = signature,
        node = node,
    }
    return node
end
