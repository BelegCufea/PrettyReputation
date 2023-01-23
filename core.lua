local ADDON_NAME = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0");

local function Setup()
end

function Addon:CHAT_MSG_COMBAT_FACTION_CHANGE(msg)
    print(msg)
end

function Addon:MAJOR_FACTION_RENOWN_LEVEL_CHANGED(factionId, newRenownLevel, oldRenownLevel)
    print(factionId)
end

function Addon:OnInitialize()
    Setup()
end

function Addon:OnEnable()
	self:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
	self:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED")
end
