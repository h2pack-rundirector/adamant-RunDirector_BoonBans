local internal = RunDirectorBoonBans_Internal
local uiData = internal.ui

internal.uiNodes = {
    banPanels = {},
    bridalGlowPanels = {},
    mainTabs = nil,
    domainTabs = {},
    domainPanels = {},
    rootViewTabs = {},
    rarityPanels = {},
    rarityBadges = {},
    forcePanels = {},
    npcRegionFilterPanel = nil,
    settingsPanel = nil,
    quickResetNode = nil,
}
local nodeCache = internal.uiNodes
local UI_NODE_CACHE_VERSION = "layout_v2_3"

local function EnsureNodeCacheVersion()
    if nodeCache._version == UI_NODE_CACHE_VERSION then
        return
    end

    for key in pairs(nodeCache) do
        nodeCache[key] = nil
    end

    nodeCache.banPanels = {}
    nodeCache.bridalGlowPanels = {}
    nodeCache.mainTabs = nil
    nodeCache.domainTabs = {}
    nodeCache.domainPanels = {}
    nodeCache.rootViewTabs = {}
    nodeCache.rarityPanels = {}
    nodeCache.rarityBadges = {}
    nodeCache.forcePanels = {}
    nodeCache.npcRegionFilterPanel = nil
    nodeCache.settingsPanel = nil
    nodeCache.quickResetNode = nil
    nodeCache._version = UI_NODE_CACHE_VERSION
end

local function PrepareNode(node, label)
    lib.ui.prepareNode(
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
        valueWidth = 100,
        valueAlign = "center",
    }
end

function uiData.GetRarityBadgeNode(alias)
    EnsureNodeCacheVersion()
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

function uiData.GetRarityPanelNode(root)
    EnsureNodeCacheVersion()
    if type(root) ~= "table" or type(root.id) ~= "string" or root.id == "" then
        return nil
    end

    local node = nodeCache.rarityPanels[root.id]
    if node then
        return node
    end

    local children = {}
    for _, row in ipairs(uiData.GetRarityRows(root)) do
        if type(row.alias) == "string" and row.alias ~= "" then
            local rarityNode = uiData.GetRarityBadgeNode(row.alias)
            if rarityNode then
                children[#children + 1] = {
                    type = "hstack",
                    gap = 12,
                    children = {
                        {
                            type = "text",
                            text = row.name or row.key or row.alias,
                            width = 300,
                        },
                        rarityNode,
                    },
                }
            end
        end
    end

    node = PrepareNode({
        type = "vstack",
        gap = 6,
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
        type = "vstack",
        gap = 6,
        children = {
            {
                type = "split",
                orientation = "horizontal",
                firstSize = 120,
                gap = 12,
                children = {
                    {
                        type = "text",
                        binds = { value = uiData.GetBanSummaryAlias(scopeKey) },
                        color = uiData.MUTED_TEXT_COLOR,
                    },
                    {
                        type = "hstack",
                        gap = 12,
                        children = {
                            {
                                type = "button",
                                label = "Ban All",
                                onClick = function(uiState)
                                    internal.BanAllGodBans(scopeKey, uiState)
                                end,
                            },
                            {
                                type = "button",
                                label = "Reset",
                                onClick = function(uiState)
                                    internal.ResetGodBans(scopeKey, uiState)
                                end,
                            },
                        },
                    },
                },
            },
            {
                type = "split",
                orientation = "horizontal",
                firstSize = 48,
                gap = 8,
                children = {
                    {
                        type = "text",
                        text = "Filter:",
                    },
                    {
                        type = "split",
                        orientation = "horizontal",
                        firstSize = 252,
                        gap = 12,
                        children = {
                            {
                                type = "hstack",
                                gap = 12,
                                children = {
                                    {
                                        type = "inputText",
                                        binds = { value = uiData.BAN_FILTER_TEXT_ALIAS },
                                        label = "",
                                        controlWidth = 180,
                                    },
                                    {
                                        type = "button",
                                        label = "Clear",
                                        onClick = function(uiState)
                                            uiState.reset(uiData.BAN_FILTER_TEXT_ALIAS)
                                            uiState.reset(uiData.BAN_FILTER_MODE_ALIAS)
                                        end,
                                    },
                                },
                            },
                            {
                                type = "radio",
                                binds = { value = uiData.BAN_FILTER_MODE_ALIAS },
                                label = "",
                                values = { "all", "checked", "unchecked" },
                                displayValues = displayValues,
                            },
                        },
                    },
                },
            },
        },
    }
end

function uiData.GetBanPanelNode(scopeKey)
    EnsureNodeCacheVersion()
    if type(scopeKey) ~= "string" or scopeKey == "" then
        return nil
    end

    local node = nodeCache.banPanels[scopeKey]
    if node then
        return node
    end

    node = PrepareNode({
        type = "vstack",
        gap = 8,
        children = {
            BuildBanControlsPanelSpec(scopeKey),
            {
                type = "packedCheckboxList",
                binds = {
                    value = internal.GetBanRootAlias(scopeKey),
                    filterText = uiData.BAN_FILTER_TEXT_ALIAS,
                    filterMode = uiData.BAN_FILTER_MODE_ALIAS,
                },
                valueColors = uiData.BuildPackedBanValueColors(scopeKey),
                slotCount = #(uiData.GetScopeBoons(scopeKey) or uiData.EMPTY_LIST),
            },
            {
                type = "text",
                binds = { value = uiData.GetBanEmptyStateAlias(scopeKey) },
                color = uiData.MUTED_TEXT_COLOR,
                visibleIf = { alias = uiData.GetBanEmptyStateAlias(scopeKey), value = "No boons match the current filter." },
            },
        },
    }, "BoonBans banPanel " .. scopeKey)
    nodeCache.banPanels[scopeKey] = node
    return node
end

function uiData.GetBridalGlowPanelNode(root)
    EnsureNodeCacheVersion()
    if type(root) ~= "table" or type(root.id) ~= "string" or root.id == "" then
        return nil
    end

    local node = nodeCache.bridalGlowPanels[root.id]
    if node then
        return node
    end

    node = PrepareNode({
        type = "vstack",
        gap = 8,
        children = {
            {
                type = "text",
                text = "Choose the Olympian god and boon pool Bridal Glow can target.",
            },
            {
                type = "text",
                binds = { value = uiData.BRIDAL_GLOW_TARGET_TEXT_ALIAS },
            },
            {
                type = "bridalGlowPicker",
            },
        },
    }, "BoonBans bridalGlowPanel " .. root.id)
    nodeCache.bridalGlowPanels[root.id] = node
    return node
end

function uiData.GetRootViewsTabsNode(root)
    EnsureNodeCacheVersion()
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
                    type = "vstack",
                    gap = 6,
                    children = {
                        {
                            type = "text",
                            text = "Rarity applies across all tiers for this root.",
                            color = uiData.MUTED_TEXT_COLOR,
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
        type = "tabs",
        id = "RootViews##" .. root.id,
        children = children,
    }, "BoonBans rootViewsTabs " .. root.id)
    nodeCache.rootViewTabs[root.id] = node
    return node
end

function uiData.GetForcePanelNode(root)
    EnsureNodeCacheVersion()
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
                controlWidth = 200,
            }
            if root.hasRarity then
                rowChildren[#rowChildren + 1] = {
                    type = "forceRarityStatus",
                    binds = { value = bindAlias },
                    forceScopeKey = scope.key,
                    rarityScopeKey = root.primaryScopeKey,
                }
            end
            children[#children + 1] = {
                type = "hstack",
                gap = 12,
                children = rowChildren,
            }
        end
    end

    node = PrepareNode({
        type = "vstack",
        gap = 6,
        children = children,
    }, "BoonBans forcePanel " .. root.id)
    nodeCache.forcePanels[root.id] = node
    return node
end

function uiData.GetSettingsPanelNode()
    EnsureNodeCacheVersion()
    if nodeCache.settingsPanel then
        return nodeCache.settingsPanel
    end

    local node = PrepareNode({
        type = "vstack",
        gap = 8,
        children = {
            {
                type = "checkbox",
                binds = { value = "EnablePadding" },
                label = "Enable Padding",
            },
            {
                type = "text",
                text = "Fills up menus to ensure enough options are available.",
                color = uiData.MUTED_TEXT_COLOR,
            },
            {
                type = "vstack",
                gap = 6,
                visibleIf = "EnablePadding",
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
                type = "stepper",
                binds = { value = "ImproveFirstNBoonRarity" },
                label = "Improve N Boon Rarity to Epic",
                min = 0,
                max = 15,
                step = 1,
            },
            {
                type = "text",
                text = "(Improve the rarity of offered boons unless specifically forced by config.)",
                color = uiData.MUTED_TEXT_COLOR,
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
            },
            {
                type = "confirmButton",
                label = "RESET ALL RARITY (Global)",
                confirmLabel = "Confirm RESET ALL RARITY",
                timeoutSeconds = uiData.CONFIRM_TIMEOUT,
                onConfirm = function(uiState)
                    internal.ResetAllRarity(uiState)
                end,
            },
        },
    }, "BoonBans settingsPanel")
    nodeCache.settingsPanel = node
    return node
end

function uiData.GetNpcRegionFilterPanelNode()
    EnsureNodeCacheVersion()
    if nodeCache.npcRegionFilterPanel then
        return nodeCache.npcRegionFilterPanel
    end

    local displayValues = {}
    for _, option in ipairs(uiData.NPC_REGION_OPTIONS) do
        displayValues[option.value] = option.label
    end

    local node = PrepareNode({
        type = "hstack",
        gap = 12,
        children = {
            {
                type = "text",
                text = "Filter NPC Sources:",
            },
            {
                type = "radio",
                binds = { value = uiData.NPC_VIEW_REGION_ALIAS },
                label = "",
                values = { 1, 2, 3, 4 },
                displayValues = displayValues,
            },
        },
    }, "BoonBans npcRegionFilterPanel")
    nodeCache.npcRegionFilterPanel = node
    return node
end

function uiData.GetQuickResetNode()
    EnsureNodeCacheVersion()
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

local function BuildMainDomainTabState(tabName, uiState)
    local visibleRoots, totalCount, godPoolFiltering = uiData.GetVisibleRoots(tabName, uiState)
    local selectedRoot = uiData.EnsureSelectedRoot(tabName, visibleRoots, uiState)
    local domainPanelNode = uiData.GetDomainPanelNode(
        tabName,
        visibleRoots,
        totalCount,
        godPoolFiltering,
        uiState)
    if domainPanelNode then
        local domainNode = domainPanelNode._domainTabsNode
        if domainNode and selectedRoot then
            domainNode._activeTabKey = selectedRoot.id
        end
        domainPanelNode.tabLabel = tabName
        domainPanelNode.tabId = tabName
    end

    return {
        tabName = tabName,
        panelNode = domainPanelNode,
        selectedRoot = selectedRoot,
        domainNode = domainPanelNode and domainPanelNode._domainTabsNode or nil,
    }
end

function uiData.GetMainTabsNode(uiState)
    EnsureNodeCacheVersion()
    local olympiansState = BuildMainDomainTabState("Olympians", uiState)
    local otherGodsState = BuildMainDomainTabState("Other Gods", uiState)
    local hammersState = BuildMainDomainTabState("Hammers", uiState)
    local npcsState = BuildMainDomainTabState("NPCs", uiState)

    local settingsNode = uiData.GetSettingsPanelNode()
    settingsNode.tabLabel = "Settings"
    settingsNode.tabId = "Settings"
    local signature = table.concat({
        "Olympians",
        nodeCache.domainPanels["Olympians"] and nodeCache.domainPanels["Olympians"].signature or "",
        "Other Gods",
        nodeCache.domainPanels["Other Gods"] and nodeCache.domainPanels["Other Gods"].signature or "",
        "Hammers",
        nodeCache.domainPanels["Hammers"] and nodeCache.domainPanels["Hammers"].signature or "",
        "NPCs",
        nodeCache.domainPanels["NPCs"] and nodeCache.domainPanels["NPCs"].signature or "",
        "Settings",
    }, "|")

    local cacheEntry, node = lib.special.getCachedPreparedNode(nodeCache.mainTabs, signature, function()
        local children = {}
        if olympiansState.panelNode then
            children[#children + 1] = olympiansState.panelNode
        end
        if otherGodsState.panelNode then
            children[#children + 1] = otherGodsState.panelNode
        end
        if hammersState.panelNode then
            children[#children + 1] = hammersState.panelNode
        end
        if npcsState.panelNode then
            children[#children + 1] = npcsState.panelNode
        end
        children[#children + 1] = settingsNode
        return PrepareNode({
            type = "tabs",
            id = "BoonSubTabs",
            children = children,
        }, "BoonBans mainTabs")
    end)
    if node._activeTabKey == nil then
        if olympiansState.panelNode then
            node._activeTabKey = "Olympians"
        elseif otherGodsState.panelNode then
            node._activeTabKey = "Other Gods"
        elseif hammersState.panelNode then
            node._activeTabKey = "Hammers"
        elseif npcsState.panelNode then
            node._activeTabKey = "NPCs"
        else
            node._activeTabKey = "Settings"
        end
    end
    node._tabStateByKey = {}
    if olympiansState.panelNode then
        node._tabStateByKey["Olympians"] = {
            selectedRoot = olympiansState.selectedRoot,
            domainNode = olympiansState.domainNode,
        }
    end
    if otherGodsState.panelNode then
        node._tabStateByKey["Other Gods"] = {
            selectedRoot = otherGodsState.selectedRoot,
            domainNode = otherGodsState.domainNode,
        }
    end
    if hammersState.panelNode then
        node._tabStateByKey["Hammers"] = {
            selectedRoot = hammersState.selectedRoot,
            domainNode = hammersState.domainNode,
        }
    end
    if npcsState.panelNode then
        node._tabStateByKey["NPCs"] = {
            selectedRoot = npcsState.selectedRoot,
            domainNode = npcsState.domainNode,
        }
    end
    nodeCache.mainTabs = cacheEntry
    return node
end

local function BuildDomainPanelSignature(tabName, visibleRoots, totalCount, godPoolFiltering, uiState)
    local signatureParts = {
        tabName,
        tostring(totalCount),
        tostring(godPoolFiltering == true),
    }

    for _, root in ipairs(visibleRoots or uiData.EMPTY_LIST) do
        signatureParts[#signatureParts + 1] = uiData.GetRootNodeSignature(root, uiState)
    end

    return table.concat(signatureParts, "|")
end

function uiData.GetDomainPanelNode(tabName, visibleRoots, totalCount, godPoolFiltering, uiState)
    EnsureNodeCacheVersion()
    if type(tabName) ~= "string" or tabName == "" then
        return nil
    end

    local signature = BuildDomainPanelSignature(tabName, visibleRoots, totalCount, godPoolFiltering, uiState)
    local cacheEntry, node = lib.special.getCachedPreparedNode(nodeCache.domainPanels[tabName], signature, function()
        local children = {}
        local domainNode = nil

        if tabName == "Olympians" and godPoolFiltering then
            children[#children + 1] = {
                type = "text",
                text = string.format(
                    "Showing %d/%d Olympians enabled in God Pool.",
                    #visibleRoots,
                    totalCount),
                color = uiData.MUTED_TEXT_COLOR,
            }
        end

        if tabName == "NPCs" then
            children[#children + 1] = uiData.GetNpcRegionFilterPanelNode()
        end

        if #visibleRoots == 0 then
            children[#children + 1] = {
                type = "text",
                text = "No entries available.",
                color = uiData.MUTED_TEXT_COLOR,
            }
        else
            domainNode = uiData.GetDomainTabsNode(tabName, visibleRoots, uiState)
            if domainNode then
                children[#children + 1] = domainNode
            end
        end

        local nextNode = PrepareNode({
            type = "vstack",
            gap = 8,
            children = children,
        }, "BoonBans domainPanel " .. tabName)
        nextNode._domainTabsNode = domainNode
        return nextNode
    end)
    nodeCache.domainPanels[tabName] = cacheEntry
    return node
end

local function BuildRootDetailHeaderSpec(root, uiState)
    local titleNode = {
        type = "text",
        text = root.displayLabel,
        color = uiData.GetSourceColor(root.primaryScopeKey),
    }

    local headerSummary = uiData.GetRootHeaderSummary(root, uiState)
    if type(headerSummary) ~= "string" or headerSummary == "" then
        return titleNode
    end

    return {
        type = "split",
        orientation = "horizontal",
        firstSize = 220,
        gap = 12,
        children = {
            titleNode,
            {
                type = "text",
                text = headerSummary,
                color = uiData.MUTED_TEXT_COLOR,
            },
        },
    }
end

local function BuildRootDetailSpec(root, uiState)
    local children = {
        BuildRootDetailHeaderSpec(root, uiState),
    }

    if root.isTiered or root.hasRarity then
        children[#children + 1] = uiData.GetRootViewsTabsNode(root)
    else
        children[#children + 1] = uiData.GetBanPanelNode(root.primaryScopeKey)
    end

    return {
        type = "vstack",
        gap = 8,
        tabLabel = uiData.GetSelectorLabel(root, uiState),
        tabId = root.id,
        tabLabelColor = uiData.GetSourceColor(root.primaryScopeKey),
        children = children,
    }
end

function uiData.GetDomainTabsNode(tabName, visibleRoots, uiState)
    EnsureNodeCacheVersion()
    if type(tabName) ~= "string" or tabName == "" then
        return nil
    end

    local signatureParts = { tabName }
    for _, root in ipairs(visibleRoots or uiData.EMPTY_LIST) do
        signatureParts[#signatureParts + 1] = uiData.GetRootNodeSignature(root, uiState)
    end
    local signature = table.concat(signatureParts, "|")

    local cacheEntry, node = lib.special.getCachedPreparedNode(nodeCache.domainTabs[tabName], signature, function()
        local children = {}
        for _, root in ipairs(visibleRoots or uiData.EMPTY_LIST) do
            children[#children + 1] = BuildRootDetailSpec(root, uiState)
        end

        return PrepareNode({
            type = "tabs",
            id = "BoonBansDomain##" .. tabName,
            orientation = "vertical",
            binds = { activeTab = uiData.GetSelectedRootAlias(tabName) },
            navWidth = 260,
            children = children,
        }, "BoonBans domainTabs " .. tabName)
    end)

    nodeCache.domainTabs[tabName] = cacheEntry
    return node
end
