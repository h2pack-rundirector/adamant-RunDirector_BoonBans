local internal = RunDirectorBoonBans_Internal
local uiData = internal.ui

local function ContractWarn(fmt, ...)
    if lib and type(lib.contractWarn) == "function" then
        lib.contractWarn("run-director", fmt, ...)
    end
end

local function ClampRarity(value)
    local numeric = math.floor(tonumber(value) or 0)
    if numeric < 0 then
        return 0
    end
    if numeric > 3 then
        return 3
    end
    return numeric
end

public.definition = public.definition or internal.definition or {}
internal.definition = public.definition

local function GetBridalGlowEligibleRoots(uiState)
    if uiData.bridalGlowEligibleRoots then
        return uiData.bridalGlowEligibleRoots
    end

    local roots = uiData.GetVisibleRoots("Olympians", uiState)
    local cached = {}
    for i, root in ipairs(roots) do
        cached[i] = root
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
            table.insert(boons, boon)
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
            if root.rootKey == transientRootKey then
                return root
            end
        end
    end

    local matchedRoot = FindBridalGlowRootForTarget(roots, selectedBoonKey)
    if matchedRoot then
        uiData.bridalGlowSelection.rootKey = matchedRoot.rootKey
        return matchedRoot
    end

    local fallback = roots[1]
    uiData.bridalGlowSelection.rootKey = fallback and fallback.rootKey or nil
    return fallback
end

public.definition.customTypes = {
    widgets = {
        bridalGlowPicker = {
            binds = {},
            slots = { "value" },
            validate = function(_, _) end,
            draw = function(ui, node, _, _, uiState)
                local _ = node
                local paneHeight = 220
                local godPaneWidth = 200
                local selectedBoonKey = uiState.view.BridalGlowTargetBoon or ""
                local eligibleRoots = GetBridalGlowEligibleRoots(uiState)
                if #eligibleRoots == 0 then
                    return lib.drawWidgetSlots(ui, node, {
                        {
                            name = "value",
                            draw = function(imgui)
                                imgui.TextDisabled("No eligible Olympian gods are currently available.")
                                return false
                            end,
                        },
                    })
                end

                local selectedRoot = EnsureBridalGlowRootSelection(eligibleRoots, selectedBoonKey)
                local selectedRootKey = selectedRoot and selectedRoot.rootKey or nil
                local eligibleBoons = GetBridalGlowEligibleBoons(selectedRoot)

                return lib.drawWidgetSlots(ui, node, {
                    {
                        name = "value",
                        draw = function(imgui)
                            imgui.BeginChild("##BridalGlowGodList", godPaneWidth, paneHeight, true)
                            imgui.TextDisabled("Eligible Gods")
                            imgui.Separator()
                            for _, root in ipairs(eligibleRoots) do
                                if imgui.Selectable(root.displayLabel, root.rootKey == selectedRootKey) then
                                    uiData.bridalGlowSelection.rootKey = root.rootKey
                                    selectedRoot = root
                                    selectedRootKey = root.rootKey
                                    eligibleBoons = GetBridalGlowEligibleBoons(selectedRoot)
                                end
                            end
                            imgui.EndChild()

                            imgui.SameLine()
                            imgui.BeginChild("##BridalGlowBoonList", 0, paneHeight, true)
                            imgui.TextDisabled("Eligible Boons")
                            imgui.Separator()
                            if imgui.Selectable("Random", selectedBoonKey == "") then
                                selectedBoonKey = ""
                                internal.SetBridalGlowTargetBoonKey(nil, uiState)
                            end
                            for _, boon in ipairs(eligibleBoons) do
                                if imgui.Selectable(boon.BridalGlowLabel, boon.Key == selectedBoonKey) then
                                    selectedBoonKey = boon.Key
                                    internal.SetBridalGlowTargetBoonKey(boon.Key, uiState)
                                end
                            end
                            imgui.EndChild()
                            return false
                        end,
                    },
                })
            end,
        },
        forceRarityStatus = {
            binds = {
                value = { storageType = "int", rootType = "packedInt" },
            },
            validate = function(node, prefix)
                if type(node.forceScopeKey) ~= "string" or node.forceScopeKey == "" then
                    ContractWarn("%s: forceRarityStatus forceScopeKey must be a non-empty string", prefix)
                end
                if type(node.rarityScopeKey) ~= "string" or node.rarityScopeKey == "" then
                    ContractWarn("%s: forceRarityStatus rarityScopeKey must be a non-empty string", prefix)
                end
            end,
            draw = function(ui, node, bound, width, uiState)
                local _ = width
                local packedMask = bound.value and bound.value:get() or 0
                local forcedBoon = uiData.GetForcedBoonSelection(node.forceScopeKey, packedMask)
                if type(forcedBoon) ~= "table" or not uiData.IsRarityEligibleBoon(forcedBoon) then
                    return false
                end

                local rarityAlias = internal.GetRarityAlias(node.rarityScopeKey, forcedBoon.Key)
                if type(rarityAlias) ~= "string" or rarityAlias == "" then
                    return false
                end

                local currentValue = ClampRarity(uiState and uiState.view and uiState.view[rarityAlias])
                local startX = ui.GetCursorPosX()
                local startY = ui.GetCursorPosY()
                local frameHeight = ui.GetFrameHeight()
                local valueSlotStart = startX + 10
                local valueText = tostring(uiData.RARITY_LABELS[currentValue] or currentValue)
                local valueColor = uiData.RARITY_COLORS[currentValue]
                local textWidth = ui.CalcTextSize(valueText)
                local alignedValueX = valueSlotStart + math.max((100 - textWidth) / 2, 0)
                local id = node._imguiId or rarityAlias or node.rarityScopeKey
                local drawStructuredAt = lib.WidgetHelpers and lib.WidgetHelpers.drawStructuredAt
                if type(drawStructuredAt) ~= "function" then
                    return false
                end

                local changed = drawStructuredAt(ui, startX, startY, frameHeight, function()
                    ui.PushID(id)

                    ui.SetCursorPos(startX, startY)
                    local localChanged = false
                    if ui.Button("-") and currentValue > 0 then
                        currentValue = currentValue - 1
                        uiState.set(rarityAlias, currentValue)
                        localChanged = true
                    end

                    ui.SetCursorPos(alignedValueX, startY)
                    if type(valueColor) == "table" then
                        ui.TextColored(valueColor[1], valueColor[2], valueColor[3], valueColor[4], valueText)
                    else
                        ui.Text(valueText)
                    end

                    ui.SetCursorPos(startX + 100, startY)
                    if ui.Button("+") and currentValue < 3 then
                        currentValue = currentValue + 1
                        uiState.set(rarityAlias, currentValue)
                        localChanged = true
                    end

                    ui.PopID()
                    return localChanged
                end)
                return changed == true
            end,
        },
    }
}
