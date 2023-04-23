local Addon = select(2, ...)
local ADDON_NAME = ...
local LSM = LibStub("LibSharedMedia-3.0")
local Bars = Addon:NewModule("Bars", "LibBars-1.0")
Addon.Bars = Bars

local factions = Addon.Factions
local Debug = Addon.DEBUG
local Const = Addon.CONST
local Options
local BarsGroup

local bars = {}
local expiredTimer

local function BarSortOrder(a, b)
    local growUp = Options.Bars.growUp
	if not a.sort then return not growUp end
	if not b.sort then return growUp end
    if growUp then
        return a.sort > b.sort
    else
        return a.sort < b.sort
    end
end

local function BarSort(info)
    if Options.Bars.sort == "session" then
        return -info.session
     elseif Options.Bars.sort == "overall" then
        return -(info.bottom + info.current)
     elseif Options.Bars.sort == "recent" then
        return -info.lastUpdated
     else
        return info.faction
     end
     return nil
end

local function PrepareFactionName(name)
    local cutBeginningWith = " - "
    if name:find(cutBeginningWith, 1, true) then
        name = name:match("^(.-) %-%s.*$")
    end

    return name
end

local function ConstructTooltipAnchor(tooltipAnchor)
    local ofsx = 0
    local ofsy = 0
    if tooltipAnchor == "RIGHT" then
        ofsx = 2
    end
    if tooltipAnchor == "LEFT" then
        ofsx = -2
        if Options.Bars.icon then
            ofsx = ofsx - Options.Bars.height
        end
    end
    if tooltipAnchor == "RIGHT" or tooltipAnchor == "LEFT" then
        if Options.Bars.growUp then
            ofsy = ofsy - Options.Bars.height
        else
            tooltipAnchor = "BOTTOM" .. tooltipAnchor
            ofsy = ofsy + Options.Bars.height
        end
        tooltipAnchor = "ANCHOR_" .. tooltipAnchor
    end
    return tooltipAnchor, ofsx, ofsy
end

local function ShowFactionTooltip(bar)
    if factions[bar.faction] then
        local faction = factions[bar.faction]
        if faction.info and faction.info.name then
            local tooltipAnchor, ofsx, ofsy = ConstructTooltipAnchor(Options.Bars.tooltipAnchor)
            GameTooltip:SetOwner(bar, tooltipAnchor, ofsx, ofsy)
            GameTooltip:AddLine(Const.MESSAGE_COLORS .NAME .. faction.info.name .. "|r")
            GameTooltip:AddLine(" ")
            local standing = faction.info.standingColor .. faction.info.standingText .. "|r"
            local toGo = (faction.info.negative and ("-" .. BreakUpLargeNumbers(faction.info.current)) or BreakUpLargeNumbers((faction.info.maximum - faction.info.current)))
            local timeElapsed = time() - faction.info.lastUpdated
            GameTooltip:AddDoubleLine("Standing:", standing)
            GameTooltip:AddDoubleLine("To next:", toGo)
            GameTooltip:AddDoubleLine("Last change:", string.format("%d:%02d", math.floor(timeElapsed / 60), timeElapsed % 60))
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cFFFFFFCCRight-Click|r to hide")
            GameTooltip:Show()
        end
    end
end

local function HideFactionTooltip(bar)
    GameTooltip:Hide()
end

local function RemoveBar(bar)
    local name = bar.faction
    local faction = factions[name]
    local info =  faction and faction.info
    if info then
        info.lastUpdated = 0
        Bars:RemoveExpired()
    end
end

local function Expired(info)
    local now = time()
    local expired = false
    if Options.Bars.removeAfter == 0 then
        expired = info and ((((info.session or 0) == 0) and ((now - (info.lastUpdated or 0)) >= 60)) or not info.lastUpdated or info.lastUpdated == 0)
    else
        expired = info and ((now - (info.lastUpdated or 0)) >= Options.Bars.removeAfter)
    end

    return expired
end

function Bars:RemoveExpired()
    local needsUpdate = false
    for i = #bars, 1, -1 do
        local name = bars[i]
        local faction = factions[name]
        local info =  faction and faction.info
        local remove = Expired(info)
        if remove then
            if faction.bar then
                needsUpdate = true
                info.lastUpdated = 0
                BarsGroup:RemoveBar(faction.bar)
                faction.bar = nil
                table.remove(bars, i)
            end
        end
    end
    if needsUpdate then
        BarsGroup:SortBars()
        Bars:Update()
    end
end

function Bars:Update()
    if (not Options.Bars.enabled) or (not Options.Enabled) then
            if Bars:IsEnabled() then Bars:Disable() end
    end
    for k,v in pairs(factions) do
        if v.info and v.info.name and v.info.session and v.info.session ~= 0 and not Expired(v.info) then
            local bar = v.bar
            if not bar then
                bar = BarsGroup:NewCounterBar("PABars" .. v.info.factionId, nil, 0, 100)
                UIFrameFadeIn(bar, 0.5, 0, Options.Bars.alpha)
                bar.faction = v.info.faction
                bar:SetScript("OnEnter", function(self) ShowFactionTooltip(self) end)
                bar:SetScript("OnLeave", function(self) HideFactionTooltip(self) end)
                bar:SetScript("OnMouseUp", function(self, button) if button == "RightButton" then RemoveBar(self) end end)
                table.insert(bars, v.info.faction)
                v.bar = bar
            end

            bar:SetValue(v.info.current, v.info.maximum)

            local labelLeft = Addon:ConstructMessage(v.info, Options.Bars.patternLeft)
            local labelRight = Addon:ConstructMessage(v.info, Options.Bars.patternRight)

            bar:SetLabel(labelLeft)
            bar:SetTimerLabel(labelRight)
        end
        if v.bar and v.info then
            v.bar.sort = BarSort(v.info)
            v.bar:SetIcon(v.info.icon)
            v.bar:UnsetAllColors()
            local color = Addon:GetFactionColor(v.info)
            v.bar:SetColorAt(0, color.r, color.g, color.b, 1)
        end
    end
    BarsGroup:SortBars()
end

local function LoadPosition()
	local x, y = Options.Bars.posx, Options.Bars.posy
	local s = BarsGroup:GetEffectiveScale()
	BarsGroup:ClearAllPoints()
	BarsGroup:SetPoint("TOPLEFT", x/s, y/s)
end

local function SavePosition()
	local x, y = 0, 0
	local s = BarsGroup:GetEffectiveScale()
	local l = BarsGroup:GetLeft()
	if l then
		x = l * s
		y = BarsGroup:GetTop() * s - UIParent:GetHeight()*UIParent:GetEffectiveScale()
	end
	Options.Bars.posx = x
	Options.Bars.posy = y
end

function Bars:AnchorMoved(cbk, group, x, y)
	SavePosition()
end

function Bars:SetOptions()
    if Options.Bars.icon then
        BarsGroup:ShowIcon()
    else
        BarsGroup:HideIcon()
    end

    local font = LSM:Fetch("font", Options.Bars.font)
    BarsGroup:SetFont(font,  Options.Bars.fontSize,  Options.Bars.fontOutline)

    local texture = LSM:Fetch("statusbar",  Options.Bars.texture)
    BarsGroup:SetTexture(texture)

    BarsGroup:SetLength(Options.Bars.width)
    BarsGroup:SetThickness( Options.Bars.height)
    BarsGroup:SetAlpha(Options.Bars.alpha)
    BarsGroup:ReverseGrowth(Options.Bars.growUp)

    LoadPosition()

    if Options.Bars.locked then
		BarsGroup:Lock()
		BarsGroup:HideAnchor()
	else
		BarsGroup:Unlock()
		BarsGroup:ShowAnchor()
	end
    if Options.Enabled and Options.Bars.enabled then
        BarsGroup:Show()
    else
        BarsGroup:Hide()
    end
end

function Bars:OnEnable()
	Options = Addon.db.profile

	if not BarsGroup then
        BarsGroup = Bars:NewBarGroup("Pretty Reputation Bars", nil, Options.Bars.width, Options.Bars.height, ADDON_NAME .. "Bars")
        BarsGroup.RegisterCallback(self, "AnchorMoved")
        BarsGroup:SetSortFunction(BarSortOrder)
    end

    Bars:SetOptions()
	if not expiredTimer then
	    expiredTimer = Addon:ScheduleRepeatingTimer(Bars.RemoveExpired, 1)
    end
end

function Bars:OnDisable()
    if BarsGroup then
		BarsGroup:Hide()
	end
	if expiredTimer then
		Addon:CancelTimer(expiredTimer, true)
		expiredTimer = nil
	end
end


