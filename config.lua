local Addon = select(2, ...)

local Config = Addon:NewModule("Config")
Addon.Config = Config

local AddonTitle = GetAddOnMetadata(..., "Title")

local COLORS = {
    TAG = "|cffd4756a"
}

local TAGS = {
    {"name", "Name of the faction"},
    {"standing", "Current reputation standing"},
    {"c_standing", "Colored current reputation standing"},
    {"change", "Actual gain/loss of reputation"},
    {"c_change", "Actual gain/loss of reputation (green for gain, red for loss)"},
    {"session", "Gain of reputation in current session"},
    {"c_session", "Gain of reputation in current session (green for gain, red for loss)"},
    {"current", "Current reputation value"},
    {"next", "Reputation boundary for next level"},
    {"bottom", "Minimun reputation in current standing"},
    {"top", "Maximum reputation in current standing"},
    {"toGo", "Reputation to gain/loss for next/previous standing"},
    {"changePercent", "Percentual change of reputation"},
    {"currentPercent", "Percent of next standing"},
    {"bar", "Shows barlike progress representation of current standing"}
}

local function tags()
    local result = ""
    for i,v in pairs(TAGS) do
       result = result .. COLORS.TAG .. "[" .. v[1] .. "]|r - " .. v[2] .. "\n"
    end
    return result
end

local options = {
	name = AddonTitle,
	type = "group",
	args = {
        MessageHeader = {
            type = "header",
            order = 10,
            name = "Message"
        },
        MessageBody = {
            type = "input",
            order = 11, 
            name = "pattern",
            desc = "Construct your reputation message",
            width = "full",
            get = function(info) return Addon.db.profile.Reputation.pattern end,
            set = function(info, value)
                Addon.db.profile.Reputation.pattern = value
            end
        },
        MessageBarCharacter = {
            type = "input",
            order = 12,
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
            order = 13,
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
        MessageParagonCount = {
            type = "toggle",
            order = 14,
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
            order = 20,
            name = "Available tags"
        },
        AvailableTags = {
            type = "description",
            order = 21,
            name = tags()
        }, 
        DefaultHeader = {
            type = "header",
            order = 30,
            name = "Default message pattern"
        },
        DefaultMessage = {
            type = "description",
            order = 31,
            name = "[name] ([c_standing]): [c_change]/[c_session] ([currentPercent]) [bar]"
        }
	},
}

function Config:OnEnable()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(AddonTitle, options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonTitle)
end