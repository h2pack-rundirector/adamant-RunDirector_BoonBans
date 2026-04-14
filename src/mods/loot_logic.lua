---@meta _
---@diagnostic disable: lowercase-global

local internal = RunDirectorBoonBans_Internal
local godMeta = internal.godMeta

internal.godInfo = internal.godInfo or {}
local godInfo = internal.godInfo

local band = bit32.band

local function IsBoonBansActive()
    return internal.IsBoonBansActive()
end

local function Log(fmt, ...)
    lib.logging.logIf(internal.definition.id, store.read("DebugMode") == true, fmt, ...)
end

local isKeepsakeOffering = false
local skipIsTraitEligible = false

local function ShuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function GeneratePriorityQueue(allowed, banned, godKey, currentTier, isHammer, priorityList, queueMaxSize, godBoonCount)
    local queue = {}
    local duoLegendaryQueue = {}

    for _, pending in ipairs(allowed) do
        local pendingName = pending.ItemName or pending.Name or pending.TraitName
        if pendingName then
            if not isHammer then
                local trait = TraitData[pendingName]
                local isDuo = trait and (trait.IsDuoBoon == true)
                local isLegendary = trait and (trait.RarityLevels and trait.RarityLevels.Legendary ~= nil)

                if isDuo or isLegendary then
                    pending.rarity = isDuo and "Duo" or "Legendary"
                    table.insert(duoLegendaryQueue, pending)
                end
            end

            if #queue < queueMaxSize then
                table.insert(queue, pending)
            end
        end
    end

    if store.read("EnablePadding") and #banned > 0 then
        -- Prioritize core boons (PriorityUpgrades) in padding for the first N god boons.
        -- After N boons have been picked, padding is a flat shuffle.
        local prioritizeN = store.read("Padding_PrioritizeCoreForFirstN") or 0
        local usePriority = (not isHammer) and (prioritizeN > 0) and (godBoonCount < prioritizeN)

        local prioritySet = {}
        if usePriority and priorityList then
            for _, name in ipairs(priorityList) do
                prioritySet[name] = true
            end
        end

        local highPrioPool = {}
        local lowPrioPool = {}

        for _, pending in ipairs(banned) do
            local pendingName = pending.ItemName or pending.Name or pending.TraitName
            local isHighPrio = usePriority and pendingName and prioritySet[pendingName]

            if isHighPrio then
                table.insert(highPrioPool, pending)
            else
                table.insert(lowPrioPool, pending)
            end
        end

        ShuffleTable(highPrioPool)
        ShuffleTable(lowPrioPool)

        -- Core boons go first, then the rest. No random bias — within the first N window
        -- core boons always lead the padding pool, after N everything is flat.
        local finalPool = {}
        for _, item in ipairs(highPrioPool) do table.insert(finalPool, item) end
        for _, item in ipairs(lowPrioPool) do table.insert(finalPool, item) end

        local avoidFuture = (store.read("Padding_AvoidFutureAllowed") ~= false)
        local allowDuos = (store.read("Padding_AllowDuos") == true)

        for _, pending in ipairs(finalPool) do
            local skipPadding = false

            if not isHammer then
                local pendingName = pending.ItemName or pending.Name or pending.TraitName

                if not allowDuos then
                    local trait = TraitData[pendingName]
                    if trait and (trait.IsDuoBoon or (trait.RarityLevels and trait.RarityLevels.Legendary)) then
                        skipPadding = true
                    end
                end

                if avoidFuture and not skipPadding and pendingName and godKey then
                    local info = internal.FindTraitInfo(pendingName, godKey)
                    if info then
                        local rootMeta = godMeta[godKey]
                        local maxTiers = (rootMeta and rootMeta.maxTiers) or 1
                        for tier = currentTier + 1, maxTiers do
                            local futureKey = (tier == 1) and godKey or (godKey .. tostring(tier))
                            if godMeta[futureKey] then
                                local futureConfig = internal.GetBanConfig(futureKey)
                                if band(futureConfig, info.mask) == 0 then
                                    skipPadding = true
                                    break
                                end
                            end
                        end
                    end
                end
            end

            if not skipPadding and #queue < queueMaxSize then
                table.insert(queue, pending)
            end
        end
    end

    if store.read("DebugMode") and #queue > 0 then
        Log("[Micro] PriorityQueue generated. Items: %d", #queue)
    end

    return queue, duoLegendaryQueue
end

modutil.mod.Path.Wrap("GetEligibleUpgrades", function(base, upgradeOptions, lootData, upgradeChoiceData)
    if not IsBoonBansActive() then return base(upgradeOptions, lootData, upgradeChoiceData) end

    local currentGodKey = internal.GetGodFromLootsource(lootData.Name)
    local isHammer = (lootData.Name == "WeaponUpgrade")

    local count = (internal.GetOrRecalcBoonCounts()[currentGodKey] or 0)
    local targetTier = count + 1

    Log("[Micro] Inspecting Loot: %s (God: %s, Tier: %d)", lootData.Name, tostring(currentGodKey), targetTier)

    if currentGodKey then
        local metaKey = (targetTier == 1) and currentGodKey or (currentGodKey .. tostring(targetTier))
        if not godMeta[metaKey] then
            Log("[Micro] Early exit for %s (Tier %d not configured)", tostring(currentGodKey), targetTier)
            return base(upgradeOptions, lootData, upgradeChoiceData)
        end
    end

    skipIsTraitEligible = true
    local fullList = base(upgradeOptions, lootData, upgradeChoiceData) or {}
    skipIsTraitEligible = false

    local allowed = {}
    local banned = {}
    local configCache = {}

    for _, option in ipairs(fullList) do
        local name = option and (option.ItemName or option.Name or option.TraitName)
        if name then
            local info = internal.FindTraitInfo(name, currentGodKey, targetTier)
            local isBanned = false
            if info then
                local cfg = configCache[info.god] or internal.GetBanConfig(info.god)
                configCache[info.god] = cfg
                if band(cfg, info.mask) ~= 0 then
                    isBanned = true
                end
            end

            if not isBanned then
                table.insert(allowed, option)
            else
                table.insert(banned, option)
            end
        end
    end

    Log("[Micro] Loot Result: Passed %d, Banned %d", #allowed, #banned)

    if #allowed == 0 then
        lootData._BoonBans_PendingAllowed = {}
        lootData._BoonBans_PendingFullCount = #fullList
        return fullList
    end

    local godBoonCount = (internal.GetOrRecalcBoonCounts()[currentGodKey] or 0)

    local queue, duoLegendaryQueue = GeneratePriorityQueue(
        allowed,
        banned,
        currentGodKey,
        targetTier,
        isHammer,
        lootData.PriorityUpgrades,
        GetTotalLootChoices(),
        godBoonCount
    )

    if store.read("DebugMode") then
        Log("Generated Priority Queue:")
        for i, queued in ipairs(queue) do
            Log("  %d. %s (Rarity: %s)", i, queued.ItemName, tostring(queued.rarity))
        end
    end

    lootData._BoonBans_PendingAllowed = allowed
    lootData._BoonBans_PendingFullCount = #fullList
    lootData._BoonBans_DuoLegendaryQueue = duoLegendaryQueue

    return queue
end)

modutil.mod.Path.Wrap("GetReplacementTraits", function(base, traitNames, onlyFromLootName)
    skipIsTraitEligible = true
    local result = base(traitNames, onlyFromLootName)
    skipIsTraitEligible = false
    return result
end)

modutil.mod.Path.Wrap("SetTraitsOnLoot", function(base, lootData, args)
    base(lootData, args)

    -- Consume pending state unconditionally to prevent stale values on next call.
    local allowed = lootData._BoonBans_PendingAllowed or {}
    local fullCount = lootData._BoonBans_PendingFullCount or 0
    lootData._BoonBans_PendingAllowed = nil
    lootData._BoonBans_PendingFullCount = nil

    -- Consume duo/legendary queue early so we have rarity info available during injection.
    local duoLegendaryQueue = lootData._BoonBans_DuoLegendaryQueue
    lootData._BoonBans_DuoLegendaryQueue = nil

    if not IsBoonBansActive() then return end

    local currentGodKey = internal.GetGodFromLootsource(lootData.Name)
    local targetTier = 1
    if currentGodKey then
        targetTier = (internal.GetOrRecalcBoonCounts()[currentGodKey] or 0) + 1
    end

    -- Rarity overrides: force configured rarity on unbanned boons that have a rarity setting.
    for _, item in ipairs(lootData.UpgradeOptions) do
        local name = item.ItemName or item.Name
        local info = internal.FindTraitInfo(name, nil)

        if info and info.god then
            local rootKey = internal.GetRootKey(info.god)
            if godMeta[rootKey] and godMeta[rootKey].rarityVar then
                local tierKey = rootKey
                if currentGodKey == rootKey and targetTier > 1 then
                    tierKey = rootKey .. tostring(targetTier)
                end

                local banConfig = internal.GetBanConfig(tierKey)
                local isBanned = band(banConfig, info.mask) ~= 0
                if not isBanned then
                    local rarityValue = internal.GetRarityValue(rootKey, info.bit)
                    if rarityValue > 0 then
                        local rarityMap = { [1] = "Common", [2] = "Rare", [3] = "Epic" }
                        local targetRarity = rarityMap[rarityValue]
                        if targetRarity then
                            item.Rarity = targetRarity
                            item.ForceRarity = true
                            Log("[Rarity] Forced %s on %s", targetRarity, name)
                        end
                    end
                end
            end
        end
    end

    -- Guarantee: if #allowed <= 2 and any allowed boon is absent from the offer (e.g. displaced
    -- by the vanilla replacement mechanic or failed the vanilla duo/legendary chance gate),
    -- inject it by displacing a padding slot. Replacement slots (TraitToReplace) and other
    -- allowed boons are never displaced.
    if #allowed <= 2 and #allowed > 0 then
        -- Build a rarity map from the duo/legendary queue so injected items get correct rarity.
        local duoRarityMap = {}
        if duoLegendaryQueue then
            for _, item in ipairs(duoLegendaryQueue) do
                if item.ItemName then
                    duoRarityMap[item.ItemName] = item.rarity
                end
            end
        end

        -- Build allowed set for displacement guard (built once before injection starts).
        local allowedSet = {}
        for _, item in ipairs(allowed) do
            local name = item.ItemName or item.Name or item.TraitName
            if name then allowedSet[name] = true end
        end

        -- Track what is currently in the offer.
        local inOffer = {}
        for _, item in ipairs(lootData.UpgradeOptions) do
            local name = item.ItemName or item.Name
            if name then inOffer[name] = true end
        end

        -- Find the single vanilla replacement slot (first TraitToReplace item). Only this
        -- index is protected from displacement — not all items with TraitToReplace.
        local replacementIdx = nil
        for i, item in ipairs(lootData.UpgradeOptions) do
            if item.TraitToReplace then
                replacementIdx = i
                break
            end
        end

        local maxChoices = GetTotalLootChoices()

        local function injectAllowedBoon(name)
            local duoRarity = duoRarityMap[name]
            local newOption = { ItemName = name, Type = "Trait" }
            if duoRarity then
                newOption.Rarity = duoRarity
                newOption.ForceRarity = true
            end

            if #lootData.UpgradeOptions < maxChoices then
                table.insert(lootData.UpgradeOptions, newOption)
                inOffer[name] = true
                Log("[Micro] Injected allowed boon '%s' into empty slot", name)
            else
                -- Displace the last padding slot: not the protected replacement index, not an allowed boon.
                local displaceIdx = nil
                for i = #lootData.UpgradeOptions, 1, -1 do
                    local item = lootData.UpgradeOptions[i]
                    local itemName = item.ItemName or item.Name
                    if itemName and i ~= replacementIdx and not allowedSet[itemName] then
                        displaceIdx = i
                        break
                    end
                end
                if displaceIdx then
                    lootData.UpgradeOptions[displaceIdx] = newOption
                    inOffer[name] = true
                    Log("[Micro] Injected allowed boon '%s' into slot %d (displaced padding)", name, displaceIdx)
                end
            end
        end

        for _, allowedItem in ipairs(allowed) do
            local name = allowedItem.ItemName or allowedItem.Name or allowedItem.TraitName
            if name and not inOffer[name] then
                injectAllowedBoon(name)
            end
        end
    end

    -- BlockReroll: vanilla sets this to true when its internal pool is exhausted, but our
    -- GetEligibleUpgrades filter makes the pool look artificially empty. Use fullCount
    -- (the unfiltered eligible pool size) as the real signal: if the full pool is larger
    -- than the offer, a reroll can surface different choices.
    if fullCount > GetTotalLootChoices() then
        lootData.BlockReroll = false
    end
end)

modutil.mod.Path.Wrap("IsTraitEligible", function(base, traitData, args)
    if not IsBoonBansActive() or skipIsTraitEligible then return base(traitData, args) end

    local info = internal.FindTraitInfo(traitData.Name, nil)
    if info then
        if isKeepsakeOffering and info.god == "Hades" and godMeta[info.god].duplicateOf == nil then
            if godInfo["HadesKeepsake"] then
                local cfg = internal.GetBanConfig("HadesKeepsake")
                if band(cfg, info.mask) ~= 0 then return false end
                return base(traitData, args)
            end
        end

        if band(internal.GetBanConfig(info.god), info.mask) ~= 0 then
            Log("[Micro] IsTraitEligible BLOCKED: %s", traitData.Name)
            return false
        end
    end
    return base(traitData, args)
end)

modutil.mod.Path.Wrap("GiveRandomHadesBoonAndBoostBoons", function(base, args)
    isKeepsakeOffering = true
    local result = base(args)
    isKeepsakeOffering = false
    return result
end)

modutil.mod.Path.Wrap("HeraSuperchargeBoon", function(base, args, origTraitData, contextArgs)
    local targetBoon = store.read("BridalGlowTargetBoon")
    if not targetBoon or targetBoon == "" then
        base(args, origTraitData, contextArgs)
        return
    end

    local targetTrait = GetHeroTrait(targetBoon)
    if not targetTrait or targetTrait.BlockStacking == true then
        base(args, origTraitData, contextArgs)
        return
    end

    contextArgs = contextArgs or {}

    local traitData = AddRarityToTraits(targetTrait, {
        ForceUpgrade = { targetTrait },
        TargetRarity = 4,
        Silent = true,
    })

    if not traitData then
        base(args, origTraitData, contextArgs)
        return
    end

    thread(AddStackToTraits, { TraitName = traitData.Name, NumStacks = args.Stacks, Silent = true })
    IncreaseTraitLevel(traitData, args.Stacks)

    origTraitData.UpgradedTraitName = traitData.Name
    thread(HeraTraitRarityPresentation, traitData.Name, args.Stacks, contextArgs.Delay)
end)
