local Addon = select(2, ...)

local Config = Addon:NewModule("Config")
Addon.Config = Config
local ConfigRegistry = LibStub("AceConfigRegistry-3.0")
local ConfigDialog = LibStub("AceConfigDialog-3.0")

local factions = Addon.Factions
local Debug = Addon.DEBUG


local function tags()
    local result = ""
    local tkeys = {}
    -- populate the table that holds the keys
    for k in pairs(Addon.TAGS.Definition) do table.insert(tkeys, k) end
    -- sort the keys
    table.sort(tkeys)
    -- use the keys to retrieve the values in the sorted order
    for _, k in ipairs(tkeys) do
        result = result .. Addon.CONST.CONFIG_COLORS.TAG .. "[" .. k .. "]|r - " .. Addon.TAGS.Definition[k].desc .. "\n"
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

local function contains_item(t, item)
    if next(t) == nil then return false end
    for _, value in pairs(t) do
        if value == item then
            return true
        end
    end
    return false
end

local function remove_item(t, item)
    local new_table = {}
    for _, value in pairs(t) do
        if value ~= item then
            table.insert(new_table, value)
        end
    end
    return new_table
end

local function ChatFrameGet(info)
    return contains_item(Addon.db.profile.sinkChatFrames, info[#info])
end

local function ChatFrameSet(info, value)
    if value then
        table.insert(Addon.db.profile.sinkChatFrames, info[#info])
    else
        Addon.db.profile.sinkChatFrames = remove_item(Addon.db.profile.sinkChatFrames, info[#info])
    end
end

local function getChatFrames()
    local options = {
        type = "group",
        name = "Output to Chat Frames",
        inline = true,
        disabled = function() return (not (Addon.db.profile.sinkChat)) or (Addon.db.profile.sink20OutputSink == "ChatFrame") end,
    }

    local frames = {}
    for i = 1, NUM_CHAT_WINDOWS do
		local name = strlower(GetChatWindowInfo(i) or "")
		if name ~= "" and _G["ChatFrame"..i.."Tab"]:IsVisible() then
            local frame = {
                type = "toggle",
                order = i,
                name = _G["ChatFrame" .. i].name,
                get = ChatFrameGet,
                set = ChatFrameSet,
            }
            frames["ChatFrame" .. i] = frame
		end
    end

    options.args = frames

    return options
end

local function getFactions()
    local list = {}

    local found

    for k,_ in pairs(factions) do
        if not found then found = k end
        if k == Addon.db.profile.Test.faction then found = k end
        list[k] = k
    end

    Addon.db.profile.Test.faction = found

    list["Darkmoon Faire"] = "Darkmoon Faire"
    table.sort(list)
    return list
end

local function SetBarsOptions()
    Addon:SetBarsOptions()
    Addon:UpdateBars()
end

local options = {
	name = AddonTitle,
	type = "group",
	args = {
        Settings = {
            type = "group",
            order = 10,
            name = "Options",
            childGroups = "tab",
            args = {
                General = {
                    type = "group",
                    order = 0,
                    name = "General",
                    args = {
                        Enabled = {
                            type = "toggle",
                            order = 1,
                            name = "Enabled",
                            desc = "Print prettified reputation message into chat",
                            width = "full",
                            get = function(info) return Addon.db.profile.Enabled end,
                            set = function(info, value)
                                Addon.db.profile.Enabled = value
                                Addon:UpdateDataBrokerText()
                                Addon:SetBarsOptions()
                            end
                        },
                        MiniMap = {
                            type = "toggle",
                            order = 2,
                            name = "Show minmap icon",
                            width = "full",
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
                        Track = {
                            type = "group",
                            order = 3,
                            name = "Track",
                            inline = true,
                            args = {
                                Enabled = {
                                    type = "toggle",
                                    order = 1,
                                    name = "Auto track",
                                    desc = "Set faction with latest reputation change as watched",
                                    get = function(info) return Addon.db.profile.Track end,
                                    set = function(info, value)
                                        Addon.db.profile.Track = value
                                    end
                                },
                                OnlyPositive = {
                                    type = "toggle",
                                    order = 2,
                                    name = "Only gain",
                                    desc = "Only switch on a gain (not on a loss)",
                                    get = function(info) return Addon.db.profile.TrackPositive end,
                                    set = function(info, value)
                                        Addon.db.profile.TrackPositive = value
                                    end,
                                    disabled = function() return not (Addon.db.profile.Track) end
                                },
                                Guild = {
                                    type = "toggle",
                                    order = 3,
                                    name = "Guild",
                                    desc = "Also switch on guild reputation change",
                                    get = function(info) return Addon.db.profile.TrackGuild end,
                                    set = function(info, value)
                                        Addon.db.profile.TrackGuild = value
                                    end,
                                    disabled = function() return not (Addon.db.profile.Track) end
                                }
                            }
                        },
                        Tooltip = {
                            type = "select",
                            order = 4,
                            name = "Sort minimap/databroker tooltip by",
                            values = {
                                ["value"] = "Session gain/loss",
                                ["faction"] = "Faction name",
                            },
                            style = "dropdown",
                            get = function(info) return Addon.db.profile.TooltipSort end,
                            set = function(info, value)
                                Addon.db.profile.TooltipSort = value
                            end,
                        },
                        Seperator1 = { type = "description", order = 5, fontSize = "small",name = "",width = "full", },
                        Debug = {
                            type = "toggle",
                            order = 9,
                            name = "Debug",
                            desc = "Print debug messages in chat",
                            width = "full",
                            get = function(info) return Addon.db.profile.Debug end,
                            set = function(info, value)
                                Addon.db.profile.Debug = value
                            end
                        },
                    }
                },
                Message = {
                    type = "group",
                    order = 10,
                    name = "Message",
                    args = {
                        Pattern = {
                            type = "group",
                            order = 10,
                            name = "Message",
                            inline = true,
                            args = {
                                MessageBody = {
                                    type = "input",
                                    order = 1,
                                    name = "pattern",
                                    desc = "Construct your reputation message",
                                    width = 2.75,
                                    multiline =true,
                                    get = function(info) return Addon.db.profile.Reputation.pattern end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.pattern = value
                                    end
                                },
                                DefaultMessageSet = {
                                    type = "execute",
                                    order = 2,
                                    name = "Default",
                                    desc = Addon.CONST.PATTERN,
                                    width = "half",
                                    func = function() Addon.db.profile.Reputation.pattern = Addon.CONST.PATTERN end
                                },
                            },
                        },
                        TagsHeader = {
                            type = "header",
                            order = 30,
                            name = "Available tags"
                        },
                        AvailableTags = {
                            type = "description",
                            order = 31,
                            name = function() return tags() end
                        },
                    },
                },
                TagsOptions = {
                    type = "group",
                    order = 20,
                    name = "Tags options",
                    args = {
                        Bar = {
                            type = "group",
                            order = 10,
                            name = "[bar]",
                            desc = "options for [bar] and [c_bar] TAGs",
                            args = {
                                BarCharacter = {
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
                                Blank1 = { type = "description", order = 1.1, fontSize = "small",name = "",width = "full", },
                                BarLength = {
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
                            },
                        },
                        BarTexture = {
                            type = "group",
                            order = 20,
                            name = "[barTexture]",
                            desc = "options for [barTexture] and [c_barTexture] TAGs",
                            args = {
                                BarTexture = {
                                    type = "select",
                                    order = 1,
                                    name = "texture",
                                    dialogControl = "LSM30_Statusbar",
                                    values = AceGUIWidgetLSMlists.statusbar,
                                    get = function() return Addon.db.profile.Reputation.barSolidTexture end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.barSolidTexture = value
                                    end,
                                },
                                Blank1 = { type = "description", order = 1.1, fontSize = "small",name = "",width = "full", },
                                BarWidth = {
                                    type = "range",
                                    order = 2,
                                    name = "width",
                                    desc = "width of progress bar",
                                    min = 1,
                                    max = 200,
                                    softMin = 5,
                                    softMax = 100,
                                    step = 1,
                                    bigStep = 5,
                                    get = function(info) return Addon.db.profile.Reputation.barSolidWidth end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.barSolidWidth = value
                                    end
                                },
                                Blank2 = { type = "description", order = 2.1, fontSize = "small",name = "",width = "full", },
                                BarHeight = {
                                    type = "range",
                                    order = 3,
                                    name = "height",
                                    desc = "height of progress bar",
                                    min = 1,
                                    max = 50,
                                    softMin = 5,
                                    softMax = 20,
                                    step = 1,
                                    bigStep = 1,
                                    get = function(info) return Addon.db.profile.Reputation.barSolidHeight end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.barSolidHeight = value
                                    end
                                },
                                Blank3 = { type = "description", order = 3.1, fontSize = "small",name = "",width = "full", },
                                BarOffset = {
                                    type = "range",
                                    order = 4,
                                    name = "offset",
                                    desc = "vertical offset of progress bar from bottom text line",
                                    min = -20,
                                    max = 20,
                                    softMin = -10,
                                    softMax = 10,
                                    step = 1,
                                    bigStep = 1,
                                    get = function(info) return Addon.db.profile.Reputation.barSolidOffset end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.barSolidOffset = value
                                    end
                                },
                            },
                        },
                        StandigText = {
                            type = "group",
                            order = 30,
                            name = "[standingText]",
                            desc = "options for [standingText] and [c_standingText] TAGs",
                            args = {
                                ParagonCount = {
                                    type = "toggle",
                                    order = 1,
                                    name = "show paragon count in standing text",
                                    width = "full",
                                    get = function(info) return Addon.db.profile.Reputation.showParagonCount end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.showParagonCount = value
                                    end
                                },
                            },
                        },
                        Icon = {
                            type = "group",
                            order = 40,
                            name = "[icon]",
                            desc = "options for [icon] TAG",
                            args = {
                                Height = {
                                    type = "range",
                                    order = 1,
                                    name = "icon size (0=text height)",
                                    desc = "sets height of icon, 0 for text height",
                                    min = 0,
                                    max = 64,
                                    softMin = 0,
                                    softMax = 32,
                                    step = 1,
                                    bigStep = 1,
                                    get = function(info) return Addon.db.profile.Reputation.iconHeight end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.iconHeight = value
                                    end
                                },
                                Blank1 = { type = "description", order = 1.1, fontSize = "small",name = "",width = "full", },
                                Style = {
                                    type = "select",
                                    order = 2,
                                    name = "style",
                                    desc = "style of icon",
                                    values = {
                                        ["default"] = "Blizzard",
                                        ["clean"] = "Clean (no borders)",
                                    },
                                    get = function(info) return Addon.db.profile.Reputation.iconStyle end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.iconStyle = value
                                    end
                                }
                            },
                        },
                        ShortTag = {
                            type = "group",
                            order = 50,
                            name = "[...Short]",
                            desc = "options for TAGs ending with 'Short'",
                            args = {
                                ShortTagChars = {
                                    type = "range",
                                    order = 1,
                                    name = "number of characters for 'Short' TAGs",
                                    width = 1.2,
                                    min = 1,
                                    max = 100,
                                    softMin = 1,
                                    softMax = 10,
                                    step = 1,
                                    bigStep = 1,
                                    get = function(info) return Addon.db.profile.Reputation.shortCharCount end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.shortCharCount = value
                                    end
                                },
                            },
                        },
                    },
                },
                Output = {
                    type = "group",
                    order = 30,
                    name = "Output",
                    args = {
                        SinkChat = {
                            type = "toggle",
                            order = 20,
                            name = "Also display message in following chat frames",
                            desc = ". If you want to display the message only in first chat frame, you can select 'Chat' option above. If you only need to display in chat but not in first chat frame, choose 'None' option above and below select in which frames you would like to see the message.",
                            width = "full",
                            disabled = function() return (Addon.db.profile.sink20OutputSink == "ChatFrame") end,
                            get = function(info) return Addon.db.profile.sinkChat end,
                            set = function(info, value)
                                Addon.db.profile.sinkChat = value
                            end
                        },
                    },
                },
                Bars = {
                    type = "group",
                    order = 40,
                    name = "Reputation bars",
                    args = {
                        Enabled = {
                            type = "toggle",
                            order = 10,
                            name = "Enable",
                            get = function(info) return Addon.db.profile.Bars.enabled end,
                            set = function(info, value)
                                Addon.db.profile.Bars.enabled = value
                                SetBarsOptions()
                            end,
                        },
                        Locked = {
                            type = "toggle",
                            order = 20,
                            name = "Lock position",
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.locked end,
                            set = function(info, value)
                                Addon.db.profile.Bars.locked = value
                                SetBarsOptions()
                            end,
                        },
                        Icon = {
                            type = "toggle",
                            order = 30,
                            name = "Show faction icons",
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.icon end,
                            set = function(info, value)
                                Addon.db.profile.Bars.icon = value
                                SetBarsOptions()
                            end,
                        },
                        Texture = {
                            type = "select",
                            dialogControl = "LSM30_Statusbar",
                            order = 110,
                            name = "Texture",
                            values = AceGUIWidgetLSMlists.statusbar,
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.texture end,
                            set = function(info, value)
                                Addon.db.profile.Bars.texture = value
                                SetBarsOptions()
                            end,
                        },
                        Width = {
                            type = "range",
                            order = 120,
                            name = "Width",
                            min = 20,
                            max = 2000,
                            softMin = 50,
                            softMax = 500,
                            step = 1,
                            bigStep = 10,
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.width end,
                            set = function(info, value)
                                Addon.db.profile.Bars.width = value
                                SetBarsOptions()
                            end,
                        },
                        Height = {
                            type = "range",
                            order = 130,
                            name = "Height",
                            min = 2,
                            max = 64,
                            softMin = 5,
                            softMax = 32,
                            step = 1,
                            bigStep = 1,
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.height end,
                            set = function(info, value)
                                Addon.db.profile.Bars.height = value
                                SetBarsOptions()
                            end,
                        },
                        Font = {
                            type = "select",
                            dialogControl = "LSM30_Font",
                            order = 210,
                            name = "Font",
                            values = AceGUIWidgetLSMlists.font,
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.font end,
                            set = function(info, value)
                                Addon.db.profile.Bars.font = value
                                SetBarsOptions()
                            end,
                        },
                        FontSize = {
                            type = "range",
                            order = 220,
                            name = "Font size",
                            min = 5,
                            max = 64,
                            softMin = 5,
                            softMax = 32,
                            step = 1,
                            bigStep = 1,
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.fontSize end,
                            set = function(info, value)
                                Addon.db.profile.Bars.fontSize = value
                                SetBarsOptions()
                            end,
                        },
                        FontOutline = {
                            type = "select",
                            order = 230,
                            name = "Font outline",
                            values = {
                                [""] = "None",
                                ["OUTLINE"] = "Normal",
                                ["THICKOUTLINE"] = "Thick",
                            },
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.fontOutline end,
                            set = function(info, value)
                                Addon.db.profile.Bars.fontOutline = value
                                SetBarsOptions()
                            end,
                        },
                        Alpha = {
                            type = "range",
                            order = 310,
                            name = "Opacity",
                            min = 0,
                            max = 1,
                            step = 0.01,
                            isPercent = true,
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.alpha end,
                            set = function(info, value)
                                Addon.db.profile.Bars.alpha = value
                                SetBarsOptions()
                            end,
                        },
                        Sort = {
                            type = "select",
                            order = 320,
                            name = "Sort bars by",
                            values = {
                                ["faction"] = "Faction name",
                                ["session"] = "Session gain/loss",
                                ["overall"] = "Overall reputation value",
                                ["recent"] = "Time of last change",
                            },
                            style = "dropdown",
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.sort end,
                            set = function(info, value)
                                Addon.db.profile.Bars.sort = value
                                SetBarsOptions()
                            end,
                        },
                        GrowUp = {
                            type = "toggle",
                            order = 330,
                            name = "Grows upward",
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.growUp end,
                            set = function(info, value)
                                Addon.db.profile.Bars.growUp = value
                                SetBarsOptions()
                            end,
                        },
                    }
                },
                Colors = {
                    type = "group",
                    order = 50,
                    name = "Colors",
                    args = {
                        ReputationColors = {
                            type = "group",
                            order = 21,
                            name = "Reputation standing colors",
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
                                        SetBarsOptions()
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
                                        SetBarsOptions()
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
                                        SetBarsOptions()
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
                                        SetBarsOptions()
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
                                        SetBarsOptions()
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
                                        SetBarsOptions()
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
                                        SetBarsOptions()
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
                                        SetBarsOptions()
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
                                        SetBarsOptions()
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
                                        SetBarsOptions()
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
                                SetBarsOptions()
                            end,
                        },
                    }
                },
                TestDesc = {
                    type = "description",
                    order = 910,
                    name = "Test: ",
                    width = 0.25,
                },
                TestFacion = {
                    type = "select",
                    order = 920,
                    name = "faction",
                    width = 1.2,
                    values = function() return getFactions() end,
                    get = function(info) return Addon.db.profile.Test.faction end,
                    set = function(info, value)
                        Addon.db.profile.Test.faction = value
                    end,
                },
                TestChange = {
                    type = 'input',
                    order = 930,
                    name = 'gain',
                    desc = 'positive number for gain, negative for loss',
                    width = 0.75,
                    pattern = '^[-]?%d+$',
                    usage = "<number>",
                    get = function(info) return tostring(Addon.db.profile.Test.change) end,
                    set = function(info, value)
                        Addon.db.profile.Test.change = tonumber(value)
                    end,
                },
                Test = {
                    type = 'execute',
                    order = 940,
                    name = 'TEST',
                    width = "half",
                    func = function() Addon:Test() end,
                },
            },
        },
        About = {
            type = "group",
            order = 90,
            name = "About",
              args = {
                generalText1 = {
                  type = "description",
                  order = 10,
                  fontSize = "medium",
                  name = "Pretty reputation is addon that displays reputation gains or losses in chat.\nMessage is completely configurable by user by using predefined and user added TAGS.\n",
                  width = "full"
                },
                blank1 = { type = "description", order = 20, fontSize = "small",name = "",width = "full", },
                cmdHeader = {
                    order = 30,
                    type = "header",
                    name = "Chat commands"
                },
                generalText2 = {
                  type = "description",
                  order = 40,
                  fontSize = "medium",
                  name = "You can use /pr in chat to get list of commands."
                },
                blank2 = { type = "description", order = 50, fontSize = "small",name = "",width = "full", },
                helpHeader = {
                    order = 60,
                    type = "header",
                    name = "Feedback"
                },
                generalText3 = {
                  type = "description",
                  order = 70,
                  fontSize = "medium",
                  name = "Need help?  Have a feature request?  Open an issue on the code repository for Pretty Reputation."
                },
                blank3 = { type = "description", order = 80, fontSize = "medium", name = "", width = "full", },
                generalText4 = {
                    type = "description",
                    order = 90,
                    fontSize = "medium",
                    name = "Issue Tracker:",
                    width = "half",
                },
                generalText5 = {
                    type = "description",
                    order = 100,
                    fontSize = "medium",
                    name = "github.com/BelegCufea/PrettyReputation",
                    width = "double",
                },
                seperator1 = { type = "header", order = 900, name = "Supported addons", },
                generalText6 = {
                    type = "description",
                    order = 910,
                    fontSize = "medium",
                    name = "Faction Addict:",
                    width = "half",
                },
                generalText7 = {
                    type = "description",
                    order = 920,
                    fontSize = "medium",
                    name = "curseforge.com/wow/addons/faction-addict",
                    width = "double",
                },
            },
        },
	},
}

function Config:OnEnable()
    options.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(Addon.db)
    options.args.Profiles.order = 80
    options.args.Settings.args.Output.args.Sink = Addon:GetSinkAce3OptionsDataTable()
    options.args.Settings.args.Output.args.Sink.order = 10
    options.args.Settings.args.Output.args.Sink.inline = true
    options.args.Settings.args.Output.args.ChatFrames = getChatFrames()
    options.args.Settings.args.Output.args.ChatFrames.order = 30
    options.args.Settings.args.Output.args.ChatFrames.inline = true
    Addon:SetSinkStorage(Addon.db.profile)
	ConfigRegistry:RegisterOptionsTable(Addon.CONST.METADATA.NAME, options)
    ConfigDialog:AddToBlizOptions(Addon.CONST.METADATA.NAME, nil, nil, "Settings")
    ConfigDialog:AddToBlizOptions(Addon.CONST.METADATA.NAME, "Profiles", Addon.CONST.METADATA.NAME, "Profiles")
    ConfigDialog:AddToBlizOptions(Addon.CONST.METADATA.NAME, "About", Addon.CONST.METADATA.NAME, "About")
    if Addon.Bars then
        Addon.Bars:SetOptions()
    end
end