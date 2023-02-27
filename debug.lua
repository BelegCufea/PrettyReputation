local Addon = select(2, ...)

local DEBUG = {}
Addon.DEBUG = DEBUG

local Const = Addon.CONST

function DEBUG:Info(value, name, type)
    if not Addon.db.profile.Debug then return end
    if not name then name = Const.METADATA.NAME end

    if (not type) or (type == "Print") then
        Addon:Print(name, value)
        return
    end

    if (type == "VDT") and ViragDevTool_AddData then
        ViragDevTool_AddData(value, Const.METADATA.NAME .. "_" .. name)
        return
    end

end