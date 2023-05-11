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
        if (tooltip and tooltip.AddLine) then
            tooltip:ClearLines()

            tooltip:AddDoubleLine(Addon.CONST.METADATA.NAME .. " (v" .. Addon.CONST.METADATA.VERSION .. ")", ldbLabelText, 1, 1, 1)
            tooltip:AddLine(" ")

            private.AddSessionGains(tooltip)

            tooltip:AddLine("|cFFFFFFCCRight-Click|r to open the options window")
            tooltip:AddLine("|cFFFFFFCCLeft-Click|r to toggle message visibility")

            tooltip:Show()
        end
    end,
    OnClick = function(self, button, down)
        if button == "LeftButton" then
            Addon.db.profile.Enabled = not Addon.db.profile.Enabled
            Addon:OnToggle()
        end
        if button == "RightButton" then
            InterfaceOptionsFrame_OpenToCategory(Addon.CONST.METADATA.NAME)
            InterfaceOptionsFrame_OpenToCategory(Addon.CONST.METADATA.NAME)
        end
    end,
};

function Addon:UpdateDataBrokerText()
	private.SetLabelText()
end

function private.SetLabelText()
    if Addon.db.profile.Enabled then
        ldbLabelText = Addon.CONST.MESSAGE_COLORS.POSITIVE .. "Enabled" .. "|r"
    else
        ldbLabelText = Addon.CONST.MESSAGE_COLORS.NEGATIVE .. "Disabled" .. "|r"
    end
    Addon.BrokerModule.text = ldbLabelText
end

function private.AddSessionGains(tooltip)
    local sortTooltipBy = Addon.db.profile.TooltipSort
    local lines = {}
    local count = 0
    for k,v in pairs(factions) do
        if v["session"] and v["session"] ~= 0 then
            count = count + 1
            local session = ((v["session"] > 0) and (Addon.CONST.MESSAGE_COLORS.POSITIVE .. "+" .. BreakUpLargeNumbers(v["session"]) .. "|r")) or (Addon.CONST.MESSAGE_COLORS.NEGATIVE  .. BreakUpLargeNumbers(v["session"]) .. "|r")
            lines[k] = {session, v["session"]}
        end
    end
    if count > 0 then
        tooltip:AddLine("Session gains/losses:",1,1,1)

        local keys = {}
        for key in pairs(lines) do
            table.insert(keys, key)
        end
        if sortTooltipBy == "value" then
            table.sort(keys, function(a, b)
                return lines[a][2] > lines[b][2]
            end)
        end
        if sortTooltipBy == "faction" then
            table.sort(keys)
        end
        for _, key in ipairs(keys) do
            tooltip:AddDoubleLine(key, lines[key][1])
        end

        tooltip:AddLine(" ")
    end
end

function Addon:InitializeDataBroker()
    Addon.BrokerModule = LibDataBroker:NewDataObject(ADDON_NAME, settings)
    private.SetLabelText()
    Addon.icon = LibStub("LibDBIcon-1.0")
    Addon.icon:Register(Addon.CONST.METADATA.NAME, Addon.BrokerModule, Addon.db.profile.minimapIcon)
    if Addon.db.profile.minimapIcon.hide then
        Addon.icon:Hide(Addon.CONST.METADATA.NAME)
    else
        Addon.icon:Show(Addon.CONST.METADATA.NAME)
    end
    if Addon.db.profile.AddonCompartment.hide then
        if Addon.icon:IsButtonInCompartment(Addon.CONST.METADATA.NAME) then
            Addon.icon:RemoveButtonFromCompartment(Addon.CONST.METADATA.NAME)
        end
    else
        if not Addon.icon:IsButtonInCompartment(Addon.CONST.METADATA.NAME) then
            Addon.icon:AddButtonToCompartment(Addon.CONST.METADATA.NAME)
        end
    end
end
