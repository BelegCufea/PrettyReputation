local Addon = select(2, ...)
Addon.TAGS = LibStub:NewLibrary("PrettyReputationTags", 1)

local LSM = LibStub("LibSharedMedia-3.0")

Addon.TAGS.Options = {
    Reputation = {
        barChar = function() return Addon.db.profile.Reputation.barChar end,
        barLength = function() return Addon.db.profile.Reputation.barLength end,
        barTextureHeight = function() return Addon.db.profile.Reputation.barSolidHeight end,
        barTextureWidth = function() return Addon.db.profile.Reputation.barSolidWidth end,
        barTextureOffset = function() return Addon.db.profile.Reputation.barSolidOffset end,
        barTexture = function() return LSM:Fetch("statusbar", Addon.db.profile.Reputation.barSolidTexture) end,
        showParagonCount = function() return Addon.db.profile.Reputation.showParagonCount end,
        shortCharCount = function() return Addon.db.profile.Reputation.shortCharCount end,
        iconSize = function() return Addon.db.profile.Reputation.iconHeight end,
        iconStyle = function() return Addon.db.profile.Reputation.iconStyle end,
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

local function first_letters(str, x)
    local result = ""
    for word in str:gmatch("%S+") do
      if tonumber(word) ~= nil then
        result = result .. word
      else
        result = result .. word:sub(1, x)
      end
    end
    return result
end

local function get_bar(info, colorFull, colorEmpty)
    if info.maximum == 0 then return "" end
    local barChar = Addon.db.profile.Reputation.barChar
    local barLen = Addon.db.profile.Reputation.barLength
    local bar = string.rep(barChar, barLen)
    local percentBar = math.floor((info.current / info.maximum * 100) / (100 / barLen))
    local percentBarText =  colorFull .. string.sub(bar, 0, percentBar * 2) .. "|r" .. colorEmpty .. string.sub(bar, percentBar * 2 + 1) .. "|r"
    return "|W" .. Addon.CONST.MESSAGE_COLORS.BAR_EDGE .. "[|r" .. percentBarText .. Addon.CONST.MESSAGE_COLORS.BAR_EDGE .. "]|r|w"
end

local function get_texture(info, colorFull, colorEmpty)
    if info.maximum == 0 then return "" end
    colorFull = string.sub(colorFull, 5, 10)
    colorEmpty = string.sub(colorEmpty, 5, 10)

    local textureHeight = 32 -- well it may work
    local textureWidth = 256 -- this one also :-)
    local barHeight = Addon.db.profile.Reputation.barSolidHeight
    local barWidth = Addon.db.profile.Reputation.barSolidWidth
    local barOffset = Addon.db.profile.Reputation.barSolidOffset
    local percentBar = math.floor((info.current / info.maximum * 100) / (100 / barWidth))
    local textureSplit = math.floor((info.current / info.maximum) * textureWidth)
    local barTexture = LSM:Fetch("statusbar", Addon.db.profile.Reputation.barSolidTexture)
    local texture = "|T%s:%d:%d:0:%d:" .. textureWidth .. ":" .. textureHeight .. ":%d:%d:0:" .. textureHeight .. ":%d:%d:%d|t"
    local rF, gF, bF = tonumber("0x" .. string.sub(colorFull, 1, 2)), tonumber("0x" .. string.sub(colorFull, 3, 4)), tonumber("0x" .. string.sub(colorFull, 5, 6))
    local rE, gE, bE = tonumber("0x" .. string.sub(colorEmpty, 1, 2)), tonumber("0x" .. string.sub(colorEmpty, 3, 4)), tonumber("0x" .. string.sub(colorEmpty, 5, 6))

    local barFull = ""
    local barEmpty = ""
    if percentBar > 0 then
        barFull = texture:format(barTexture, barHeight, percentBar, barOffset, 0, textureSplit, rF, gF, bF)
    end
    if percentBar < barWidth then
        barEmpty = texture:format(barTexture, barHeight, barWidth - percentBar, barOffset, textureSplit + 1, textureWidth, rE, gE, bE)
    end
    return "|W" .. barFull .. barEmpty .. "|w"
end

local function combine(info, value)
    if value and value ~= "" then
        return (info.prefix or "") .. value .. (info.suffix or "")
    else
        return ""
    end
end

Addon.TAGS.Functions = {
    Short = function(text, characters)
        return first_letters(text, characters)
    end,
    Combine = function(info, value)
        return combine(info, value)
    end,
}

Addon.TAGS.Definition = {
    ["name"] = {
        desc = "Name of the faction",
        value = function(info) return Addon.CONST.MESSAGE_COLORS.NAME .. combine(info, info.name) .. "|r" end
    },
    ["c_name"] = {
        desc = "Name of the faction colored by standing",
        value = function(info) return info.standingColor .. combine(info, info.name) .. "|r" end
    },
    ["nc_name"] = {
        desc = "Name of the faction (no accent color)",
        value = function(info) return combine(info, info.name) end
    },
    ["nameShort"] = {
        desc = "A shortened name of the faction",
        value = function(info)
            local nameShort =  first_letters(info.name, Addon.db.profile.Reputation.shortCharCount)
            return Addon.CONST.MESSAGE_COLORS.NAME .. combine(info, nameShort) .. "|r"
        end
    },
    ["c_nameShort"] = {
        desc = "A shortened name of the faction colored by standing",
        value = function(info)
            local nameShort =  first_letters(info.name, Addon.db.profile.Reputation.shortCharCount)
            return info.standingColor .. combine(info, nameShort) .. "|r"
        end
    },
    ["nc_nameShort"] = {
        desc = "A shortened name of the faction (no accent color)",
        value = function(info)
            local nameShort =  first_letters(info.name, Addon.db.profile.Reputation.shortCharCount)
            return combine(info, nameShort)
        end
    },
    ["standing"] = {
        desc = "Current reputation standing",
        value = function(info)
            if Addon.db.profile.Reputation.showParagonCount and info.paragon ~= "" then
                return combine(info, info.standingText .. " (" .. info.paragon .. ")")
            else
                return combine(info, info.standingText)
            end
        end
    },
    ["standingShort"] = {
        desc = "A shortened expression of the current reputation standing, with a maximum of 'x' characters per word, can be set in the options (1 is the default value for x).",
        value = function(info)
            local standingTextShort = first_letters(info.standingText, Addon.db.profile.Reputation.shortCharCount)
            if Addon.db.profile.Reputation.showParagonCount and info.paragon ~= "" then
                return combine(info, standingTextShort .. " (" .. info.paragon .. ")")
            else
                return combine(info, standingTextShort)
            end
        end
    },
    ["c_standing"] = {
        desc = "Colored current reputation standing",
        value = function(info)
            if Addon.db.profile.Reputation.showParagonCount and info.paragon ~= "" then
                local reputationColors = Addon.db.profile.Colors
                local paragonColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[9].r*255, reputationColors[9].g*255, reputationColors[9].b*255)
                return info.standingColor .. combine(info, info.standingText) .. "|r" .. paragonColor .. " (" .. info.paragon .. ")|r"
            else
                return info.standingColor .. combine(info, info.standingText) .. "|r"
            end
        end
    },
    ["c_standingShort"] = {
        desc = "A colored, shortened expression of the current reputation standing, with a maximum of 'x' characters per word, can be set in the options (1 is the default value for x).",
        value = function(info)
            local standingTextShort = first_letters(info.standingText, Addon.db.profile.Reputation.shortCharCount)
            if Addon.db.profile.Reputation.showParagonCount and info.paragon ~= "" then
                local reputationColors = Addon.db.profile.Colors
                local paragonColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[9].r*255, reputationColors[9].g*255, reputationColors[9].b*255)
                return info.standingColor .. combine(info, standingTextShort) .. "|r" .. paragonColor .. " (" .. info.paragon .. ")|r"
            else
                return info.standingColor .. combine(info, standingTextShort) .. "|r"
            end
        end
    },
    ["change"] = {
        desc = "Actual gain/loss of reputation",
        value = function(info) return combine(info, (info.negative and "-" or "+") .. BreakUpLargeNumbers(info.change)) end
    },
    ["c_change"] = {
        desc = "Actual gain/loss of reputation (green for gain, red for loss)",
        value = function(info) return (info.negative and Addon.CONST.MESSAGE_COLORS.NEGATIVE or Addon.CONST.MESSAGE_COLORS.POSITIVE) .. combine(info, (info.negative and "-" or "+") .. BreakUpLargeNumbers(info.change)).. "|r" end
    },
    ["session"] = {
        desc = "Gain of reputation in current session",
        value = function(info) return combine(info, ((info.session > 0) and "+" or "") .. BreakUpLargeNumbers(info.session)) end
    },
    ["c_session"] = {
        desc = "Gain of reputation in current session (green for gain, red for loss)",
        value = function(info) return ((info.session > 0) and Addon.CONST.MESSAGE_COLORS.POSITIVE or Addon.CONST.MESSAGE_COLORS.NEGATIVE) .. combine(info, ((info.session > 0) and "+" or "") .. BreakUpLargeNumbers(info.session)) .. "|r" end
    },
    ["current"] = {
        desc = "Current reputation value",
        value = function(info) return combine(info, BreakUpLargeNumbers(info.current)) end
    },
    ["next"] = {
        desc = "Reputation boundary for next level",
        value = function(info) return combine(info, BreakUpLargeNumbers(info.maximum)) end
    },
    ["bottom"] = {
        desc = "Minimum reputation in current standing",
        value = function(info) return combine(info, BreakUpLargeNumbers(info.bottom)) end
    },
    ["top"] = {
        desc = "Maximum reputation in current standing",
        value = function(info) return combine(info, BreakUpLargeNumbers(info.top)) end
    },
    ["toGo"] = {
        desc = "Reputation to gain/loss for next/previous standing",
        value = function(info) return combine(info, (info.negative and ("-" .. BreakUpLargeNumbers(info.current))) or BreakUpLargeNumbers(info.maximum - info.current)) end
    },
    ["changePercent"] = {
        desc = "Percentual change of reputation",
        value = function(info) return combine(info, format("%.2f%%", (info.maximum == 0 and 0) or (info.change / info.maximum * 100))) end
    },
    ["sessionPercent"] = {
        desc = "Percentual change of reputation during active session",
        value = function(info) return combine(info, format("%.1f%%", (info.maximum == 0 and 0) or (info.session / info.maximum * 100))) end
    },
    ["currentPercent"] = {
        desc = "Percent of next standing",
        value = function(info) return combine(info, format("%.1f%%", (info.maximum == 0 and 0) or (info.current / info.maximum * 100))) end
    },
    ["paragonLevel"] = {
        desc = "Paragon level (with reward icon if available)",
        value = function(info) return combine(info, info.paragon) end
    },
    ["c_paragonLevel"] = {
        desc = "Colored paragon level (with reward icon if available)",
        value = function(info)
            local reputationColors = Addon.db.profile.Colors
            local paragonColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[9].r*255, reputationColors[9].g*255, reputationColors[9].b*255)
            return paragonColor .. combine(info, info.paragon) .. "|r"
        end
    },
    ["renownLevel"] = {
        desc = "Renown level",
        value = function(info) return combine(info, info.renown) end
    },
    ["renownLevelNoParagon"] = {
        desc = "Renown level",
        value = function(info)
            if info.paragon and info.paragon ~= "" then return "" end
            return combine(info, info.renown)
        end
    },
    ["c_renownLevel"] = {
        desc = "Colored renown level",
        value = function(info)
            local reputationColors = Addon.db.profile.Colors
            local renownColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[10].r*255, reputationColors[10].g*255, reputationColors[10].b*255)
            return renownColor .. combine(info, info.renown) .. "|r"
        end
    },
    ["c_renownLevelNoParagon"] = {
        desc = "Colored renown level",
        value = function(info)
            if info.paragon and info.paragon ~= "" then return "" end
            local reputationColors = Addon.db.profile.Colors
            local renownColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[10].r*255, reputationColors[10].g*255, reputationColors[10].b*255)
            return renownColor .. combine(info, info.renown) .. "|r"
        end
    },
    ["bar"] = {
        desc = "Shows barlike progress representation of current standing",
        value = function(info)
            return get_bar(info, Addon.CONST.MESSAGE_COLORS.BAR_FULL, Addon.CONST.MESSAGE_COLORS.BAR_EMPTY)
        end
    },
    ["c_bar"] = {
        desc = "Shows barlike progress representation of current standing in standing color",
        value = function(info)
            return get_bar(info, info.standingColor, Addon.CONST.MESSAGE_COLORS.BAR_EMPTY)
        end
    },
    ["barTexture"] = {
        desc = "Shows textured bar representing current standing",
        value = function(info)
            return get_texture(info, Addon.CONST.MESSAGE_COLORS.BAR_FULL, Addon.CONST.MESSAGE_COLORS.BAR_EMPTY)
        end
    },
    ["c_barTexture"] = {
        desc = "Shows textured bar representing current standing colored by standing",
        value = function(info)
            return get_texture(info, info.standingColor, Addon.CONST.MESSAGE_COLORS.BAR_EMPTY)
        end
    },
    ["more"] = {
        desc = "How many of this gain/loss to reach next/prevois standing",
        value = function(info)
            if info.change then
                if info.negative then
                    return combine(info, math.ceil(info.current/info.change))
                else
                    return combine(info, math.ceil((info.maximum - info.current)/info.change))
                end
            end
            return ""
        end
    },
    ["icon"] = {
        desc = "Show faction icon if available (all, if Faction Addict is installed - see About)",
        value = function(info)
            if info.icon then
                if Addon.db.profile.Reputation.iconStyle == 'clean' then
                    return string.format(Addon.CONST.ICON.CLEAN, info.icon, Addon.db.profile.Reputation.iconHeight, Addon.db.profile.Reputation.iconHeight)
                else
                    return string.format(Addon.CONST.ICON.DEFAULT, info.icon, Addon.db.profile.Reputation.iconHeight, Addon.db.profile.Reputation.iconHeight)
                end
            end
            return ""
        end
    },
    ["standingColorStart"] = {
        desc = "Color the text between it and [standingColorEnd] with a standing color. |cnWARNING_FONT_COLOR:Must be used with [standingColorEnd] TAG!|r",
        value = function(info)
            return info.standingColor
        end
    },
    ["standingColorEnd"] = {
        desc = "Color the text between it and [standingColorStart] with a standing color. |cnWARNING_FONT_COLOR:Must be used with [standingColorStart] TAG!|r",
        value = function(info)
            return "|r"
        end
    },
    ["signText"] = {
        desc = "If a reputation is gained then it will display 'increased' when lost then 'decreased' (may be modified on Tags options panel)",
        value = function(info)
            return combine(info, (info.negative and Addon.db.profile.Reputation.signTextNegative) or Addon.db.profile.Reputation.signTextPositive)
        end
    },
    ["standingNext"] = {
        desc = "Shows next/previous (depending on gain or loss) standing/paragon",
        value = function(info)
            return combine(info, info.standingTextNext)
        end
    },
    ["c_standingNext"] = {
        desc = "Shows next/previous (depending on gain or loss) standing/renown/paragon in that standing color",
        value = function(info)
            if info.standingIdNext then
                local reputationColors = Addon.db.profile.Colors
                local standingColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[info.standingIdNext].r*255, reputationColors[info.standingIdNext].g*255, reputationColors[info.standingIdNext].b*255)
                return standingColor .. combine(info, info.standingTextNext) .. "|r"
            else
                return combine(info, info.standingtextNext)
            end
        end
    },
    ["standingNextShort"] = {
        desc = "Shows next/previous (depending on gain or loss) standing/paragon, with a maximum of 'x' characters per word, can be set in the options (1 is the default value for x).",
        value = function(info)
            return combine(info, first_letters(info.standingTextNext, Addon.db.profile.Reputation.shortCharCount))
        end
    },
    ["c_standingNextShort"] = {
        desc = "Shows next/previous (depending on gain or loss) standing/renown/paragon in that standing color, with a maximum of 'x' characters per word, can be set in the options (1 is the default value for x).",
        value = function(info)
            if info.standingIdNext then
                local reputationColors = Addon.db.profile.Colors
                local standingColor = ("|cff%.2x%.2x%.2x"):format(reputationColors[info.standingIdNext].r*255, reputationColors[info.standingIdNext].g*255, reputationColors[info.standingIdNext].b*255)
                return standingColor .. combine(info, first_letters(info.standingTextNext, Addon.db.profile.Reputation.shortCharCount)) .. "|r"
            else
                return combine(info, first_letters(info.standingTextNext, Addon.db.profile.Reputation.shortCharCount))
            end
        end
    },
}
