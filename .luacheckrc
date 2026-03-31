std = "lua52"
max_line_length = 150
globals = {
    "rom",
    "public",
    "config",
    "modutil",
    "game",
    "chalk",
    "reload",
    "_PLUGIN",
    "CurrentRun",
    "MetaUpgradeData",
    "LootSetData",


    "RunDirectorBoonBans_Internal"

}
read_globals = {
    "imgui",
    "import_as_fallback",
    "import",
    "SetupRunData",
    "UnitSetData",
    "SpellData",
    "TraitData",
    "MetaUpgradeDefaultCardLayout",
    "IsGameStateEligible",
    "GameState",
    "GetTotalHeroTraitValue",
    "GetEquippedWeapon",
    "IsGodTrait",
    "GameState",

    "GetTotalLootChoices"


}
exclude_files = { "src/main.lua", "src/main_special.lua" }