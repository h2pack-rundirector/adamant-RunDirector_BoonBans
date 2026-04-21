local mods = rom.mods
mods["SGG_Modding-ENVY"].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods["SGG_Modding-ModUtil"]
local chalk = mods["SGG_Modding-Chalk"]
local reload = mods["SGG_Modding-ReLoad"]
---@type AdamantModpackLib
lib = mods["adamant-ModpackLib"]

local dataDefaults = import("config.lua")
local config = chalk.auto("config.lua")

local PACK_ID = "run-director"
---@class RunDirectorBoonBansInternal
---@field definition ModuleDefinition|nil
---@field store ManagedStore|nil
---@field standaloneUi StandaloneRuntime|nil
---@field BuildDefinitionStorage fun(config: table)|nil
---@field RegisterHooks fun()|nil
---@field DrawTab fun(imgui: table, session: AuthorSession)|nil
---@field DrawQuickContent fun(imgui: table, session: AuthorSession)|nil
RunDirectorBoonBans_Internal = RunDirectorBoonBans_Internal or {}
---@type RunDirectorBoonBansInternal
local internal = RunDirectorBoonBans_Internal

public.definition = {
    modpack = PACK_ID,
    id = "BoonBans",
    name = "Boon Bans",
    tooltip = "Ban boon offerings, force rarity, and configure padding behavior.",
    default = dataDefaults.Enabled,
    affectsRunData = false,
}
internal.definition = public.definition

public.host = nil
local store
local session
internal.standaloneUi = nil


local function init()
    import_as_fallback(rom.game)
    import("mods/god_meta.lua")
    import("mods/boon_catalog.lua")
    import("mods/data.lua")
    import("mods/logic.lua")
    import("mods/ui.lua")

    internal.BuildDefinitionStorage(dataDefaults)
    store, session = lib.createStore(config, public.definition, dataDefaults)
    internal.store = store
    public.host = lib.createModuleHost({
        definition = public.definition,
        store = store,
        session = session,
        hookOwner = internal,
        registerHooks = internal.RegisterHooks,
        drawTab = internal.DrawTab,
        drawQuickContent = internal.DrawQuickContent,
    })
    internal.standaloneUi = lib.standaloneHost(public.host)
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(nil, init)
end)

local function renderStandaloneWindow()
    if internal.standaloneUi and internal.standaloneUi.renderWindow then
        internal.standaloneUi.renderWindow()
    end
end

---@diagnostic disable-next-line: redundant-parameter
rom.gui.add_imgui(renderStandaloneWindow)

local function addStandaloneMenuBar()
    if internal.standaloneUi and internal.standaloneUi.addMenuBar then
        internal.standaloneUi.addMenuBar()
    end
end

---@diagnostic disable-next-line: redundant-parameter
rom.gui.add_to_menu_bar(addStandaloneMenuBar)
