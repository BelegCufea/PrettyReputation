local Addon = select(2, ...)
Addon.TAGS = LibStub:NewLibrary("PrettyReputationTags", 1)

Addon.TAGS.Options = {
    Reputation = {
        barChar = function() return Addon.db.profile.Reputation.barChar end,
        barLength = function() return Addon.db.profile.Reputation.barLength end,
        showParagonCount = function() return Addon.db.profile.Reputation.showParagonCount end,
        shortCharCount = function() return Addon.db.profile.Reputation.shortCharCount end,
    },
    Colors = function()
        return Addon.db.profile.Colors
    end,
    StandingColors = function()
        local standingColors = {}
        for k,v in pairs(Addon.db.profile.Colors) do
            standingColors[k] = ("|cff%.2x%.2x%.2x"):format(v.r*255, v.g*255, v.b*255)
        end
        return standingColors
    end,
}

Addon.TAGS.Const = {
    Colors = {
        name = Addon.CONST.MESSAGE_COLORS.NAME,
        bar_full = Addon.CONST.MESSAGE_COLORS.BAR_FULL,
        bar_empty = Addon.CONST.MESSAGE_COLORS.BAR_EMPTY,
        bar_edge = Addon.CONST.MESSAGE_COLORS.BAR_EDGE,
        positive = Addon.CONST.MESSAGE_COLORS.POSITIVE,
        negative = Addon.CONST.MESSAGE_COLORS.NEGATIVE,
    }
}

local function first_letters(sentence, x)
    local result = ""
    for word in string.gmatch(sentence, "%a+") do
        local first_letter = string.upper(string.sub(word, 1, 1))
        local rest_of_word = string.sub(word, 2, x)
        result = result .. first_letter .. rest_of_word
    end
    return result
end

Addon.TAGS.Definition = {
    ["name"] = {
        desc = "Name of the faction",
        value = function(info) return Addon.CONST.MESSAGE_COLORS.NAME .. info.name .. "|r" end
    },
    ["c_name"] = {
        desc = "Name of the faction colored by standing",
        value = function(info) return info.standingColor .. info.name .. "|r" end
    },
    ["standing"] = {
        desc = "Current reputation standing",
        value = function(info)
            if Addon.db.profile.Reputation.showParagonCount and info.paragon ~= "" then
                return info.standingText .. " (" .. info.paragon .. ")"
            else
                return info.standingText
            end
        end
    },
    ["standingShort"] = {
        desc = "A shortened expression of the current reputation standing, with a maximum of 'x' characters per word, can be set in the options (1 is the default value for x).",
        value = function(info)
            local standingTextShort = first_letters(info.standingText, Addon.db.profile.Reputation.shortCharCount) .. info.renown
            if (info.standingId == 10) and string.find(info.standingText, " ") then
                local level = string.sub(info.standingText, string.find(info.standingText, " ") + 1)
                standingTextShort = standingTextShort .. level
            end
            if Addon.db.profile.Reputation.showParagonCount and info.paragon ~= "" then
                return standingTextShort .. " (" .. info.paragon .. ")"
            else
                return standingTextShort
            end
        end
    },
    ["c_standing"] = {
        desc = "Colored current reputation standing",
        value = function(info)
            if Addon.db.profile.Reputation.showParagonCount and info.paragon ~= "" then
                local reputationColors = Addon.db.profile.Colors
                local paragonColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[9].r*255, reputationColors[9].g*255, reputationColors[9].b*255)
                return info.standingColor .. info.standingText .. "|r" .. paragonColor .. " (" .. info.paragon .. ")|r"
            else
                return info.standingColor .. info.standingText .. "|r"
            end
        end
    },
    ["c_standingShort"] = {
        desc = "A colored, shortened expression of the current reputation standing, with a maximum of 'x' characters per word, can be set in the options (1 is the default value for x).",
        value = function(info)
            local standingTextShort = first_letters(info.standingText, Addon.db.profile.Reputation.shortCharCount) .. info.renown
            if Addon.db.profile.Reputation.showParagonCount and info.paragon ~= "" then
                local reputationColors = Addon.db.profile.Colors
                local paragonColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[9].r*255, reputationColors[9].g*255, reputationColors[9].b*255)
                return info.standingColor .. standingTextShort .. "|r" .. paragonColor .. " (" .. info.paragon .. ")|r"
            else
                return info.standingColor .. standingTextShort .. "|r"
            end
        end
    },
    ["change"] = {
        desc = "Actual gain/loss of reputation",
        value = function(info) return (info.negative and "-" or "+") .. info.change end
    },
    ["c_change"] = {
        desc = "Actual gain/loss of reputation (green for gain, red for loss)",
        value = function(info) return (info.negative and Addon.CONST.MESSAGE_COLORS.NEGATIVE or Addon.CONST.MESSAGE_COLORS.POSITIVE) .. (info.negative and "-" or "+") .. info.change .. "|r" end
    },
    ["session"] = {
        desc = "Gain of reputation in current session",
        value = function(info) return ((info.session > 0) and "+" or "") .. info.session end
    },
    ["c_session"] = {
        desc = "Gain of reputation in current session (green for gain, red for loss)",
        value = function(info) return ((info.session > 0) and Addon.CONST.MESSAGE_COLORS.POSITIVE or Addon.CONST.MESSAGE_COLORS.NEGATIVE) .. ((info.session > 0) and "+" or "") .. info.session .. "|r" end
    },
    ["current"] = {
        desc = "Current reputation value",
        value = function(info) return info.current end
    },
    ["next"] = {
        desc = "Reputation boundary for next level",
        value = function(info) return info.maximum end
    },
    ["bottom"] = {
        desc = "Minimum reputation in current standing",
        value = function(info) return info.bottom end
    },
    ["top"] = {
        desc = "Maximum reputation in current standing",
        value = function(info) return info.top end
    },
    ["toGo"] = {
        desc = "Reputation to gain/loss for next/previous standing",
        value = function(info) return (info.negative and ("-" .. info.current) or (info.maximum - info.current)) end
    },
    ["changePercent"] = {
        desc = "Percentual change of reputation",
        value = function(info) return format("%.2f%%%%", (info.maximum == 0 and 0) or (info.change / info.maximum * 100)) end
    },
    ["sessionPercent"] = {
        desc = "Percentual change of reputation during active session",
        value = function(info) return format("%.1f%%%%", (info.maximum == 0 and 0) or (info.session / info.maximum * 100)) end
    },
    ["currentPercent"] = {
        desc = "Percent of next standing",
        value = function(info) return format("%.1f%%%%", (info.maximum == 0 and 0) or (info.current / info.maximum * 100)) end
    },
    ["paragonLevel"] = {
        desc = "Paragon level (with reward icon if available)",
        value = function(info) return info.paragon end
    },
    ["c_paragonLevel"] = {
        desc = "Colored paragon level (with reward icon if available)",
        value = function(info)
            local reputationColors = Addon.db.profile.Colors
            local paragonColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[9].r*255, reputationColors[9].g*255, reputationColors[9].b*255)
            return paragonColor .. info.paragon .. "|r"
        end
    },
    ["renownLevel"] = {
        desc = "Renown level",
        value = function(info) return info.renown end
    },
    ["c_renownLevel"] = {
        desc = "Colored renown level",
        value = function(info)
            local reputationColors = Addon.db.profile.Colors
            local renownColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[10].r*255, reputationColors[10].g*255, reputationColors[10].b*255)
            return renownColor .. info.renown .. "|r"
        end
    },
    ["bar"] = {
        desc = "Shows barlike progress representation of current standing",
        value = function(info)
            if info.maximum == 0 then return "" end
            local barChar = Addon.db.profile.Reputation.barChar
            local barLen = Addon.db.profile.Reputation.barLength
            local bar = string.rep(barChar, barLen)
            local percentBar = math.floor((info.current / info.maximum * 100) / (100 / barLen))
            local percentBarText =  Addon.CONST.MESSAGE_COLORS.BAR_FULL .. string.sub(bar, 0, percentBar * 2) .. "|r" .. Addon.CONST.MESSAGE_COLORS.BAR_EMPTY .. string.sub(bar, percentBar * 2 + 1) .. "|r"
            return Addon.CONST.MESSAGE_COLORS.BAR_EDGE .. "[|r" .. percentBarText .. Addon.CONST.MESSAGE_COLORS.BAR_EDGE .. "]|r"
        end
    },
    ["c_bar"] = {
        desc = "Shows barlike progress representation of current standing in standing color",
        value = function(info)
            if info.maximum == 0 then return "" end
            local barChar = Addon.db.profile.Reputation.barChar
            local barLen = Addon.db.profile.Reputation.barLength
            local bar = string.rep(barChar, barLen)
            local percentBar = math.floor((info.current / info.maximum * 100) / (100 / barLen))
            local percentBarText =  info.standingColor .. string.sub(bar, 0, percentBar * 2) .. "|r" .. Addon.CONST.MESSAGE_COLORS.BAR_EMPTY .. string.sub(bar, percentBar * 2 + 1) .. "|r"
            return Addon.CONST.MESSAGE_COLORS.BAR_EDGE .. "[|r" .. percentBarText .. Addon.CONST.MESSAGE_COLORS.BAR_EDGE .. "]|r"
        end
    },
    ["more"] = {
        desc = "How many of this gain/loss to reach next/prevois standing",
        value = function(info)
            if info.change then
                if info.negative then
                    return math.ceil(info.current/info.change)
                else
                    return math.ceil((info.maximum - info.current)/info.change)
                end
            end
            return ""
        end
    },
    ["icon"] = {
        desc = "Show faction icon if available (all, if Faction Addict is installed - see About)",
        value = function(info)
            if info.icon then
                return "|T" .. info.icon ..":0|t"
            end
            return ""
        end
    },
}
