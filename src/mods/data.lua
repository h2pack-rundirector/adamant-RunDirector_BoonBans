local internal = RunDirectorBoonBans_Internal

local function BuildPackedStorageNode(item)
    local bits = internal.GetPackedStorageBits(item.key)
    if not bits then
        return {
            type = "int",
            alias = item.key,
            configKey = item.key,
        }
    end

    local packedWidth = nil
    local lastBit = bits[#bits]
    if lastBit then
        packedWidth = lastBit.offset + lastBit.width
    end

    return {
        type = "packedInt",
        alias = item.key,
        configKey = item.key,
        default = item.default,
        width = packedWidth,
        bits = bits,
    }
end

function internal.BuildDefinitionStorage(config)
    internal.definition.storage = {
        { type = "bool",   alias = "EnablePadding",                   configKey = "EnablePadding" },
        { type = "int",    alias = "Padding_PrioritizeCoreForFirstN", configKey = "Padding_PrioritizeCoreForFirstN", min = 0, max = 15 },
        { type = "bool",   alias = "Padding_AvoidFutureAllowed",      configKey = "Padding_AvoidFutureAllowed" },
        { type = "bool",   alias = "Padding_AllowDuos",               configKey = "Padding_AllowDuos" },
        { type = "int",    alias = "ImproveFirstNBoonRarity",         configKey = "ImproveFirstNBoonRarity",         min = 0, max = 15 },
        { type = "string", alias = "BridalGlowTargetBoon",            configKey = "BridalGlowTargetBoon",            maxLen = 128 },
        { type = "int",    alias = "NpcViewRegion",                   lifetime = "transient",                         default = 4, min = 1, max = 4 },
        { type = "string", alias = "BanFilterText",                   lifetime = "transient",                         default = "", maxLen = 128 },
        { type = "string", alias = "SelectedRoot_Olympians",          lifetime = "transient",                         default = "", maxLen = 64 },
        { type = "string", alias = "SelectedRoot_Other Gods",         lifetime = "transient",                         default = "", maxLen = 64 },
        { type = "string", alias = "SelectedRoot_Hammers",            lifetime = "transient",                         default = "", maxLen = 64 },
        { type = "string", alias = "SelectedRoot_NPCs",               lifetime = "transient",                         default = "", maxLen = 64 },
    }

    local packedKeys = {}
    for key, value in pairs(config) do
        if type(key) == "string" and key:find("^Packed") then
            table.insert(packedKeys, { key = key, default = value })
        end
    end
    table.sort(packedKeys, function(a, b)
        return a.key < b.key
    end)
    for _, item in ipairs(packedKeys) do
        table.insert(internal.definition.storage, BuildPackedStorageNode(item))
    end
end

return internal
