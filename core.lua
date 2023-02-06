local ADDON_NAME = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0");

local GetFactionInfoByID = GetFactionInfoByID
local GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation
local IsMajorFaction = C_Reputation.IsMajorFaction
local GetMajorFactionData = C_MajorFactions.GetMajorFactionData
local HasMaximumRenown = C_MajorFactions.HasMaximumRenown
local IsFactionParagon = C_Reputation.IsFactionParagon

local private = {}
local factions = {}
Addon.Factions = factions

local AddonDB_Defaults = {
    profile = {
        Enabled = true,
        Reputation = {
            pattern = "[name] ([c_standing]): [c_change]/[c_session] ([currentPercent]) [bar]",
            barChar = "||",
            barLength = 20,
            showParagonCount = true
        },
        Colors = Addon.CONST.REP_COLORS.wowproColors,
        ColorsPreset = "wowpro",
        minimapIcon = { hide = false, minimapPos = 220, radius = 80, },
        Debug = false,
    }
}

local function SaveRepHeaders()
    local collapsed = {}
	for i = GetNumFactions(), 1, -1 do
		local name, _, _, _, _, _, _, _, isHeader, isCollapsed, _, _, _, factionId = GetFactionInfo(i)
		if (factionId == nil) then factionId = name	end

		if isHeader and isCollapsed then
            ExpandFactionHeader(i)
            collapsed[factionId] = true
		end
	end
    ExpandAllFactionHeaders() -- to be sure
    return collapsed
end

local function RestoreRepHeaders(collapsed)
	for i = GetNumFactions(), 1, -1 do
		local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionId = GetFactionInfo(i)
		if (factionId == nil) then factionId = name	end

		if isHeader and collapsed[factionId] then
            CollapseFactionHeader(i)
		end
	end
end
local function SetupFactions()
    local collapsedHeaders = SaveRepHeaders() -- please make all factions visible
    for i=1, 500 do -- to be sure thogh it may be safe to use GetNumFactions()
        local name, _, _, _, _, _, _, _, _, _, _, _, _, factionId = GetFactionInfo(i)
        local nextName = GetFactionInfo(i + 1)
        if name == nextName and nextName ~= "Guild" then break end -- bugfix
        if (name) then
            if (factionId) and not factions[name] then
                factions[name] = { id = factionId, session = 0}
            elseif (factionId) and not factions[name].id then
                factions[name].id = factionId
            end
        else
            break
        end
    end
    -- Add watched faction if not already there (just in case)
    local name, _, _, _, _, factionId = GetWatchedFactionInfo()
    if factionId and name then
        if (factionId) and not factions[name] then
            factions[name] = { Id = factionId, session = 0}
        elseif (factionId) and not factions[name].id then
            factions[name].id = factionId
        end
    end
    RestoreRepHeaders(collapsedHeaders) -- restore collapsed faction headers
end

local SEX = UnitSex("player")
local function GetFactionLabel(standingId)
	if standingId == "paragon" then
		return "Paragon"
	end
	if (standingId == "renown") then
		return "Renown"
	end
	return GetText("FACTION_STANDING_LABEL" .. standingId, SEX)
end

local function GetRepInfo(info)
    local reputationColors = Addon.db.profile.Colors
    local showParagonCount = Addon.db.profile.Reputation.showParagonCount
    local name, standingId, bottomValue, topValue, barValue

    if (info.factionId and info.factionId ~= 0) then
        name, _, standingId, bottomValue, topValue, barValue = GetFactionInfoByID(info.factionId)
        info["standingId"] = standingId
        info["name"] = name
        info["bottom"] = bottomValue
        info["top"] = topValue
        info["paragon"] = ""
        info["renown"] = ""

        if (IsMajorFaction(info.factionId)) then
            info["color"] = reputationColors[10]
			local data = GetMajorFactionData(info.factionId)
			local isCapped = HasMaximumRenown(info.factionId)
            if data then
                info["current"] = isCapped and data.renownLevelThreshold or data.renownReputationEarned or 0
                info["maximum"] = data.renownLevelThreshold
                info["standingText"] = (RENOWN_LEVEL_LABEL .. data.renownLevel)
                info["renown"] = data.renownLevel
                if not isCapped then
                    return info
                end

                local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(info.factionId);
                local paragonLevel = (currentValue - (currentValue % threshold))/threshold
                if showParagonCount then
                    info["paragon"] =  info["paragon"] .. paragonLevel+1
                end
                if hasRewardPending then
                    local reward = "|A:ParagonReputation_Bag:0:0|a"
                    info["paragon"] = info["paragon"] .. reward
                    if not showParagonCount then
                        info["standingText"] = info["standingText"] .. " " .. reward
                    end
                end
                info["current"] = mod(currentValue, threshold)
                info["maximum"] = threshold
                return info
            else
                info["current"] = 0
                info["maximum"] = 0
                info["standingText"] = RENOWN_LEVEL_LABEL
                return info
            end
		end

		if (standingId == nil) then
            info["current"] = 0
            info["maximum"] = 0
            info["color"] = {r = 1, b = 0, g = 0}
            info["standingText"] = "??? - " .. (info.factionId .. "?")
            info["bottom"] = 0
            info["top"] = 0
			return info
		end

		if (IsFactionParagon(info.factionId)) then
			info["color"] = reputationColors[9]
			local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(info.factionId);
			local paragonLevel = (currentValue - (currentValue % threshold))/threshold
			info["standingText"] = GetFactionLabel("paragon")
			if showParagonCount then
                info["paragon"] =  info["paragon"] .. paragonLevel+1
            end
			if hasRewardPending then
                local reward = "|A:ParagonReputation_Bag:0:0|a"
                info["paragon"] =  info["paragon"] .. reward
                if not showParagonCount then
                    info["standingText"] = info["standingText"] .. " " .. reward
                end
			end
            info["current"] = mod(currentValue, threshold)
            info["maximum"] = threshold
			return info
		end

		local friendInfo = GetFriendshipReputation(info.factionId)
		if (friendInfo.friendshipFactionID and friendInfo.friendshipFactionID ~= 0) then
            info["current"] = 1
			info["maximum"] = 1
			info["color"] = reputationColors[standingId] or reputationColors[5]
			info["standingText"] = friendInfo.reaction
			if (friendInfo.nextThreshold) then
                info["current"] = friendInfo.standing - friendInfo.reactionThreshold
				info["maximum"] = friendInfo.nextThreshold - friendInfo.reactionThreshold
			end
			return info
		end

        info["current"] = barValue - bottomValue
        info["maximum"] = topValue - bottomValue
        info["color"] = reputationColors[standingId] or reputationColors[5]
        info["standingText"] = GetFactionLabel(standingId)
        return info
	end
end

local function GetFactionInfo(info)
    if factions[info.faction] then
        local factionId = factions[info.faction].id
        info["factionId"] = factionId
        local session = factions[info.faction] and (factions[info.faction].session + (info.change * ((info.negative and -1 or 1)))) or 0
        factions[info.faction].session = session
        info["session"] = session
        if Addon.db.profile.Enabled then
            local info = GetRepInfo(info)
            if info.color then
                info["standingColor"] = ("|cff%.2x%.2x%.2x"):format(info.color.r*255, info.color.g*255, info.color.b*255)
            end
        end
    end
    return info
end

local function ConstructMessage(info)
    if info == nil or info.name == nil then
        return "Faction not found - " .. info.faction .. " [change: " .. (info.negative and "-" or "+") .. info.change .. ", session: " .. info.session .. "]"
    end

    local message = Addon.db.profile.Reputation.pattern

    -- Debug
    if info.debug then
        message = ""
        local tkeys = {}
        -- populate the table that holds the keys
        for k in pairs(Addon.TAGS.Definition) do table.insert(tkeys, k) end
        -- sort the keys
        table.sort(tkeys)
        -- use the keys to retrieve the values in the sorted order
        for _, k in ipairs(tkeys) do
            message = message .. Addon.CONST.CONFIG_COLORS.TAG .. k .. "|r: [" .. Addon.TAGS.Definition[k].value(info) .. "], "
        end
        return message
    end

    for k,v in pairs(Addon.TAGS.Definition) do
        if string.find(message, "%[" .. k .. "%]") then
            message = string.gsub(message, "%[" .. k .. "%]", v.value(info))
        end
    end

    return message
end

local function PrintReputation(info)
    if info.name then
        print(ConstructMessage(info))
    else
        Addon:Print(ConstructMessage(info))
    end

    if Addon.db.profile.Debug then
        info["debug"] = true
        Addon:Print(ConstructMessage(info))
    end
end

local fsInc = FACTION_STANDING_INCREASED:gsub("%%d", "([0-9]+)"):gsub("%%s", "(.*)")
local fsInc2 = FACTION_STANDING_INCREASED_ACH_BONUS:gsub("%%d", "([0-9]+)"):gsub("%%s", "(.*)"):gsub(" %(%+.*%)" ,"")
local fsInc3 = FACTION_STANDING_INCREASED_GENERIC:gsub("%%s", "(.*)"):gsub(" %(%+.*%)" ,"")
local fsDec = FACTION_STANDING_DECREASED:gsub("%%d", "([0-9]+)"):gsub("%%s", "(.*)")
function private.ReputationChanged(eventName, msg)
    msg = msg:gsub(" %(%+.*%)" ,"")
    local faction, value, neg, updated = msg:match(fsInc)
    if not faction then
        faction, value, neg, updated = msg:match(fsInc2)
        if not faction then
            faction = msg:match(fsInc3)
            if not faction then
                faction, value = msg:match(fsDec)
                if not faction then return end
                neg = true
            end
        end
    end
    if tonumber(faction) then faction, value = value, tonumber(faction) else value = tonumber(value) end

    local info = {}

    info["faction"] = faction
    info["negative"] = neg
    info["change"] = value

    if factions[info.faction] == nil then
        Addon:ScheduleTimer(function()
            SetupFactions()
            GetFactionInfo(info)
            PrintReputation(info)
            -- Debug
            if Addon.db.profile.Debug then
                Addon:Print("New Faction " .. info.faction .. ((factions[info.faction].id and " found") or " not found"))
            end
        end, 1)
    else
        GetFactionInfo(info)
        PrintReputation(info)
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
        print(format(argStr, "version", "ver", "Print Addon Version"))
    elseif cmd == "config" then
        -- happens twice because there is a bug in the blizz implementation and the first call doesn't work. subsequent calls do.
        InterfaceOptionsFrame_OpenToCategory(Addon.CONST.METADATA.NAME)
        InterfaceOptionsFrame_OpenToCategory(Addon.CONST.METADATA.NAME)
    elseif cmd == "version" or cmd == "ver" then
        Addon:Print(("You are running version |cff1784d1%s|r."):format(Addon.CONST.METADATA.VERSION))
    elseif cmd == "toggle" then
        Addon.db.profile.Enabled = not Addon.db.profile.Enabled
        Addon:UpdateDataBrokerText()
    elseif cmd == "enable" then
        Addon.db.profile.Enabled = true
        Addon:UpdateDataBrokerText()
    elseif cmd == "disable" then
        Addon.db.profile.Enabled = false
        Addon:UpdateDataBrokerText()
    end
end

function Addon:OnInitialize()
    Addon:RegisterChatCommand("pr", private.chatCmdShowConfig)
end

function Addon:OnEnable()
    SetupFactions()
    Addon:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE", private.ReputationChanged)
    Addon.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", AddonDB_Defaults, true) -- set true to prefer 'Default' profile as default
    Addon:InitializeDataBroker()
end
