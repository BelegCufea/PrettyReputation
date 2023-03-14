local Addon = select(2, ...)
local LSM = LibStub("LibSharedMedia-3.0")
local Bars = Addon:NewModule("Bars", "LibBars-1.0")
Addon.Bars = Bars

local factions = Addon.Factions
local Debug = Addon.DEBUG
local Const = Addon.CONST
local Options
local BarsGroup

local function BarSortOrder(a, b)
	if not a.sort then return true end
	if not b.sort then return false end
	return a.sort < b.sort
end

function Bars:Update()
    if not Options.Bars.enabled then return end
    for k,v in pairs(factions) do
        if v.info and v.info.name and v.info.session and v.info.session ~= 0 then
            local bar = v.bar
            if not bar then
                bar = BarsGroup:NewCounterBar("PABars" .. v.info.factionId, nil, 0, 100)
                UIFrameFadeIn(bar, 0.5, 0, Options.Bars.alpha)
                v.bar = bar
             end

             if Options.Bars.sort == "session" then
                bar.sort = v.info.session
             elseif Options.Bars.sort == "overall" then
                bar.sort = v.info.bottom + v.info.current
             elseif Options.Bars.sort == "recent" then
                bar.sort = v.info.lastUpdated
             else
                bar.sort = v.info.faction
             end
             Debug:Info(Options.Bars.sort, "optionssort")
             Debug:Info(bar.sort, "barsort")

             if v.info.icon and v.info.icon ~= "" then
                bar:SetIcon(v.info.icon)
             else
                bar:HideIcon()
             end
             bar:UnsetAllColors()
             bar:SetColorAt(0, v.info.color.r, v.info.color.g, v.info.color.b, 1)

             local session = ((v.info.session > 0) and (Addon.CONST.MESSAGE_COLORS.POSITIVE .. "+" .. BreakUpLargeNumbers(v.info.session) .. "|r")) or (Addon.CONST.MESSAGE_COLORS.NEGATIVE  .. BreakUpLargeNumbers(v.info.session) .. "|r")

             bar:SetValue(v.info.current, v.info.maximum)

             local faction = string.format("%s (%s / %s)", v.info.name, BreakUpLargeNumbers(v.info.current), BreakUpLargeNumbers(v.info.maximum))

             bar:SetLabel(faction)
             bar:SetTimerLabel(session)
        end
        if v.info and v.info.name and v.info.session and v.info.session == 0 and v.bar then
            BarsGroup:RemoveBar(v.bar)
            v.bar = nil
        end
    end
    Debug:Info(BarsGroup, "BarsGroup", "VDT")
    BarsGroup:SortBars()
end

local function LoadPosition()
	local x, y = Options.Bars.posx, Options.Bars.posy
	local s = BarsGroup:GetEffectiveScale()
	BarsGroup:ClearAllPoints()
	BarsGroup:SetPoint("TOPLEFT", x/s, y/s)
end

local function SavePosition()
	local x, y = 0,0
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

    LoadPosition()

    if Options.Bars.locked then
		BarsGroup:Lock()
		BarsGroup:HideAnchor()
	else
		BarsGroup:Unlock()
		BarsGroup:ShowAnchor()
	end
end

function Bars:OnEnable()
	Options = Addon.db.profile

	if not BarsGroup then
        BarsGroup = Bars:NewBarGroup("Pretty Reputation Bars", nil, Options.Bars.width, Options.Bars.height, Const.METADATA.NAME .. "_Bars")
	end
    BarsGroup.RegisterCallback(self, "AnchorMoved")
    BarsGroup:SetSortFunction(BarSortOrder)

    Bars:SetOptions()
    BarsGroup:Show()
end

function Bars:OnDisable()
	if BarsGroup then
		BarsGroup:Hide()
	end
end


