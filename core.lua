local ADDON_NAME = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0");

local GetFactionInfoByID = GetFactionInfoByID
local GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation
local IsMajorFaction = C_Reputation.IsMajorFaction
local GetMajorFactionData = C_MajorFactions.GetMajorFactionData
local HasMaximumRenown = C_MajorFactions.HasMaximumRenown
local IsFactionParagon = C_Reputation.IsFactionParagon

local reputationColors = FACTION_BAR_COLORS

local private = {}
local factionsId = {}

local function SetupFactions()
    for i=1, GetNumFactions() do
        local name, _, _, _, _, earnedValue, _, _, _, _, _, isWatched, _, factionId = GetFactionInfo(i)
        if (name) then
            if (factionId) and not factionsId[name] then
                factionsId[name] = factionId
            end
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
    local name, standingId, bottomValue, topValue, barValue
    if (factionId and factionId ~= 0) then
        name, _, standingId, bottomValue, topValue, barValue = GetFactionInfoByID(factionId)

        if (IsMajorFaction(factionId)) then
			local data = GetMajorFactionData(factionId)
			local isCapped = HasMaximumRenown(factionId)
			local current = isCapped and data.renownLevelThreshold or data.renownReputationEarned or 0
			local standingText = (RENOWN_LEVEL_LABEL .. data.renownLevel)
            return name, current, data.renownLevelThreshold, reputationColors[10], standingText      
		end

		if (standingId == nil) then
			return name, "0", "0", "|cFFFF0000", "??? - " .. (factionId .. "?")
		end

		if (IsFactionParagon(factionId)) then
			local color = reputationColors[9]
			local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionId);
			local paragonLevel = (currentValue - (currentValue % threshold))/threshold
			local standingText = GetFactionLabel("paragon") .. " " .. paragonLevel+1
			if hasRewardPending then
				if standingText then 
					standingText = standingText .. " |A:ParagonReputation_Bag:0:0|a" 
				else
					standingText = GetFactionLabel("paragon") .. " |A:ParagonReputation_Bag:0:0|a" 
				end
			end
			return name, mod(currentValue, threshold), threshold, color, standingText
		end

		local friendInfo = GetFriendshipReputation(factionId)
		if (friendInfo.friendshipFactionID and friendInfo.friendshipFactionID ~= 0) then
			local standingText = friendInfo.reaction
			local color = reputationColors[standingId] or reputationColors[5]
			local maximun, current = 1, 1
			if (friendInfo.nextThreshold) then
				maximun, current = friendInfo.nextThreshold - friendInfo.reactionThreshold, friendInfo.standing - friendInfo.reactionThreshold
			end
			return name, current, maximun, color, standingText
		end

        local current = barValue - bottomValue
        local maximun = topValue - bottomValue
        local color = reputationColors[standingId] or reputationColors[5]
        local standingText = GetFactionLabel(standingId)
        return name, current, maximun, color, standingText
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

    local factionId = factionsId[faction]
    if not factionId then
        SetupFactions()
        factionId = factionsId[faction]
    end
    local name, current, maximum, color, standingText = GetRepInfo(factionId)
    if name then
        local standingColor = ("|cff%.2x%.2x%.2x"):format(color.r*255, color.g*255, color.b*255)
        local percent = current * 100 / maximum
        if (maximum == 0) then
            percent = 100
        end
        local bar = "||||||||||||||||||||||||||||||||||||||||";
        local GREY_COLOR = '|cff666666';
        local GREEN_COLOR = '|cff00ff00';
        local CYAN_COLOR = '|cff00ffff';
        local percentBar = math.floor(percent / 5); -- for 20 "||" to avoid split escape string
        local percentBarText =  GREEN_COLOR .. string.sub(bar, 0, percentBar * 2) .. GREY_COLOR .. string.sub(bar, percentBar * 2 + 1);
        print(("|cffbbbbff%s|r (%s%s|r): %s%d (%.1f%%) " .. CYAN_COLOR .. "[%s" .. CYAN_COLOR .. "]"):format(
            name,
            standingColor,
            standingText,
            neg and "-" or "+",
            value,
            percent,
            percentBarText
        ))
    end
end

function Addon:OnInitialize()
    SetupFactions()
end

function Addon:OnEnable()
	self:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE", private.ReputationChanged)
end
