local internal = RunDirectorBoonBans_Internal

function internal.RegisterHooks()
    _G.bit32 = require("bit32")

    import("mods/logic/utilities.lua")
    import("mods/logic/runtime_state.lua")
    import("mods/logic/npc_logic.lua")
    import("mods/logic/loot_logic.lua")
end

return internal
