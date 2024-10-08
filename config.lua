local Addon = select(2, ...)

local Config = Addon:NewModule("Config")
Addon.Config = Config
local ConfigRegistry = LibStub("AceConfigRegistry-3.0")
local ConfigDialog = LibStub("AceConfigDialog-3.0")

local factions = Addon.Factions
local Debug = Addon.DEBUG
local Const = Addon.CONST

local searchQuery = ""

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

local function conditionalTags()
    local result = ""
    result = result .. "This functionality allows adding conditional prefixes and/or suffixes to any text TAG (except for graphics ones like bar, icon etc.)" .. "\n"
    result = result .. "\n"
    result = result .. "Format is: |cnGOLD_FONT_COLOR:[{prefix}TAG{suffix}]|r, where both {prefix} and {suffix} are optional." .. "\n"
    result = result .. "If [TAG] would return empty value, the output of [{prefix}TAG{suffix}] is also empty (ie. nothing will be displayed) " .. "\n"
    result = result .. "No spaces are alowed except inside {} brackets as part of prefix or suffix text." .. "\n"
    result = result .. "\n"
    result = result .. "For example, |cnGOLD_FONT_COLOR:[{Level }paragonLevel{ paragon}]|r will display |cnGOLD_FONT_COLOR:Level 5 paragon|r if the Paragon level is 5, and nothing will be displayed if the faction does not have a Paragon level or has not reached it yet." .. "\n"
    return result
end

local function faq()
    local FAQ = Addon.FAQ
    if not FAQ then return end
    local result = {
        type = "group",
        order = 70,
        name = FAQ.Header,
        args = {},
    }
    for k,v in pairs(FAQ.Points) do
        local order = k:match("^(%d+)%.")
        local header = k:match("%d+%.%s*(.+)")
        local description = v:gsub(" '", " |cnNORMAL_FONT_COLOR:")
        description = description:gsub("'", "|r")
        result.args["header" .. order] = {
            type = "header",
            order = order * 10,
            name = header,
        }
        result.args["description" .. order] = {
            type = "description",
            order = order * 10 + 1,
            name = description,
            fontSize = "medium",
        }
        result.args["blank" .. order] = { type = "description", order = order * 10 + 2, fontSize = "large",name = " ",width = "full", }
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
    Debug:Table("colors", REP_COLORS)
    if value == "blizzard" then Addon.db.profile.Colors = REP_COLORS.blizzardColors end
    if value == "ascii" then Addon.db.profile.Colors = REP_COLORS.asciiColors end
    if value == "wowpro" then Addon.db.profile.Colors = REP_COLORS.wowproColors end
    if value == "tiptac" then Addon.db.profile.Colors = REP_COLORS.tiptacColors end
    if value == "elvui" then Addon.db.profile.Colors = REP_COLORS.elvuiColors end
    Addon.db.profile.ColorsPreset = value

    local colorIndexLow     = Const.REP_COLOR_INDEX_LOW
    local colorIndexHigh    = Const.REP_COLOR_INDEX_HIGH
    local colorIndexParagon = Const.REP_COLOR_INDEX_PARAGON
    Addon.db.profile.ColorRenownLow  = Addon.db.profile.Colors[colorIndexLow]     or Const.REP_COLORS.wowproColors[colorIndexLow]
    Addon.db.profile.ColorRenownHigh = Addon.db.profile.Colors[colorIndexHigh]    or Const.REP_COLORS.wowproColors[colorIndexHigh]
    Addon.db.profile.ColorFriendLow  = Addon.db.profile.Colors[colorIndexLow]     or Const.REP_COLORS.wowproColors[colorIndexLow]
    Addon.db.profile.ColorFriendHigh = Addon.db.profile.Colors[colorIndexHigh]    or Const.REP_COLORS.wowproColors[colorIndexHigh]
    Addon.db.profile.ColorParagon    = Addon.db.profile.Colors[colorIndexParagon] or Const.REP_COLORS.wowproColors[colorIndexParagon]
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

local function getFactions(type)
    local list = {}

    local found

    for k,v in pairs(factions) do
        if not found then found = k end
        if k == Addon.db.profile.Test.faction then found = k end
        if type == "all" or searchQuery == "" or string.find(string.lower(k), string.lower(searchQuery)) then
            if v and v.blizzFix then
                if type == "all" or type == "blizzFix" then
                    list[k] = "|cffff0000"..k.."|r"
                end
            elseif type == "all" or type == "standard" then
                list[k] = k
            end
        end
    end

    if type == "all" and not list["Darkmoon Faire"] then
        list["Darkmoon Faire"] = "Darkmoon Faire"
    end
    Addon.db.profile.Test.faction = found
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
                                Addon:OnToggle()
                            end
                        },
                        MiniMap = {
                            type = "toggle",
                            order = 2,
                            name = "Show minimap icon",
                            width = "full",
                            get = function(info) return not Addon.db.profile.minimapIcon.hide end,
                            set = function(info, value)
                                Addon.db.profile.minimapIcon.hide = not value
                                if Addon.db.profile.minimapIcon.hide then
                                    Addon.icon:Hide(Addon.CONST.METADATA.NAME)
                                else
                                    Addon.icon:Show(Addon.CONST.METADATA.NAME)
                                end
                             end
                        },
                        Compartment = {
                            type = "toggle",
                            order = 2.1,
                            name = "Show addon compartment button",
                            width = "full",
                            get = function(info) return not Addon.db.profile.AddonCompartment.hide end,
                            set = function(info, value)
                                Addon.db.profile.AddonCompartment.hide = not value
                                if Addon.db.profile.AddonCompartment.hide then
                                    if Addon.icon:IsButtonInCompartment(Addon.CONST.METADATA.NAME) then
                                        Addon.icon:RemoveButtonFromCompartment(Addon.CONST.METADATA.NAME)
                                    end
                                else
                                    if not Addon.icon:IsButtonInCompartment(Addon.CONST.METADATA.NAME) then
                                        Addon.icon:AddButtonToCompartment(Addon.CONST.METADATA.NAME)
                                    end
                                end
                             end
                        },
                       Splash = {
                            type = "toggle",
                            order = 3,
                            name = "Show splash reputation (|cnWARNING_FONT_COLOR:May cause lag!|r)",
                            desc = "Sometimes you can receive reputation changes with factions that are not announced by Blizzard. The addon has an option to display these changes as well, but be aware that this feature may slow down the system even if addon is not enabled on General panel and it's not recommended unless you really need it. It won't catch the first reputation change for a newly discovered 'splased' factions.",
                            width = "full",
                            get = function(info) return Addon.db.profile.Splash end,
                            set = function(info, value)
                                Addon.db.profile.Splash = value
                            end
                        },
                        Track = {
                            type = "group",
                            order = 4,
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
                            order = 5,
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
                        Seperator1 = { type = "description", order = 6, fontSize = "small",name = "",width = "full", },
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
                        ConditionalTagsHeader = {
                            type = "header",
                            order = 40,
                            name = "Conditional prefixes and suffixes for tags"
                        },
                        ConditionalTags = {
                            type = "description",
                            order = 41,
                            name = function() return conditionalTags() end
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
                            name = "[standing]",
                            desc = "options for [standing] and [standingNext] TAGs",
                            args = {
                                ParagonCount = {
                                    type = "toggle",
                                    order = 1,
                                    name = "show paragon level instead of standing text",
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
                        SignText = {
                            type = "group",
                            order = 50,
                            name = "[signText]",
                            desc = "options for [signtext] TAG",
                            args = {
                                Positive = {
                                    type = "input",
                                    order = 1,
                                    name = "text for reputation gain",
                                    width = "full",
                                    get = function(info) return Addon.db.profile.Reputation.signTextPositive end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.signTextPositive = value
                                    end
                                },
                                Negative = {
                                    type = "input",
                                    order = 1,
                                    name = "text for reputation loss",
                                    width = "full",
                                    get = function(info) return Addon.db.profile.Reputation.signTextNegative end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.signTextNegative = value
                                    end
                                },
                            },
                        },
                        ShortTag = {
                            type = "group",
                            order = 60,
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
                        Paragon = {
                            type = "group",
                            order = 70,
                            name = "[c_...]",
                            desc = "options for TAGs starting with 'c_'",
                            args = {
                                ParagonCount = {
                                    type = "toggle",
                                    order = 1,
                                    name = "paragon standing color overrides renown",
                                    width = "full",
                                    get = function(info) return Addon.db.profile.Reputation.paragonColorOverride end,
                                    set = function(info, value)
                                        Addon.db.profile.Reputation.paragonColorOverride = value
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
                        PatternOverride = {
                            type = "toggle",
                            order = 50,
                            name = "Override pattern for chat frames",
                            width = "full",
                            disabled = function() return (Addon.db.profile.sink20OutputSink == "ChatFrame") or (not Addon.db.profile.sinkChat) end,
                            get = function(info) return Addon.db.profile.Reputation.patternChatFrameOverride end,
                            set = function(info, value)
                                Addon.db.profile.Reputation.patternChatFrameOverride = value
                            end
                        },
                        Pattern = {
                            type = "input",
                            order = 60,
                            name = "pattern",
                            desc = "Construct your reputation message",
                            width = "full",
                            multiline =true,
                            hidden = function() return not Addon.db.profile.Reputation.patternChatFrameOverride end,
                            disabled = function() return (not Addon.db.profile.Reputation.patternChatFrameOverride) or (Addon.db.profile.sink20OutputSink == "ChatFrame") or (not Addon.db.profile.sinkChat) end,
                            get = function(info) return Addon.db.profile.Reputation.patternChatFrame end,
                            set = function(info, value)
                                Addon.db.profile.Reputation.patternChatFrame = value
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
                            name = "Enabled",
                            width = "full",
                            get = function(info) return Addon.db.profile.Bars.enabled end,
                            set = function(info, value)
                                Addon.db.profile.Bars.enabled = value
                                SetBarsOptions()
                            end,
                        },
                        Locked = {
                            type = "toggle",
                            order = 110,
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
                            order = 120,
                            name = "Show faction icons",
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.icon end,
                            set = function(info, value)
                                Addon.db.profile.Bars.icon = value
                                SetBarsOptions()
                            end,
                        },
                        GrowUp = {
                            type = "toggle",
                            order = 130,
                            name = "Grows upward",
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.growUp end,
                            set = function(info, value)
                                Addon.db.profile.Bars.growUp = value
                                SetBarsOptions()
                            end,
                        },
                        Texture = {
                            type = "select",
                            dialogControl = "LSM30_Statusbar",
                            order = 210,
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
                            order = 220,
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
                            order = 230,
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
                            order = 310,
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
                            order = 320,
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
                            order = 330,
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
                            order = 410,
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
                            order = 420,
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
                        TooltipAnchor = {
                            type = "select",
                            order = 430,
                            name = "Anchor tooltip to",
                            values = {
                                ["ANCHOR_TOP"] = "Top",
                                ["ANCHOR_BOTTOM"] = "Bottom",
                                ["RIGHT"] = "Right",
                                ["LEFT"] = "Left",
                                ["ANCHOR_CURSOR"] = "Cursor",
                            },
                            style = "dropdown",
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.tooltipAnchor end,
                            set = function(info, value)
                                Addon.db.profile.Bars.tooltipAnchor = value
                            end,
                        },
                        RemoveAfter = {
                            type = "range",
                            order = 510,
                            name = "Time (s)",
                            desc = "For how many seconds without reputation change will the faction bar be visible. 0=never hide.",
                            min = 0,
                            max = 900,
                            softMin = 0,
                            softMax = 300,
                            step = 1,
                            bigStep = 5,
                            disabled = function() return not Addon.db.profile.Bars.enabled end,
                            get = function(info) return Addon.db.profile.Bars.removeAfter end,
                            set = function(info, value)
                                Addon.db.profile.Bars.removeAfter = value
                            end,
                        },
                        blank1 = { type = "description", order = 600, fontSize = "small",name = "",width = "full", },
                        PatternLeft = {
                            type = "input",
                            order = 610,
                            name = "pattern for left text",
                            width = "full",
                            get = function(info) return Addon.db.profile.Bars.patternLeft end,
                            set = function(info, value)
                                Addon.db.profile.Bars.patternLeft = value
                                SetBarsOptions()
                            end
                        },
                        PatternRight = {
                            type = "input",
                            order = 620,
                            name = "pattern for right text",
                            width = "full",
                            get = function(info) return Addon.db.profile.Bars.patternRight end,
                            set = function(info, value)
                                Addon.db.profile.Bars.patternRight = value
                                SetBarsOptions()
                            end
                        },
                        ParagonOverride = {
                            type = "toggle",
                            order = 630,
                            name = "paragon standing color overrides renown",
                            width = "full",
                            get = function(info) return Addon.db.profile.Bars.paragonColorOverride end,
                            set = function(info, value)
                                Addon.db.profile.Bars.paragonColorOverride = value
                                SetBarsOptions()
                            end
                        },
                    },
                },
                Colors = {
                    type = "group",
                    order = 50,
                    name = "Colors",
                    args = {
                        ReputationColors = {
                            type = "group",
                            order = 10,
                            name = "Reputation standing colors",
                            inline = true,
                            args = {
                                Hated = {
                                    type = "color",
                                    order = 1,
                                    name = Addon.CONST.REP_STANDING[1],
                                    get = function(info)
                                        local color = Addon.db.profile.Colors[1]
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.Colors[1]
                                        color.r, color.g, color.b = r, g, b
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
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.Colors[2]
                                        color.r, color.g, color.b = r, g, b
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
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.Colors[3]
                                        color.r, color.g, color.b = r, g, b
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
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.Colors[4]
                                        color.r, color.g, color.b = r, g, b
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
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.Colors[5]
                                        color.r, color.g, color.b = r, g, b
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
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.Colors[6]
                                        color.r, color.g, color.b = r, g, b
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
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.Colors[7]
                                        color.r, color.g, color.b = r, g, b
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
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.Colors[8]
                                        color.r, color.g, color.b = r, g, b
                                        Addon.db.profile.ColorsPreset = "custom"
                                        SetBarsOptions()
                                    end
                                },
                            }
                        },
                        RenownColors = {
                            type = "group",
                            name = "Renown faction colors",
                            order = 20,
                            inline = true,
                            args = {
                                ColorLow = {
                                    type = "color",
                                    order = 10,
                                    name = "From",
                                    get = function(info)
                                        local color = Addon.db.profile.ColorRenownLow
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.ColorRenownLow
                                        color.r, color.g, color.b = r, g, b
                                        Addon.db.profile.ColorsPreset = "custom"
                                        SetBarsOptions()
                                    end
                                },
                                ColorHigh = {
                                    type = "color",
                                    order = 20,
                                    name = "To",
                                    get = function(info)
                                        local color = Addon.db.profile.ColorRenownHigh
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.ColorRenownHigh
                                        color.r, color.g, color.b = r, g, b
                                        Addon.db.profile.ColorsPreset = "custom"
                                        SetBarsOptions()
                                    end
                                },
                                ColorParagon = {
                                    type = "color",
                                    order = 30,
                                    name = "Paragon",
                                    get = function(info)
                                        local color = Addon.db.profile.ColorParagon
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.ColorParagon
                                        color.r, color.g, color.b = r, g, b
                                        Addon.db.profile.ColorsPreset = "custom"
                                        SetBarsOptions()
                                    end
                                },
                            },
                        },
                        FriendColors = {
                            type = "group",
                            name = "Friendship faction colors",
                            order = 30,
                            inline = true,
                            args = {
                                ColorLow = {
                                    type = "color",
                                    order = 10,
                                    name = "From",
                                    get = function(info)
                                        local color = Addon.db.profile.ColorFriendLow
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.ColorFriendLow
                                        color.r, color.g, color.b = r, g, b
                                        Addon.db.profile.ColorsPreset = "custom"
                                        SetBarsOptions()
                                    end
                                },
                                ColorHigh = {
                                    type = "color",
                                    order = 20,
                                    name = "To",
                                    get = function(info)
                                        local color = Addon.db.profile.ColorFriendHigh
                                        return color.r, color.g, color.b
                                    end,
                                    set = function(info, r, g, b, a)
                                        local color = Addon.db.profile.ColorFriendHigh
                                        color.r, color.g, color.b = r, g, b
                                        Addon.db.profile.ColorsPreset = "custom"
                                        SetBarsOptions()
                                    end
                                },
                            },
                        },
                        ReputationColorsPresets = {
                            type = "select",
                            order = 90,
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
                    values = function() return getFactions("all") end,
                    get = function(info) return Addon.db.profile.Test.faction end,
                    set = function(info, value)
                        Addon.db.profile.Test.faction = value
                    end,
                },
                TestChange = {
                    type = 'input',
                    order = 930,
                    name = 'change',
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
                    disabled = function() return not Addon.db.profile.Enabled end,
                    func = function() Addon:Test() end,
                },
            },
        },
        Favorites = {
            type = "group",
            order = 70,
            name = "Favorites",
              args = {
                description = {
                    type = "description",
                    name = "Choose favorite factions",
                    order = 10,
                },
                search = {
                    type = "input",
                    name = "Search",
                    desc = "Type to filter the factions list.",
                    get = function() return searchQuery end,
                    set = function(_, value)
                        searchQuery = value
                    end,
                    order = 20,
                },
                list1 = {
                    type = "multiselect",
                    name = "Visible Factions",
                    values = function() return getFactions("standard") end,
                    get = function(info, key)
                        return Addon.db.profile.FavoriteFactions[key] or false
                    end,
                    set = function(info, key, value)
                        Addon.db.profile.FavoriteFactions[key] = value
                        SetBarsOptions()
                    end,
                    order = 30,
                },
                list2 = {
                    type = "multiselect",
                    name = "Hiden Factions",
                    values = function() return getFactions("blizzFix") end,
                    get = function(info, key)
                        return Addon.db.profile.FavoriteFactions[key] or false
                    end,
                    set = function(info, key, value)
                        Addon.db.profile.FavoriteFactions[key] = value
                        SetBarsOptions()
                    end,
                    order = 40,
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
    options.args.FAQ = faq()
    Addon:SetSinkStorage(Addon.db.profile)
	ConfigRegistry:RegisterOptionsTable(Addon.CONST.METADATA.NAME, options)
    _, Config.categoryID = ConfigDialog:AddToBlizOptions(Addon.CONST.METADATA.NAME, nil, nil, "Settings")
    ConfigDialog:AddToBlizOptions(Addon.CONST.METADATA.NAME, "Favorites", Addon.CONST.METADATA.NAME, "Favorites")
    ConfigDialog:AddToBlizOptions(Addon.CONST.METADATA.NAME, "Profiles", Addon.CONST.METADATA.NAME, "Profiles")
    ConfigDialog:AddToBlizOptions(Addon.CONST.METADATA.NAME, "About", Addon.CONST.METADATA.NAME, "About")
    if options.args.FAQ then
        ConfigDialog:AddToBlizOptions(Addon.CONST.METADATA.NAME, Addon.FAQ.Header, Addon.CONST.METADATA.NAME, "FAQ")
    end
    if Addon.Bars then
        Addon.Bars:SetOptions()
    end
end