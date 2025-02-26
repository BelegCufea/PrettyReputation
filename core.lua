local ADDON_NAME = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "LibSink-2.0")

local GetNumFactions = C_Reputation.GetNumFactions
local GetFactionDataByIndex = C_Reputation.GetFactionDataByIndex
local GetFactionDataByID = C_Reputation.GetFactionDataByID
local ExpandAllFactionHeaders = C_Reputation.ExpandAllFactionHeaders
local ExpandFactionHeader = C_Reputation.ExpandFactionHeader
local CollapseFactionHeader = C_Reputation.CollapseFactionHeader
local GetWatchedFactionData = C_Reputation.GetWatchedFactionData
local SetWatchedFactionByID = C_Reputation.SetWatchedFactionByID
local GetFactionParagonInfo = C_Reputation.GetFactionParagonInfo
local IsMajorFaction = C_Reputation.IsMajorFaction
local IsFactionParagon = C_Reputation.IsFactionParagon
local GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation
local GetFriendshipReputationRanks = C_GossipInfo.GetFriendshipReputationRanks
local GetMajorFactionIDs = C_MajorFactions.GetMajorFactionIDs
local GetMajorFactionData = C_MajorFactions.GetMajorFactionData
local HasMaximumRenown = C_MajorFactions.HasMaximumRenown
local GetRenownLevels = C_MajorFactions.GetRenownLevels
local GetMajorFactionRenownInfo = C_MajorFactions.GetMajorFactionRenownInfo
local GetDelvesFactionForSeason = C_DelvesUI.GetDelvesFactionForSeason
local GetCurrencyInfo = C_CurrencyInfo.GetCurrencyInfo
local GetCurrencyInfoFromLink = C_CurrencyInfo.GetCurrencyInfoFromLink
local MAJOR_FACTION_REPUTATION_REWARD_ICON_FORMAT = [[Interface\Icons\UI_MajorFaction_%s]]

local Debug = Addon.DEBUG
local Const = Addon.CONST
local Tags = Addon.TAGS
local Bars = Addon.Bars
local Options

local factionPanelFix = true
local guildname
local private = {}
local icons = {}
local factions = {}
local delveFaction = {currencyID = 3068, currencyAltID = 2803}
Addon.Factions = factions

local AddonDB_Defaults = {
    profile = {
        Enabled = true,
        Reputation = {
            pattern = "[name] ([c_standing]): [c_change]/[c_session] ([currentPercent]) [bar]",
            barChar = "||",
            barLength = 20,
            barSolidWidth = 50,
            barSolidHeight = 10,
            barSolidTexture = "Blizzard",
            barSolidOffset = 0,
            showParagonCount = true,
            shortCharCount = 1,
            iconHeight = 0,
            iconStyle = "default",
            signTextPositive = "increased",
            signTextNegative = "decreased",
            paragonColorOverride = false,
            patternChatFrame = "[name] ([c_standing]): [c_change]/[c_session] ([currentPercent]) [bar]",
            patternChatFrameOverride = false,
        },
        Bars = {
            enabled = true,
            locked = false,
            texture = "Blizzard",
            width = 300,
            height = 18,
            posx = 100,
            posy = -100,
            icon = false,
            font = "2002",
            fontSize = 11,
            fontOutline = "OUTLINE",
            alpha = 0.8,
            sort = "session",
            growUp = false,
            tooltipAnchor = "RIGHT",
            removeAfter = 0,
            paragonColorOverride = true,
            patternLeft = "[nc_name][{ |}renownLevelNoParagon{|}][{ x}paragonLevel] ([current] / [next])",
            patternRight = "[c_session]",
        },
        Test = {
            faction = "Darkmoon Faire",
            change = 100,
        },
        Colors = Const.REP_COLORS.wowproColors,
        ColorsPreset = "wowpro",
        ColorRenownLow  = {},
        ColorRenownHigh = {},
        ColorFriendLow  = {},
        ColorFriendHigh = {},
        ColorParagon    = {},
        minimapIcon = { hide = true, minimapPos = 220, radius = 80, },
        AddonCompartment = { hide = false },
        Track = false,
        TrackPositive = false,
        TrackGuild = false,
        TooltipSort = "value",
        sink20OutputSink = "ChatFrame",
        sinkChat = false,
        sinkChatFrames = {"ChatFrame1"},
        Splash = false,
        Debug = false,
        FavoriteFactions = {},
    }
}

function private.saveRepHeaders()
    local parse = true -- make it an option?
    local collapsed = {}
    if not parse then
        ExpandAllFactionHeaders()
        return collapsed
    end

    local lastName
    local i = 1
    while true do
        local factionData = GetFactionDataByIndex(i)
        if not factionData or not factionData.name or (factionData.name == lastName and factionData.name ~= GUILD) then break end
        if (factionData.factionID == nil) then factionData.factionID = factionData.name	end
        if factionData.isHeader and factionData.isCollapsed then
            ExpandFactionHeader(i)
            collapsed[factionData.factionID] = true
        end
        lastName = factionData.name
        i = i + 1
    end
    ExpandAllFactionHeaders() -- to be sure every header is expanded
    return collapsed
end

function private.restoreRepHeaders(collapsed)
    if next(collapsed) == nil then
        return
    end
	for i = GetNumFactions(), 1, -1 do
        local factionData = GetFactionDataByIndex(i)
		if (factionData.factionID == nil) then factionData.factionID = factionData.name	end

		if factionData.isHeader and collapsed[factionData.factionID] then
            CollapseFactionHeader(i)
		end
	end
end

function private.setupIcons() -- FactionAddict
    if not faFactionData then return end
	for maintableRow in ipairs(faFactionData) do
        icons[faFactionData[maintableRow][1]] = faFactionData[maintableRow][2]
	end
end

function private.setupFaction(factionData)
    if factionData and factionData.name and factionData.factionID and factionData.factionID ~= 0 then
        if not factions[factionData.name] then
            factions[factionData.name] = { id = factionData.factionID, session = 0}
        end
        if not factions[factionData.name].id then
            factions[factionData.name].id = factionData.factionID
        end
        if not factions[factionData.name].session then
            factions[factionData.name].session = 0
        end
        if not factions[factionData.name].info then
            local info = {}
            info["faction"] = factionData.name
            info["factionID"] = factionData.factionID
            info["change"] = 0
            info["session"] = factions[factionData.name].session
            info["expansionID"] = factionData.expansionID
            factions[factionData.name].info = private.getRepInfo(info)
        end
    end
end

function private.setupFactions()
    if IsInGuild() then
        guildname = GetGuildInfo("player")
    end
    -- load FactionAddict Icons
    if next(icons) == nil then private.setupIcons() end
    do -- itterate major factions reputations
        for _, factionId in ipairs(GetMajorFactionIDs()) do
            private.setupFaction(GetMajorFactionData(factionId))
        end
    end
    do -- itterate Reputation panel reputations
        local collapsedHeaders = private.saveRepHeaders() -- pretty please make all factions visible
        for i=1, GetNumFactions() do
            private.setupFaction(GetFactionDataByIndex(i))
        end
        private.restoreRepHeaders(collapsedHeaders) -- restore collapsed faction headers
    end
    do -- delves
        local info = GetCurrencyInfo(delveFaction.currencyID)
        if info then
            local factionId = C_DelvesUI.GetDelvesFactionForSeason()
            delveFaction.factionID = factionId
            delveFaction.name = info.name
            private.setupFaction(delveFaction)
        end
    end
    do -- "WTF why is Blizz not listing all factions in Reputation panel" temporary onetime FIX
        if factionPanelFix then
            factionPanelFix = false
            for factionID=1, 5000 do
                local factionData = GetFactionDataByID(factionID)
                if factionData and factionData.name and not factions[factionData.name] then
                    private.setupFaction(factionData)
                    if factions[factionData.name] then
                        factions[factionData.name].blizzFix = true
                    end
                end
            end
        end
    end
    Debug:Table("Factions", factions)
end

function private.trackFaction(info)
    if not info then return end
    local watchedFactionData = GetWatchedFactionData()
    if watchedFactionData and info.faction == watchedFactionData.name then return end
    if ((info.faction == GUILD) or (info.faction == guildname)) and not Options.TrackGuild then return end
    if info.negative and Options.TrackPositive then return end
    if factions[info.faction] and factions[info.faction].id and factions[info.faction].id ~= delveFaction.factionID then
        SetWatchedFactionByID(factions[info.faction].id)
    end
end

local SEX = UnitSex("player")
function private.getFactionLabel(standingId)
	if standingId == "paragon" then
		return "Paragon"
	end
	if (standingId == "renown") then
		return "Renown"
	end
	return GetText("FACTION_STANDING_LABEL" .. standingId, SEX)
end

function private.rgbToHsv(colRGB)
    local max, min = math.max(colRGB.r, colRGB.g, colRGB.b), math.min(colRGB.r, colRGB.g, colRGB.b)
    local h, s, v = 0, 0, max
    local d = max - min
    s = max == 0 and 0 or d / max

    if max ~= min then
        if max == colRGB.r then
            h = (colRGB.g - colRGB.b) / d + (colRGB.g < colRGB.b and 6 or 0)
        elseif max == colRGB.g then
            h = (colRGB.b - colRGB.r) / d + 2
        elseif max == colRGB.b then
            h = (colRGB.r - colRGB.g) / d + 4
        end
        h = h / 6
    end

    return {h = h * 360, s = s, v = v}
end

function private.hsvToRgb(colHSV)
    local r, g, b

    local i = math.floor(colHSV.h / 60) % 6
    local f = (colHSV.h / 60) - math.floor(colHSV.h / 60)
    local p = colHSV.v * (1 - colHSV.s)
    local q = colHSV.v * (1 - f * colHSV.s)
    local t = colHSV.v * (1 - (1 - f) * colHSV.s)

    if i == 0 then r, g, b = colHSV.v, t, p
    elseif i == 1 then r, g, b = q, colHSV.v, p
    elseif i == 2 then r, g, b = p, colHSV.v, t
    elseif i == 3 then r, g, b = p, q, colHSV.v
    elseif i == 4 then r, g, b = t, p, colHSV.v
    elseif i == 5 then r, g, b = colHSV.v, p, q
    end

    return {r = r, g = g, b = b }
end

function private.interpolateColors(colRGB1, colRGB2, factor)
    local colHSV1 = private.rgbToHsv(colRGB1)
    local colHSV2 = private.rgbToHsv(colRGB2)
    local h
    if math.abs(colHSV1.h - colHSV2.h) > 180 then
        if colHSV1.h > colHSV2.h then
            h = colHSV1.h + factor * ((colHSV2.h + 360) - colHSV1.h)
        else
            h = colHSV1.h - factor * ((colHSV1.h + 360) - colHSV2.h)
        end
    else
        h = colHSV1.h + factor * (colHSV2.h - colHSV1.h)
    end
    h = h % 360

    local s = colHSV1.s + factor * (colHSV2.s - colHSV1.s)
    local v = colHSV1.v + factor * (colHSV2.v - colHSV1.v)

    return private.hsvToRgb({ h = h, s = s, v = v})
end

function Addon:GetFactionColors(info, bar)
    local reputationColors = Options.Colors
    if (info.factionID and info.factionID ~= 0) then
        local factionData = GetFactionDataByID(info.factionID)
        if not factionData and info.factionID ~= delveFaction.factionID then return reputationColors[5], reputationColors[5] end
        local level = info.level and info.level > 0 and info.level or 1
        local maxLevel = info.maxLevel and info.maxLevel > level and info.maxLevel or level
        if (IsMajorFaction(info.factionID)) then
            local colorLow = Options.ColorRenownLow
            local colorHigh = Options.ColorRenownHigh
            local colorParagon = Options.ColorParagon
            local paragonOverride = bar and Options.Bars.paragonColorOverride or Options.Reputation.paragonColorOverride
            if paragonOverride and IsFactionParagon(info.factionID) then
                return colorParagon, colorParagon
            end
            if level and maxLevel and maxLevel > 1 then
                local color = private.interpolateColors(colorLow, colorHigh, (level-1)/(maxLevel-1))
                local colorNext = color
                if level < maxLevel then
                    colorNext = private.interpolateColors(colorLow, colorHigh, (level)/(maxLevel-1))
                end
                return color, colorNext
            end
            return colorLow, colorLow
		end

		if (IsFactionParagon(info.factionID)) then
            local colorParagon = Options.ColorParagon
			return colorParagon, colorParagon
		end

		local friendInfo = GetFriendshipReputation(info.factionID)
		if (friendInfo.friendshipFactionID and friendInfo.friendshipFactionID ~= 0) then
            if level and maxLevel then
                local colorLow = Options.ColorFriendLow
                local colorHigh = Options.ColorFriendHigh
                local color = private.interpolateColors(colorLow, colorHigh, (level-1)/(maxLevel-1))
                local colorNext = color
                if level < maxLevel then
                    colorNext = private.interpolateColors(colorLow, colorHigh, (level)/(maxLevel-1))
                end
                return color, colorNext
            end
			return reputationColors[5], reputationColors[5]
		end

        if not factionData or (factionData.reaction == nil) then
            return {r = 1, b = 0, g = 0}, {r = 1, b = 0, g = 0}
		end

        local color = reputationColors[factionData.reaction] or reputationColors[5]
        local colorNext = factionData.reaction == 8 and color or reputationColors[factionData.reaction + 1] or reputationColors[5]
        return color, colorNext
	end
    return nil
end

function private.getRepInfo(info)
    local showParagonCount = Options.Reputation.showParagonCount
    local processed = false
    if (info.factionID and info.factionID ~= 0) then
        if info.factionID == delveFaction.factionID then
            local data = GetMajorFactionRenownInfo(info.factionID)
            if not data then return info end
            local levels = GetRenownLevels(info.factionID)
            info["maxLevel"] = 0
            if levels then
                for _, levelInfo in ipairs(levels) do
                    if levelInfo.level > info["maxLevel"] then
                        info["maxLevel"] = levelInfo.level
                    end
                end
            end
            info["bottom"] = (data.renownLevel - 1) * data.renownLevelThreshold
            info["top"] = data.renownLevel * data.renownLevelThreshold
            info["current"] = data.renownReputationEarned or 0
            info["maximum"] = data.renownLevelThreshold
            info["standingText"] = ("Stage " .. data.renownLevel)
            info["renown"] = data.renownLevel
            info["level"] = data.renownLevel
            info["standingTextNext"] = "Stage " .. (data.renownLevel + 1)
            info["standingId"] = 10
            info["standingIdNext"] = 10
            info["name"] = delveFaction.name
            info["paragon"] = ""
            info["reward"] = ""
            processed = true
        end
        local factionData = GetFactionDataByID(info.factionID)
        if not processed then
            if not factionData then return info end
            info["standingId"] = factionData.reaction
            info["name"] = factionData.name
            info["bottom"] = factionData.currentReactionThreshold
            info["top"] = factionData.nextReactionThreshold
            info["paragon"] = ""
            info["renown"] = ""
            info["standingTextNext"] = ""
            info["reward"] = ""
        end
        if icons and icons[info.factionID] then
            info["icon"] = icons[info.factionID]
        end

        if not processed and (IsMajorFaction(info.factionID)) then
            info["isRenown"] = true
			local data = GetMajorFactionData(info.factionID)
			local isCapped = HasMaximumRenown(info.factionID)
            local isParagon = IsFactionParagon(info.factionID)
            local levels = GetRenownLevels(info.factionID)
            info["maxLevel"] = 0
            if levels then
                for _, levelInfo in ipairs(levels) do
                    if levelInfo.level > info["maxLevel"] then
                        info["maxLevel"] = levelInfo.level
                    end
                end
            end
            if data then
                info["bottom"] = (data.renownLevel - 1) * data.renownLevelThreshold
                info["top"] = data.renownLevel * data.renownLevelThreshold
                info["current"] = isCapped and data.renownLevelThreshold or data.renownReputationEarned or 0
                info["maximum"] = data.renownLevelThreshold
                info["standingText"] = RENOWN_LEVEL_LABEL:format(data.renownLevel)
                info["renown"] = data.renownLevel
                info["level"] = data.renownLevel
                info["standingTextNext"] =  RENOWN_LEVEL_LABEL:format(data.renownLevel+1)
                info["standingId"] = 10
                info["standingIdNext"] = 10
                if not info["icon"] then
                    info["icon"] = MAJOR_FACTION_REPUTATION_REWARD_ICON_FORMAT:format(data.textureKit)
                    -- fix for Dream Wardens icon (and possibly more in the future)
                    info["icon"] = Const.MAJOR_FACTON_ICONS_OVERRIDE[info.factionID] and MAJOR_FACTION_REPUTATION_REWARD_ICON_FORMAT:format(Const.MAJOR_FACTON_ICONS_OVERRIDE[info.factionID]) or info["icon"]
                end
                if isCapped and isParagon then
                    local currentValue, threshold, _, hasRewardPending = GetFactionParagonInfo(info.factionID)
                    local paragonLevel = (currentValue - (currentValue % threshold))/threshold
                    if showParagonCount and paragonLevel > 0 then
                        info["paragon"] =  info["paragon"] .. paragonLevel
                    end
                    info["standingTextNext"] = private.getFactionLabel("paragon") .. " " .. (paragonLevel + 1)
                    info["standingId"] = 9
                    info["standingIdNext"] = 9
                    if hasRewardPending then
                        local reward = "|A:ParagonReputation_Bag:0:0|a"
                        info["reward"] = reward
                        info["paragon"] = info["paragon"] .. reward
                        if not showParagonCount then
                            info["standingText"] = info["standingText"] .. " " .. reward
                        end
                    end
                    info["current"] = mod(currentValue, threshold)
                    info["maximum"] = threshold
                    info["bottom"] = info["bottom"] + paragonLevel * threshold
                    info["top"] = info["bottom"] + threshold
                end
            else
                info["current"] = 0
                info["maximum"] = 0
                info["standingText"] = RENOWN_LEVEL_LABEL
            end
            processed = true
		end

		if not processed and (factionData.reaction == nil) then
            info["current"] = 0
            info["maximum"] = 0
            info["color"] = {r = 1, b = 0, g = 0}
            info["standingText"] = "??? - " .. (info.factionID .. "?")
            info["bottom"] = 0
            info["top"] = 0
            processed = true
        end

		if not processed and (IsFactionParagon(info.factionID)) then
			local currentValue, threshold, _, hasRewardPending = GetFactionParagonInfo(info.factionID);
			local paragonLevel = (currentValue - (currentValue % threshold))/threshold
			info["standingText"] = private.getFactionLabel("paragon")
			if showParagonCount and paragonLevel > 0 then
                info["paragon"] =  info["paragon"] .. paragonLevel
            end
            info["standingTextNext"] = private.getFactionLabel("paragon") .. " " .. (paragonLevel + 1)
            info["standingId"] = 9
            info["standingIdNext"] = 9
			if hasRewardPending then
                local reward = "|A:ParagonReputation_Bag:0:0|a"
                info["reward"] = reward
                info["paragon"] =  info["paragon"] .. reward
                if not showParagonCount then
                    info["standingText"] = info["standingText"] .. " " .. reward
                end
			end
            info["current"] = mod(currentValue, threshold)
            info["maximum"] = threshold
            info["bottom"] = info["top"] + paragonLevel * threshold
            info["top"] = info["bottom"] + threshold
            processed = true
		end

		local friendInfo = GetFriendshipReputation(info.factionID)
        local rankInfo = GetFriendshipReputationRanks(info.factionID)
		if not processed and (friendInfo.friendshipFactionID and friendInfo.friendshipFactionID ~= 0) then
            info["current"] = 1
			info["maximum"] = 1
            info["bottom"] = friendInfo.reactionThreshold
            info["top"] = friendInfo.reactionThreshold
			info["standingText"] = friendInfo.reaction
            info["level"] = rankInfo.currentLevel
            info["maxLevel"] = rankInfo.maxLevel
            if (friendInfo.nextThreshold) then
                info["current"] = friendInfo.standing - friendInfo.reactionThreshold
				info["maximum"] = friendInfo.nextThreshold - friendInfo.reactionThreshold
                info["top"] = friendInfo.nextThreshold
			end
            processed = true
		end

        if not processed then
            info["current"] = factionData.currentStanding - info.bottom
            info["maximum"] = info.top - info.bottom
            info["standingText"] = private.getFactionLabel(factionData.reaction)
            info["standingTextNext"] = (info.negative and factionData.reaction > 1 and _G["FACTION_STANDING_LABEL".. factionData.reaction - 1]) or (not info.negative and factionData.reaction < 8 and _G["FACTION_STANDING_LABEL".. factionData.reaction + 1]) or ""
            info["standingIdNext"] = (info.negative and factionData.reaction > 1 and (factionData.reaction - 1)) or (not info.negative and factionData.reaction < 8 and (factionData.reaction + 1))
            processed = true
        end

        info["color"], info["colorNext"] = Addon:GetFactionColors(info)
        if info.color then
            info["standingColor"] = ("|cff%.2x%.2x%.2x"):format(info.color.r*255, info.color.g*255, info.color.b*255)
        else
            info["standingColor"] = ""
        end
        if info.colorNext then
            info["standingColorNext"] = ("|cff%.2x%.2x%.2x"):format(info.colorNext.r*255, info.colorNext.g*255, info.colorNext.b*255)
        else
            info["standingColorNext"] = ""
        end
	end
    return info
end

function private.getFactionSession(info)
    return factions[info.faction] and (factions[info.faction].session + (info.change * ((info.negative and -1 or 1)))) or 0
end

function private.getFactionInfo(info)
    if factions[info.faction] then
        local factionID = factions[info.faction].id
        info["factionID"] = factionID
        local session = private.getFactionSession(info)
        factions[info.faction].session = session
        info["lastUpdated"] = time()
        info["session"] = session
        if Options.Enabled then
            factions[info.faction].info = private.getRepInfo(info)
        end
    end
    return info
end

function Addon:ConstructMessage(info, pattern)
    if info == nil or info.name == nil then
        if info and info.faction and info.change then
            Debug:Info("Faction not found", info.faction .. " [change: " .. (info.negative and "-" or "+") .. info.change .. "]")
        end
        Debug:Table("NotFound", info)
        return ""
    end

    local definitions = Tags.Definition

    local message = pattern:gsub("%[([^%[].-)%]", function(text)
        info.prefix = text:match("^%b{}") or ""
        if info.prefix ~= "" then info.prefix = info.prefix:sub(2, -2) end
        info.suffix = text:match("%b{}$") or ""
        if info.suffix ~= "" then info.suffix = info.suffix:sub(2, -2) end
        local key = text:gsub("%{(.-)%}", "")
        if not definitions[key] or not definitions[key].value then
            return "[" .. text .. "]"
        end
        return definitions[key].value(info)
    end)
    return message
end

function private.printReputation(info)
    if not Options.Enabled then return end
    local message = Addon:ConstructMessage(info, Options.Reputation.pattern
)
    if message and message ~= "" then
        Addon:Pour(message, 1, 1, 1)
        if Options.sinkChat and (Options.sink20OutputSink ~= "ChatFrame") then
            if  Options.Reputation.patternChatFrameOverride then
                message = Addon:ConstructMessage(info, Options.Reputation.patternChatFrame)
            end
            for _, v in pairs(Options.sinkChatFrames) do
                _G[v]:AddMessage(message)
            end
        end
    end

    if Options.Track and not Options.Splash then
        private.trackFaction(info)
    end

    if Options.Debug then
        info.prefix = ""
        info.suffix = ""
        Debug:Table("Info_"..info.faction, info)
        local debug = {}
        local tkeys = {}
        for k in pairs(Tags.Definition) do table.insert(tkeys, k) end
        table.sort(tkeys)
        for _, k in ipairs(tkeys) do
            debug[k] = Tags.Definition[k].value(info)
        end
        Debug:Table("Tags_"..info.faction, debug)
    end
end

function Addon:SetBarsOptions()
    if not Bars then
        Bars = Addon.Bars
    end
    if Options.Bars.enabled then
        if not Bars:IsEnabled() then Bars:Enable() end
    else
        if Bars:IsEnabled() then Bars:Disable() end
    end

    if Options.Enabled and Options.Bars.enabled then
        if not Bars:IsEnabled() then Bars:Enable() end
    end

    if not Options.Enabled then
        if Bars:IsEnabled() then Bars:Disable() end
    end

    Bars:SetOptions()
end

function Addon:UpdateBars()
    if not Bars then
        Bars = Addon.Bars
    end

    Bars:Update()
end

function private.processAllFactions(factionInfo)
    -- OK, need to run even if Options.Enabled is false to avoid wrong session gains
    --debugprofilestart()
    local trackFaction
    for k, v in pairs(factions) do
        local currentOld = v.info.current + v.info.bottom
        local info = private.getRepInfo(v.info)
        local change = (info.current + info.bottom) - currentOld
        if factionInfo.new and (change == 0) and (v.info.faction == factionInfo.faction) and (factionInfo.change ~= 0) then
            change = factionInfo.change * ((factionInfo.negative and -1) or 1)
        end
        if change ~= 0 then
            info.change = math.abs(change)
            info.negative = change < 0
            local session = private.getFactionSession(info)
            factions[info.faction].session = session
            info.session = session
            info.lastUpdated = time()
            private.printReputation(info)
            if not trackFaction then
                trackFaction = info
            elseif trackFaction.change < info.change then
                trackFaction = info
            end
        end
    end
    if trackFaction then private.trackFaction(trackFaction) end
    Debug:Table("Factions", factions)
    --local elapsedTime = debugprofilestop()
    --Debug:Info("EllapsedTime", elapsedTime .. " ms")
end

function private.processFaction(faction, change)
    if faction == GUILD and IsInGuild() then
        faction = guildname or GetGuildInfo("player")
    end
    if not faction then return end
    local info = {}
    Debug:Info("Event", ((faction == nil and "N/A") or faction) .. ": " .. ((change == nil and "N/A") or change))
    info["faction"] = faction

    if type(change) == "number" then
        info["change"] = math.abs(change)
        if tonumber(change) < 0 then
            info["negative"] = true
        end
    else
        info["change"] = 0
    end

    info["new"] = (factions[info.faction] == nil)
    if not Options.Splash then
        if info.new then
            C_Timer.After(0.3, function()
                private.setupFactions()
                info = private.getFactionInfo(info)
                private.printReputation(info)
                Addon:UpdateBars()
                if factions[info.faction] then
                    Debug:Info("New Faction", info.faction .. ((factions[info.faction].id and " found") or " not found"))
                else
                    Debug:Info("New Faction", info.faction .. " not initialized")
                end
            end)
        else
            C_Timer.After(0.5, function()
                info = private.getFactionInfo(info)
                private.printReputation(info)
                Addon:UpdateBars()
            end)
        end
    else
        C_Timer.After(0.3, function()
            private.setupFactions()
            private.processAllFactions(info)
            Addon:UpdateBars()
        end)
    end
end

function private.CombatTextUpdated(_, messagetype)
	if messagetype == 'FACTION' then
		local faction, change = GetCurrentCombatTextEventInfo()
        private.processFaction(faction, change)
	end
end

function private.LootToast(_, typeIdentifier, itemLink, quantity, specID, sex, personalLootToast, toastMethod, lessAwesome, upgraded, corrupted)
    if typeIdentifier == "currency" then
        local currencyInfo = GetCurrencyInfoFromLink(itemLink)
        Debug:Info("Currency", itemLink, quantity)
        Debug:Table("Currency", currencyInfo)
        if currencyInfo and (currencyInfo.currencyID == delveFaction.currencyID or currencyInfo.currencyID == delveFaction.currencyAltID) then
            local info = factions[delveFaction.name].info
            Debug:Table("DelveInfo", info)
            if info then
                local current = info.current
                local maximum = info.maximum
                local level = info.level
                Debug:Info("DelveInfo", current, maximum, level)

                C_Timer.After(0.5, function()
                    local data = GetMajorFactionRenownInfo(delveFaction.factionID)
                    Debug:Table("DelveData", data)
                    if data then
                        local change = data.renownReputationEarned - current + maximum * (data.renownLevel - level)
                        if change > 0 then
                            private.processFaction(delveFaction.name, change)
                        end
                    end
                end)
            end
        end
    end
end

function private.HideReward()
    local updateBars = false
    for k, v in pairs(factions) do
        if v.info and v.info.reward and v.info.reward ~= "" then
            local paragonLevel = 0
            if v.info.paragon then
                paragonLevel = v.info.paragon:match("^%d+")
            end
            local _, _, _, hasRewardPending = GetFactionParagonInfo(v.info.factionID)
            if not hasRewardPending then
                v.info.reward = ""
                v.info.paragon = ((not paragonLevel) and "") or paragonLevel
                v.info.lastUpdated = time()
                updateBars = true
            end
        end
    end
    if updateBars then Addon:UpdateBars() end
end

function private.UpdateReward()
    if Options.Enabled and Options.Bars.enabled then
        C_Timer.After(0.3, function() private.HideReward() end)
     end
end

function private.Initialize(event, isInitialLogin, isReloadingUi)
    if isInitialLogin or isReloadingUi then
        private.setupFactions()
        C_Timer.After(1, function() Addon:UpdateBars() end)
        Addon:InitializeDataBroker()
    end
end

function Addon:Test()
    if not Options.Enabled then return end
    local faction, change = Options.Test.faction, Options.Test.change
    local session = factions[faction].session
    local splash = Options.Splash
    Options.Splash = false
    private.processFaction(faction, change)
    Options.Splash = splash
    factions[faction].session = session
    if factions[faction].info and factions[faction].info.session then
        factions[faction].info.session = session
    end
end

function private.chatCmdShowConfig(input)
    local cmd = Addon:GetArgs(input)
    if not cmd or cmd == "" or cmd == "help" or cmd == "?" then
        local argStr  = "   |cff00ff00/pr %s|r - %s"
        local arg2Str = "   |cff00ff00/pr %s|r or |cff00ff00%s|r - %s"
        Addon:Print("Available Chat Command Arguments")
        print(format(argStr, "config", "Opens configuration window."))
        print(format(argStr, "toggle", "Toggles showing reputation message in chat."))
        print(format(argStr, "enable", "Enables showing reputation message in chat."))
        print(format(argStr, "disable", "Disables showing reputation message in chat."))
        print(format(arg2Str, "help", "?", "Print this again."))
        print(format(argStr, "ver", "Print Addon Version"))
    elseif cmd == "config" then
        -- happens twice because there is a bug in the blizz implementation and the first call doesn't work. subsequent calls do.
        InterfaceOptionsFrame_OpenToCategory(Const.METADATA.NAME)
        InterfaceOptionsFrame_OpenToCategory(Const.METADATA.NAME)
    elseif cmd == "ver" then
        Addon:Print(("You are running version |cff1784d1%s|r."):format(Const.METADATA.VERSION))
    elseif cmd == "toggle" then
        Options.Enabled = not Options.Enabled
        Addon:OnToggle()
    elseif cmd == "enable" then
        Options.Enabled = true
        Addon:OnToggle()
    elseif cmd == "disable" then
        Options.Enabled = false
        Addon:OnToggle()
    end
end

function private.setInterpolateColors()
    local colorIndexLow     = Const.REP_COLOR_INDEX_LOW
    local colorIndexHigh    = Const.REP_COLOR_INDEX_HIGH
    local colorIndexParagon = Const.REP_COLOR_INDEX_PARAGON
    Options.ColorRenownLow  = Options.ColorRenownLow  and next( Options.ColorRenownLow)  and Options.ColorRenownLow  or Options.Colors[colorIndexLow]     or Const.REP_COLORS.wowproColors[colorIndexLow]
    Options.ColorRenownHigh = Options.ColorRenownHigh and next( Options.ColorRenownHigh) and Options.ColorRenownHigh or Options.Colors[colorIndexHigh]    or Const.REP_COLORS.wowproColors[colorIndexHigh]
    Options.ColorFriendLow  = Options.ColorFriendLow  and next( Options.ColorFriendLow)  and Options.ColorFriendLow  or Options.Colors[colorIndexLow]     or Const.REP_COLORS.wowproColors[colorIndexLow]
    Options.ColorFriendHigh = Options.ColorFriendHigh and next( Options.ColorFriendHigh) and Options.ColorFriendHigh or Options.Colors[colorIndexHigh]    or Const.REP_COLORS.wowproColors[colorIndexHigh]
    Options.ColorParagon    = Options.ColorParagon    and next( Options.ColorParagon)    and Options.ColorParagon    or Options.Colors[colorIndexParagon] or Const.REP_COLORS.wowproColors[colorIndexParagon]
end

function Addon:OnToggle()
    Addon:UpdateDataBrokerText()
    Addon:SetBarsOptions()
    if Options.Enabled then
        Addon:Print(Const.MESSAGE_COLORS.POSITIVE .. "Enabled|r")
    else
        Addon:Print(Const.MESSAGE_COLORS.NEGATIVE .. "Disabled|r")
    end
end

function Addon:OnInitialize()
    Addon:RegisterChatCommand("pr", private.chatCmdShowConfig)
end

function Addon:RefreshConfig()
    Options = self.db.profile
    private.setInterpolateColors()
end

function Addon:OnEnable()
    Addon.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", AddonDB_Defaults, true)
    Options = Addon.db.profile
    private.setInterpolateColors()

    Addon:RegisterEvent("PLAYER_ENTERING_WORLD", private.Initialize)
    Addon:RegisterEvent("COMBAT_TEXT_UPDATE", private.CombatTextUpdated)
    Addon:RegisterEvent("SHOW_LOOT_TOAST", private.LootToast)
    Addon:RegisterEvent("QUEST_TURNED_IN", private.UpdateReward)

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function Addon:OnDisable()
    Addon:UnregisterEvent("QUEST_TURNED_IN")
    Addon:UnregisterEvent("COMBAT_TEXT_UPDATE")
end
