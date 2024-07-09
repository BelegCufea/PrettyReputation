local ADDON_NAME = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "LibSink-2.0")

local GetFactionInfoByID = GetFactionInfoByID
local GetFriendshipReputation = C_GossipInfo.GetFriendshipReputation
local IsMajorFaction = C_Reputation.IsMajorFaction
local GetMajorFactionData = C_MajorFactions.GetMajorFactionData
local HasMaximumRenown = C_MajorFactions.HasMaximumRenown
local IsFactionParagon = C_Reputation.IsFactionParagon
local MAJOR_FACTION_REPUTATION_REWARD_ICON_FORMAT = [[Interface\Icons\UI_MajorFaction_%s]]

local Debug = Addon.DEBUG
local Const = Addon.CONST
local Tags = Addon.TAGS
local Bars = Addon.Bars
local Options

local private = {}
local icons = {}
local factions = {}
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
            patternLeft = "[nc_name][{ |}renownLevelNoParagon{|}][{ x}paragonLevel] ([current] / [next])",
            patternRight = "[c_session]",

        },
        Test = {
            faction = "Darkmoon Faire",
            change = 100,
        },
        Colors = Const.REP_COLORS.wowproColors,
        ColorsPreset = "wowpro",
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
		local name, _, _, _, _, _, _, _, isHeader, isCollapsed, _, _, _, factionId = GetFactionInfo(i)
        if not name or (name == lastName and name ~= GUILD) then break end
        if (factionId == nil) then factionId = name	end
        if isHeader and isCollapsed then
            ExpandFactionHeader(i)
            collapsed[factionId] = true
        end
        lastName = name
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
		local name, _, _, _, _, _, _, _, isHeader, _, _, _, _, factionId = GetFactionInfo(i)
		if (factionId == nil) then factionId = name	end

		if isHeader and collapsed[factionId] then
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

function private.setupFactions()
    local lastName
    local collapsedHeaders = private.saveRepHeaders() -- pretty please make all factions visible
    if next(icons) == nil then private.setupIcons() end -- load FactionAddict Icons
    for i=1, GetNumFactions() do
        local name, _, _, _, _, _, _, _, _, _, _, _, _, factionId = GetFactionInfo(i)
        if not name or (name == lastName and name ~= GUILD) then break end
        if not factions[name] then
            factions[name] = { id = factionId, session = 0}
        end
        if not factions[name].id then
            factions[name].id = factionId
        end
        if not factions[name].session then
            factions[name].session = 0
        end
        if not factions[name].info then
            local info = {}
            info["faction"] = name
            info["factionId"] = factionId
            info["change"] = 0
            info["session"] = factions[name].session
            factions[name].info = private.getRepInfo(info)
        end
        lastName = name
    end
    private.restoreRepHeaders(collapsedHeaders) -- restore collapsed faction headers
end

function private.trackFaction(info)
    if not info then return end
    if info.faction == GetWatchedFactionInfo() then return end
    if info.faction == GUILD and not Options.TrackGuild then return end
    if info.negative and Options.TrackPositive then return end
    local collapsedHeaders = private.saveRepHeaders()
    for i = 1, GetNumFactions() do
        if info.faction == GetFactionInfo(i) then
            SetWatchedFactionIndex(i)
            break
        end
    end
    private.restoreRepHeaders(collapsedHeaders)
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

function Addon:GetFactionColor(info)
    local reputationColors = Options.Colors

    if (info.factionId and info.factionId ~= 0) then
        local _, _, standingId = GetFactionInfoByID(info.factionId)

        if (IsMajorFaction(info.factionId)) then
            if Options.Reputation.paragonColorOverride and IsFactionParagon(info.factionId) then
                return reputationColors[9]
            end
            return reputationColors[10]
		end

		if (standingId == nil) then
            return {r = 1, b = 0, g = 0}
		end

		if (IsFactionParagon(info.factionId)) then
			return reputationColors[9]
		end

		local friendInfo = GetFriendshipReputation(info.factionId)
		if (friendInfo.friendshipFactionID and friendInfo.friendshipFactionID ~= 0) then
			return reputationColors[standingId] or reputationColors[5]

		end
        return reputationColors[standingId] or reputationColors[5]
	end
    return nil
end

function private.getRepInfo(info)
    local showParagonCount = Options.Reputation.showParagonCount
    local name, standingId, bottomValue, topValue, barValue

    if (info.factionId and info.factionId ~= 0) then
        name, _, standingId, bottomValue, topValue, barValue = GetFactionInfoByID(info.factionId)
        info["standingId"] = standingId
        info["name"] = name
        info["bottom"] = bottomValue
        info["top"] = topValue
        info["paragon"] = ""
        info["renown"] = ""
        info["standingTextNext"] = ""
        info["reward"] = ""
        if icons and icons[info.factionId] then
            info["icon"] = icons[info.factionId]
        end

        info["color"] = Addon:GetFactionColor(info)
        if info.color then
            info["standingColor"] = ("|cff%.2x%.2x%.2x"):format(info.color.r*255, info.color.g*255, info.color.b*255)
        else
            info["standingColor"] = ""
        end

        if (IsMajorFaction(info.factionId)) then
            info["isRenown"] = true
			local data = GetMajorFactionData(info.factionId)
			local isCapped = HasMaximumRenown(info.factionId)
            local isParagon = IsFactionParagon(info.factionId)
            if data then
                info["bottom"] = (data.renownLevel - 1) * data.renownLevelThreshold
                info["top"] = data.renownLevel * data.renownLevelThreshold
                info["current"] = isCapped and data.renownLevelThreshold or data.renownReputationEarned or 0
                info["maximum"] = data.renownLevelThreshold
                info["standingText"] = (RENOWN_LEVEL_LABEL .. data.renownLevel)
                info["renown"] = data.renownLevel
                info["standingTextNext"] = RENOWN_LEVEL_LABEL .. (data.renownLevel + 1)
                info["standingId"] = 10
                info["standingIdNext"] = 10
                info["icon"] = MAJOR_FACTION_REPUTATION_REWARD_ICON_FORMAT:format(data.textureKit)
                if not isCapped or not isParagon then
                    return info
                end

                local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(info.factionId)
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
			local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(info.factionId);
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
        return info
		end

		local friendInfo = GetFriendshipReputation(info.factionId)
		if (friendInfo.friendshipFactionID and friendInfo.friendshipFactionID ~= 0) then
            info["current"] = 1
			info["maximum"] = 1
            info["bottom"] = friendInfo.reactionThreshold
            info["top"] = friendInfo.reactionThreshold
			info["standingText"] = friendInfo.reaction
			if (friendInfo.nextThreshold) then
                info["current"] = friendInfo.standing - friendInfo.reactionThreshold
				info["maximum"] = friendInfo.nextThreshold - friendInfo.reactionThreshold
                info["top"] = friendInfo.nextThreshold
			end
			return info
		end

        info["current"] = barValue - bottomValue
        info["maximum"] = topValue - bottomValue
        info["standingText"] = private.getFactionLabel(standingId)
        info["standingTextNext"] = (info.negative and standingId > 1 and _G["FACTION_STANDING_LABEL".. standingId - 1]) or (not info.negative and standingId < 8 and _G["FACTION_STANDING_LABEL".. standingId + 1]) or ""
        info["standingIdNext"] = (info.negative and standingId > 1 and (standingId - 1)) or (not info.negative and standingId < 8 and (standingId + 1))
        return info
	end
    return info
end

function private.getFactionSession(info)
    return factions[info.faction] and (factions[info.faction].session + (info.change * ((info.negative and -1 or 1)))) or 0
end

function private.getFactionInfo(info)
    if factions[info.faction] then
        local factionId = factions[info.faction].id
        info["factionId"] = factionId
        local session = private.getFactionSession(info)
        factions[info.faction].session = session
        info["lastUpdated"] = time()
        info["session"] = session
        if Options.Enabled then
            factions[info.faction].info = private.getRepInfo(info)
        end
    end
    Debug:Table("Factions", factions)
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
        Debug:Table("Info", info)
        local debug = {}
        local tkeys = {}
        for k in pairs(Tags.Definition) do table.insert(tkeys, k) end
        table.sort(tkeys)
        for _, k in ipairs(tkeys) do
            debug[k] = Tags.Definition[k].value(info)
        end
        Debug:Table("Tags", debug)
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
        faction = GetGuildInfo("player")
    end
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

function private.HideReward()
    local updateBars = false
    for k, v in pairs(factions) do
        if v.info and v.info.reward and v.info.reward ~= "" then
            local paragonLevel = 0
            if v.info.paragon then
                paragonLevel = v.info.paragon:match("^%d+")
            end
            local _, _, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(v.info.factionId)
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

function private.UpdateReward(event)
    if Options.Enabled and Options.Bars.enabled then
        C_Timer.After(0.3, function() private.HideReward() end)
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
end

function Addon:OnEnable()
    Addon.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", AddonDB_Defaults, true)
    Options = Addon.db.profile
    private.setupFactions()
    -- Hope it will update :-)
    C_Timer.After(1, function() Addon:UpdateBars() end)

    Addon:InitializeDataBroker()
    Addon:RegisterEvent("COMBAT_TEXT_UPDATE", private.CombatTextUpdated)
    Addon:RegisterEvent("QUEST_TURNED_IN", private.UpdateReward)

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function Addon:OnDisable()
    Addon:UnregisterEvent("QUEST_TURNED_IN")
    Addon:UnregisterEvent("COMBAT_TEXT_UPDATE")
end
