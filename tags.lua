local Addon = select(2, ...)
Addon.TAGS = LibStub:NewLibrary("PrettyReputationTags", 1)

Addon.TAGS.Definition = {
    ["name"] = {
        tag = "Name of the faction",
        value = function(info) return Addon.CONST.MESSAGE_COLORS.NAME .. info.name .. "|r" end
    },
    ["c_name"] = {
        tag = "Name of the faction colored by standing",
        value = function(info) return info.standingColor .. info.name .. "|r" end
    },
    ["standing"] = {
        tag = "Current reputation standing",
        value = function(info)
            if Addon.db.profile.Reputation.showParagonCount and info.paragon ~= "" then
                return info.standingText .. " (" .. info.paragon .. ")"
            else 
                return info.standingText
            end
        end
    },
    ["c_standing"] = {
        tag = "Colored current reputation standing",
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
    ["change"] = {
        tag = "Actual gain/loss of reputation",
        value = function(info) return (info.negative and "-" or "+") .. info.change end
    },
    ["c_change"] = {
        tag = "Actual gain/loss of reputation (green for gain, red for loss)",
        value = function(info) return (info.negative and Addon.CONST.MESSAGE_COLORS.NEGATIVE or Addon.CONST.MESSAGE_COLORS.POSITIVE) .. (info.negative and "-" or "+") .. info.change .. "|r" end
    },
    ["session"] = {
        tag = "Gain of reputation in current session",
        value = function(info) return ((info.session > 0) and "+" or "") .. info.session end
    },
    ["c_session"] = {
        tag = "Gain of reputation in current session (green for gain, red for loss)",
        value = function(info) return ((info.session > 0) and Addon.CONST.MESSAGE_COLORS.POSITIVE or Addon.CONST.MESSAGE_COLORS.NEGATIVE) .. ((info.session > 0) and "+" or "") .. info.session .. "|r" end
    },
    ["current"] = {
        tag = "Current reputation value",
        value = function(info) return info.current end
    },
    ["next"] = {
        tag = "Reputation boundary for next level",
        value = function(info) return info.maximum end
    },
    ["bottom"] = {
        tag = "Minimum reputation in current standing",
        value = function(info) return info.bottom end
    },
    ["top"] = {
        tag = "Maximum reputation in current standing",
        value = function(info) return info.top end
    },
    ["toGo"] = {
        tag = "Reputation to gain/loss for next/previous standing",
        value = function(info) return (info.negative and ("-" .. info.current) or (info.maximum - info.current)) end
    },
    ["changePercent"] = {
        tag = "Percentual change of reputation",
        value = function(info) return format("%.2f%%%%", (info.maximum == 0 and 0) or (info.change / info.maximum * 100)) end
    },
    ["sessionPercent"] = {
        tag = "Percentual change of reputation during active session",
        value = function(info) return format("%.1f%%%%", (info.maximum == 0 and 0) or (info.session / info.maximum * 100)) end
    },
    ["currentPercent"] = {
        tag = "Percent of next standing",
        value = function(info) return format("%.1f%%%%", (info.maximum == 0 and 0) or (info.current / info.maximum * 100)) end
    },
    ["paragonLevel"] = {
        tag = "Paragon level (with reward icon if available)",
        value = function(info) return info.paragon end
    },
    ["c_paragonLevel"] = {
        tag = "Colored paragon level (with reward icon if available)",
        value = function(info)
            local reputationColors = Addon.db.profile.Colors
            local paragonColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[9].r*255, reputationColors[9].g*255, reputationColors[9].b*255)            
            return paragonColor .. info.paragon .. "|r"
        end
    },
    ["renownLevel"] = {
        tag = "Renown level",
        value = function(info) return info.renown end
    },
    ["c_renownLevel"] = {
        tag = "Colored renown level",
        value = function(info)
            local reputationColors = Addon.db.profile.Colors
            local renownColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[10].r*255, reputationColors[10].g*255, reputationColors[10].b*255)
            return renownColor .. info.renown .. "|r"
        end
    },
    ["bar"] = {
        tag = "Shows barlike progress representation of current standing",
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
}
