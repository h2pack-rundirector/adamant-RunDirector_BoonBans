-- luacheck: globals TestAcquisitionLogic TraitData

local lu = require("luaunit")

TestAcquisitionLogic = {}

function TestAcquisitionLogic:setUp()
    public = {}
    _PLUGIN = { guid = "test-boon-bans-acquisition" }

    lib = {
        isModuleEnabled = function()
            return true
        end,
        hooks = {
            Wrap = function() end,
        },
        logging = {
            logIf = function() end,
        },
    }

    TraitData = {
        ReboundingSparkBoon = { IsDuoBoon = true },
        ZeusStrikeBoon = {},
    }

    RunDirectorBoonBans_Internal = {
        definition = {
            id = "BoonBans",
            modpack = "RunDirector",
        },
        store = {
            read = function()
                return false
            end,
        },
        godMeta = {
            Zeus = {
                key = "Zeus",
                lootSource = { key = "ZeusUpgrade" },
            },
            Apollo = {
                key = "Apollo",
                lootSource = { key = "ApolloUpgrade" },
            },
        },
        godInfo = {
            traitLookup = {
                ZeusStrikeBoon = {
                    { god = "Zeus" },
                },
                ReboundingSparkBoon = {
                    { god = "Apollo" },
                },
            },
        },
    }

    self.internal = RunDirectorBoonBans_Internal
    self.internal.GetGodFromLootsource = function(lootKey)
        if lootKey == "ZeusUpgrade" then
            return "Zeus"
        end
        if lootKey == "ApolloUpgrade" then
            return "Apollo"
        end
        return nil
    end
    self.internal.GetRootKey = function(key)
        return key
    end
    self.internal.FindTraitInfo = function(traitName)
        local list = self.internal.godInfo.traitLookup[traitName]
        return list and list[1] or nil
    end

    dofile("src/mods/logic/acquisition.lua")
end

function TestAcquisitionLogic:testResolveAcquiredGodKeyPrefersStampedDuoSource()
    self.internal.ActiveGodKey = "Apollo"

    local acquiredTrait = {
        Name = "ReboundingSparkBoon",
        [self.internal.BoonOfferSourceField] = "ZeusUpgrade",
    }

    local godKey, sourceMode = self.internal.ResolveAcquiredGodKey({ FromLoot = true }, acquiredTrait, acquiredTrait)

    lu.assertEquals(godKey, "Zeus")
    lu.assertEquals(sourceMode, "stamped-source")
end

function TestAcquisitionLogic:testResolveAcquiredGodKeyFallsBackToCatalogForNonDuo()
    local acquiredTrait = {
        Name = "ZeusStrikeBoon",
    }

    local godKey, sourceMode = self.internal.ResolveAcquiredGodKey({}, acquiredTrait, acquiredTrait)

    lu.assertEquals(godKey, "Zeus")
    lu.assertEquals(sourceMode, "catalog")
end

function TestAcquisitionLogic:testShouldAdvanceBoonTierRequiresLootAcquisitionWithoutSkipFlags()
    local acquiredTrait = {
        Name = "ZeusStrikeBoon",
    }

    local shouldAdvance, reason = self.internal.ShouldAdvanceBoonTier({}, acquiredTrait, acquiredTrait, "Zeus")
    lu.assertFalse(shouldAdvance)
    lu.assertEquals(reason, "not-from-loot")

    shouldAdvance, reason = self.internal.ShouldAdvanceBoonTier(
        { FromLoot = true, SkipActivatedTraitUpdate = true },
        acquiredTrait,
        acquiredTrait,
        "Zeus"
    )
    lu.assertFalse(shouldAdvance)
    lu.assertEquals(reason, "skip-activated-update")

    shouldAdvance, reason = self.internal.ShouldAdvanceBoonTier(
        { FromLoot = true },
        acquiredTrait,
        acquiredTrait,
        "Zeus"
    )
    lu.assertTrue(shouldAdvance)
    lu.assertEquals(reason, "counted")
end
