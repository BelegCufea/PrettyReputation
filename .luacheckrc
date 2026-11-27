-- luacheck config: run `luacheck .` from the repo root.
--
-- The shared WoW config (Lua 5.1 dialect, ignore rules, WoW API names) lives
-- one folder up, in Programming/Lua/.luacheckrc. luacheck reads only one
-- config, so this one loads the shared file and appends this addon's own
-- names. A new WoW API name goes in the shared file; a name only this addon
-- writes or reads goes below.
local shared = {}
local chunk = loadfile("../.luacheckrc", "t", shared)
if chunk then
    chunk()
    for k, v in pairs(shared) do _ENV[k] = v end
else
    print("luacheck: ../.luacheckrc (shared WoW config) not found; using plain lua51")
    std = "lua51"
    max_line_length = false
end

local function Append(list, names)
    list = list or {}
    for _, name in ipairs(names) do list[#list + 1] = name end
    return list
end

-- exclude_files is relative to the config that sets it, so the shared
-- "Libs/**" does not reach this folder: repeat it here (vendored libraries).
exclude_files = Append(exclude_files, { "Libs/**" })

ignore = Append(ignore, {
    "212/info",     -- AceConfig get/set/disabled/hidden callbacks get `info` first
})

-- Other addons' and libraries' globals this addon reads.
read_globals = Append(read_globals, {
    "FactionAddictGT", "RepRewards_Data",       -- OptionalDeps: faction lists
    "DevTool", "ViragDevTool_AddData",          -- debug.lua table viewer
    "AceGUIWidgetLSMlists",                     -- AceGUI-3.0-SharedMediaWidgets
})
