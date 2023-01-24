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
    {"current", "Current reputation value"},
    {"next", "Reputation boundary for next level"},
    {"bottom", "Minimun reputation in current standing"},
    {"top", "Maximum reputation in current standing"},
    {"toGo", "Reputation to gain/loss for next/previous standing"},
    {"changePercent", "Percentual change of reputation"},
    {"currentPercent", "Percent of next standing"},
    {"bar", "Shows barlike representation of current standing"}
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
            get = function(info) return Addon.db.profile.message end,
            set = function(info, value)
                Addon.db.profile.message = value
            end,
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
            name = "[name] ([c_standing]): [c_change] ([currentPercent]) [bar]"
        }
	},
}

function Config:OnEnable()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(AddonTitle, options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddonTitle)
end