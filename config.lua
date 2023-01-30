local Addon = select(2, ...)

local Config = Addon:NewModule("Config")
Addon.Config = Config

local TAGS = {
    {"name", "Name of the faction"},
    {"c_name", "Name of the faction colored by standing"},
    {"standing", "Current reputation standing"},
    {"c_standing", "Colored current reputation standing"},
    {"change", "Actual gain/loss of reputation"},
    {"c_change", "Actual gain/loss of reputation (green for gain, red for loss)"},
    {"session", "Gain of reputation in current session"},
    {"c_session", "Gain of reputation in current session (green for gain, red for loss)"},
    {"current", "Current reputation value"},
    {"next", "Reputation boundary for next level"},
    {"bottom", "Minimum reputation in current standing"},
    {"top", "Maximum reputation in current standing"},
    {"toGo", "Reputation to gain/loss for next/previous standing"},
    {"changePercent", "Percentual change of reputation"},
    {"currentPercent", "Percent of next standing"},
    {"paragonLevel", "Paragon level"},
    {"c_paragonLevel", "Colored paragon level"},
    {"renownLevel", "Renown level"},
    {"c_renownLevel", "Colored renown level"},
    {"bar", "Shows barlike progress representation of current standing"}
}

local function tags()
    local result = ""
    for i,v in pairs(TAGS) do
       result = result .. Addon.CONST.CONFIG_COLORS.TAG .. "[" .. v[1] .. "]|r - " .. v[2] .. "\n"
    end
    return result
end

local function standingColorsPresets()
    local presets = {}
    presets["custom"] = "Custom"
    presets["blizzard"] = "Blizzard"
    presets["ascii"] = "Ara Reputation"
    presets["wowpro"] = "WoW-Pro (default)"
    presets["tiptac"] = "TipTac"
    presets["elvui"] = "ElvUI Progressively Colored DataBars"

    return presets
end

local function standingColorsSet(value)
    local function copy(obj, seen)
        if type(obj) ~= 'table' then return obj end
        if seen and seen[obj] then return seen[obj] end
        local s = seen or {}
        local res = setmetatable({}, getmetatable(obj))
        s[obj] = res
        for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
        return res
    end
      
    local REP_COLORS = copy(Addon.CONST.REP_COLORS)
    if value == "blizzard" then Addon.db.profile.Colors = REP_COLORS.blizzardColors end
    if value == "ascii" then Addon.db.profile.Colors = REP_COLORS.asciiColors end
    if value == "wowpro" then Addon.db.profile.Colors = REP_COLORS.wowproColors end
    if value == "tiptac" then Addon.db.profile.Colors = REP_COLORS.tiptacColors end
    if value == "elvui" then Addon.db.profile.Colors = REP_COLORS.elvuiColors end
    Addon.db.profile.ColorsPreset = value
end

local options = {
	name = AddonTitle,
	type = "group",
    childGroups = "tab",
	args = {
        Enabled = {
            type = "toggle",
            order = 1,
            name = "Enabled",
            desc = "Print prettified reputation message into chat",
            get = function(info) return Addon.db.profile.Enabled end,
            set = function(info, value)
                Addon.db.profile.Enabled = value
            end 
        },
        MiniMap = {
            type = "toggle",
            order = 2,
            name = "Show minmap icon",
            get = function(info) return not Addon.db.profile.minimapIcon.hide end,
            set = function(info, value)                
                Addon.db.profile.minimapIcon.hide = not value
                if Addon.db.profile.minimapIcon.hide == true then
                    Addon.icon:Hide(Addon.CONST.METADATA.NAME)
                  else
                    Addon.icon:Show(Addon.CONST.METADATA.NAME)
                  end
            end 
        },
        Message = {
            type = "group",
            order = 10,
            name = "Message",
            args = {
                Pattern = {
                    type = "group",
                    order = 11,
                    name = "Message",
                    inline = true,
                    args = {
                        MessageBody = {
                            type = "input",
                            order = 1, 
                            name = "pattern",
                            desc = "Construct your reputation message",
                            width = "full",
                            get = function(info) return Addon.db.profile.Reputation.pattern end,
                            set = function(info, value)
                                Addon.db.profile.Reputation.pattern = value
                            end
                        },
                        DefaultMessageSet = {
                            type = "execute",
                            order = 2,
                            name = "Set default pattern",
                            desc = Addon.CONST.PATTERN,
                            func = function() Addon.db.profile.Reputation.pattern = Addon.CONST.PATTERN end
                        },
                    }          
                },
                Bar = {
                    type = "group",
                    order = 11,
                    name = "Progress bar",
                    inline = true,
                    args = {
                        MessageBarCharacter = {
                            type = "input",
                            order = 1,
                            name = "bar character",
                            desc = "character to be used for 1bar in barlike progress",
                            width = "half",
                            get = function(info) return Addon.db.profile.Reputation.barChar end,
                            set = function(info, value)
                                Addon.db.profile.Reputation.barChar = value
                            end
                        },
                        MessageBarLength = {
                            type = "range",
                            order = 2,
                            name = "bar length",
                            desc = "number of bars in barlike progress (would be nice to be clean divider of 100)",
                            min = 1,
                            max = 100,
                            softMin = 5,
                            softMax = 50,
                            step = 1,
                            bigStep = 5,
                            get = function(info) return Addon.db.profile.Reputation.barLength end,
                            set = function(info, value)
                                Addon.db.profile.Reputation.barLength = value
                            end
                        },      
                    }                      
                },
                MessageParagonCount = {
                    type = "toggle",
                    order = 12,
                    name = "show paragon count",
                    desc = "show paragon count in standing text",
                    width = "full",
                    get = function(info) return Addon.db.profile.Reputation.showParagonCount end,
                    set = function(info, value)
                        Addon.db.profile.Reputation.showParagonCount = value
                    end            
                }, 
                TagsHeader = {
                    type = "header",
                    order = 30,
                    name = "Available tags"
                },
                AvailableTags = {
                    type = "description",
                    order = 31,
                    name = tags()
                },        
            },   
        },
        Colors = {
            type = "group",
            order = 20,
            name = "Colors",
            args = {
                ReputationColors = {
                    type = "group",
                    order = 21,
                    name = "Reputation standning colors",
                    inline = true,
                    args = {
                        Hated = {
                            type = "color",
                            order = 1,
                            name = Addon.CONST.REP_STANDING[1],
                            get = function(info)
                                local color = Addon.db.profile.Colors[1]
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(info, r, g, b, a)
                                local color = Addon.db.profile.Colors[1]
                                color.r, color.g, color.b, color.a = r, g, b, a
                                Addon.db.profile.ColorsPreset = "custom"
                            end
                        },
                        Hostile = {
                            type = "color",
                            order = 2,
                            name = Addon.CONST.REP_STANDING[2],
                            get = function(info)
                                local color = Addon.db.profile.Colors[2]
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(info, r, g, b, a)
                                local color = Addon.db.profile.Colors[2]
                                color.r, color.g, color.b, color.a = r, g, b, a
                                Addon.db.profile.ColorsPreset = "custom"
                            end
                        },
                        Unfriendly = {
                            type = "color",
                            order = 3,
                            name = Addon.CONST.REP_STANDING[3],
                            get = function(info)
                                local color = Addon.db.profile.Colors[3]
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(info, r, g, b, a)
                                local color = Addon.db.profile.Colors[3]
                                color.r, color.g, color.b, color.a = r, g, b, a
                                Addon.db.profile.ColorsPreset = "custom"
                            end
                        },
                        Neutral = {
                            type = "color",
                            order = 4,
                            name = Addon.CONST.REP_STANDING[4],
                            get = function(info)
                                local color = Addon.db.profile.Colors[4]
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(info, r, g, b, a)
                                local color = Addon.db.profile.Colors[4]
                                color.r, color.g, color.b, color.a = r, g, b, a
                                Addon.db.profile.ColorsPreset = "custom"
                            end
                        },
                        Friendly = {
                            type = "color",
                            order = 5,
                            name = Addon.CONST.REP_STANDING[5],
                            get = function(info)
                                local color = Addon.db.profile.Colors[5]
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(info, r, g, b, a)
                                local color = Addon.db.profile.Colors[5]
                                color.r, color.g, color.b, color.a = r, g, b, a
                                Addon.db.profile.ColorsPreset = "custom"
                            end
                        },
                        Honored = {
                            type = "color",
                            order = 6,
                            name = Addon.CONST.REP_STANDING[6],
                            get = function(info)
                                local color = Addon.db.profile.Colors[6]
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(info, r, g, b, a)
                                local color = Addon.db.profile.Colors[6]
                                color.r, color.g, color.b, color.a = r, g, b, a
                                Addon.db.profile.ColorsPreset = "custom"
                            end
                        },
                        Revered = {
                            type = "color",
                            order = 7,
                            name = Addon.CONST.REP_STANDING[7],
                            get = function(info)
                                local color = Addon.db.profile.Colors[7]
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(info, r, g, b, a)
                                local color = Addon.db.profile.Colors[7]
                                color.r, color.g, color.b, color.a = r, g, b, a
                                Addon.db.profile.ColorsPreset = "custom"
                            end
                        },
                        Exalted = {
                            type = "color",
                            order = 8,
                            name = Addon.CONST.REP_STANDING[8],
                            get = function(info)
                                local color = Addon.db.profile.Colors[8]
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(info, r, g, b, a)
                                local color = Addon.db.profile.Colors[8]
                                color.r, color.g, color.b, color.a = r, g, b, a
                                Addon.db.profile.ColorsPreset = "custom"
                            end
                        },
                        Paragon = {
                            type = "color",
                            order = 9,
                            name = Addon.CONST.REP_STANDING[9],
                            get = function(info)
                                local color = Addon.db.profile.Colors[9]
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(info, r, g, b, a)
                                local color = Addon.db.profile.Colors[9]
                                color.r, color.g, color.b, color.a = r, g, b, a
                                Addon.db.profile.ColorsPreset = "custom"
                            end
                        },
                        Renown = {
                            type = "color",
                            order = 10,
                            name = Addon.CONST.REP_STANDING[10],
                            get = function(info)
                                local color = Addon.db.profile.Colors[10]
                                return color.r, color.g, color.b, color.a
                            end,
                            set = function(info, r, g, b, a)
                                local color = Addon.db.profile.Colors[10]
                                color.r, color.g, color.b, color.a = r, g, b, a
                                Addon.db.profile.ColorsPreset = "custom"
                            end
                        },
                    }
                },
                ReputationColorsPresets = {
                    type = "select",
                    order = 22,
                    name = "Standing colors presets",
                    values = standingColorsPresets(),
                    style = "dropdown",
                    width = "double",
                    get = function(info) return Addon.db.profile.ColorsPreset end,
                    set = function(info, value)
                        standingColorsSet(value)
                    end,
                },
            }
        },    
	},
}

function Config:OnEnable()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(Addon.CONST.METADATA.NAME, options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(Addon.CONST.METADATA.NAME)
end