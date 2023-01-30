local Addon = select(2, ...)
local ADDON_NAME = ...

local LibDataBroker = LibStub("LibDataBroker-1.1")
local factions = Addon.Factions

local ldbLabelText = ""
local private = {}

local settings = {
    type = "data source",
    label = ADDON_NAME,
    text = ldbLabelText,
    icon = "Interface\\AddOns\\PrettyReputation\\textures\\icon",
    OnTooltipShow = function(tooltip)
        tooltip:AddDoubleLine(ADDON_NAME, ldbLabelText, 1, 1, 1)
        tooltip:AddLine(" ")
        private.AddSessionGains(tooltip)
        tooltip:AddLine(" ")
		tooltip:AddLine("|cFFFFFFCCRight-Click|r to open the options window")
		tooltip:AddLine("|cFFFFFFCCLeft-Click|r to toggle message visibility")
    end,
    OnClick = function(self, button, down)
        if button == "LeftButton" then
            Addon.db.profile.Enabled = not Addon.db.profile.Enabled
            private.SetLabelText()
        end
        if button == "RightButton" then
            InterfaceOptionsFrame_OpenToCategory(Addon.CONST.METADATA.NAME)
            InterfaceOptionsFrame_OpenToCategory(Addon.CONST.METADATA.NAME)
        end
    end,
};

function private.SetLabelText()
    if Addon.db.profile.Enabled then
        ldbLabelText = Addon.CONST.MESSAGE_COLORS.POSITIVE .. "Enabled" .. "|r"
    else
        ldbLabelText = Addon.CONST.MESSAGE_COLORS.NEGATIVE .. "Disabled" .. "|r"
    end
    Addon.BrokerModule.text = ldbLabelText
end

function private.AddSessionGains(tooltip)
    tooltip:AddLine("Session gains/losses:",1,1,1)
    for k,v in pairs(factions) do
        if v["Session"] and v["Session"] ~= 0 then
            local session = ((v["Session"] > 0) and (Addon.CONST.MESSAGE_COLORS.POSITIVE .. "+" .. v["Session"] .. "|r")) or (Addon.CONST.MESSAGE_COLORS.NEGATIVE  .. v["Session"] .. "|r")
            tooltip:AddDoubleLine(k, session)
        end
    end
end

function Addon:InitializeDataBroker()
    Addon.BrokerModule = LibDataBroker:NewDataObject(ADDON_NAME, settings)
    private.SetLabelText()
    Addon.icon = LibStub("LibDBIcon-1.0")
    Addon.icon:Register(Addon.CONST.METADATA.NAME, Addon.BrokerModule, Addon.db.profile.minimapIcon)
    if Addon.db.profile.minimapIcon.hide == true then
        Addon.icon:Hide(Addon.CONST.METADATA.NAME)
    else
        Addon.icon:Show(Addon.CONST.METADATA.NAME)
    end
end
