local ADDON_NAME = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0");

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

local function SetupFactions()
--    for i=1, GetNumFactions() do
    for i=1, 500 do
        local name, _, _, _, _, _, _, _, _, _, _, _, _, factionId = GetFactionInfo(i)
        local nextName = GetFactionInfo(i + 1)
        if name == nextName and nextName ~= "Guild" then break end -- bugfix
        if (name) then
            if (factionId) and not factions[name] then
                factions[name] = { Id = factionId, Session = 0}
            elseif (factionId) and not factions[name].Id then
                factions[name].Id = factionId
            end
        else
            break
        end
    end
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

local function GetRepInfo(factionId)
    local reputationColors = Addon.db.profile.Colors
    local showParagonCount = Addon.db.profile.Reputation.showParagonCount
    local name, standingId, bottomValue, topValue, barValue
    local info = {} -- name, current, maximum, color, standingText, bottom, top, paragon, renown

    if (factionId and factionId ~= 0) then
        name, _, standingId, bottomValue, topValue, barValue = GetFactionInfoByID(factionId)
        info["factionId"] = factionId
        info["standingId"] = standingId
        info["name"] = name
        info["bottom"] = bottomValue
        info["top"] = topValue
        info["paragon"] = ""
        info["renown"] = ""

        if (IsMajorFaction(factionId)) then
            info["color"] = reputationColors[10]
			local data = GetMajorFactionData(factionId)
			local isCapped = HasMaximumRenown(factionId)
            if data then
                info["current"] = isCapped and data.renownLevelThreshold or data.renownReputationEarned or 0
                info["maximum"] = data.renownLevelThreshold
                info["standingText"] = (RENOWN_LEVEL_LABEL .. data.renownLevel)
                info["renown"] = data.renownLevel
                if not isCapped then 
                    return info      
                end
    
                local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionId);
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
            info["standingText"] = "??? - " .. (factionId .. "?")
            info["bottom"] = 0
            info["top"] = 0
			return info
		end

		if (IsFactionParagon(factionId)) then
			info["color"] = reputationColors[9]
			local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionId);
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

		local friendInfo = GetFriendshipReputation(factionId)
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

local function ConstructMessage(info)
    if not info.name then
        return "Faction not found - " .. info.faction .. " [change: " .. (info.negative and "-" or "+") .. info.change .. ", session: " .. info.session .. "]"
    end

    local message = Addon.db.profile.Reputation.pattern

    -- Debug
    if info.debug then
        message = ""
        for k,v in pairs(Addon.TAGS.Definition) do
            message = message .. Addon.CONST.CONFIG_COLORS.TAG .. k .. "|r: [" .. v.value(info) .. "], "
        end
        return message
    end

    for k,v in pairs(Addon.TAGS.Definition) do
        message = string.gsub(message, "%[" .. k .. "%]", v.value(info))
    end

    return message
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

    if factions[faction] == nil then
        factions[faction] = {Id = nil, Session = 0}
        SetupFactions()
        -- Debug
        if Addon.db.profile.Debug then
            Addon:Print("New Faction " .. faction .. ((factions[faction].Id and " found") or " not found"))
        end
    end

    if factions[faction] then
        local factionId = factions[faction].Id
        local session = factions[faction] and (factions[faction].Session + (value * ((neg and -1 or 1)))) or 0
        factions[faction].Session = session
        if Addon.db.profile.Enabled then 
            local info = GetRepInfo(factionId)
            info["negative"] = neg
            info["change"] = value
            info["session"] = session
            info["faction"] = faction
            if info.color then
                info["standingColor"] = ("|cff%.2x%.2x%.2x"):format(info.color.r*255, info.color.g*255, info.color.b*255)
            end
            print(ConstructMessage(info))
            -- Debug
            if Addon.db.profile.Debug then
                info["debug"] = true
                Addon:Print(ConstructMessage(info))
            end
        end
    end
end

function Addon:OnInitialize()
    SetupFactions()
end

function Addon:OnEnable()
	Addon:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE", private.ReputationChanged)
    Addon.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", AddonDB_Defaults, true) -- set true to prefer 'Default' profile as default
    Addon:InitializeDataBroker();
end
