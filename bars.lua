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
    local cutBeginningWith = ' - '
    if name:find(cutBeginningWith, 1, true) then
        name = name:match("^(.-) %-%s.*$")
    end

    return name
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

            local session = ((v.info.session > 0) and (Addon.CONST.MESSAGE_COLORS.POSITIVE .. "+" .. BreakUpLargeNumbers(v.info.session) .. "|r")) or (Addon.CONST.MESSAGE_COLORS.NEGATIVE  .. BreakUpLargeNumbers(v.info.session) .. "|r")

            bar:SetValue(v.info.current, v.info.maximum)

            local faction = PrepareFactionName(v.info.name)
            if v.info.renown and v.info.renown ~= "" then
                faction = faction .. " [" .. v.info.renown .. "]"
            end
            if v.info.paragon and v.info.paragon ~= "" then
                faction = faction .. " x" .. v.info.paragon
            end
            if v.info.reward and v.info.reward ~= "" then
                session = session .. v.info.reward
            end
            faction = string.format("%s (%s / %s)", faction, BreakUpLargeNumbers(v.info.current), BreakUpLargeNumbers(v.info.maximum))

            bar:SetLabel(faction)
            bar:SetTimerLabel(session)
        end
        if v.bar and v.info then
            v.bar.sort = BarSort(v.info)
            if v.info.icon and v.info.icon ~= "" then
                v.bar:SetIcon(v.info.icon)
            else
                v.bar:HideIcon()
            end
            v.bar:UnsetAllColors()
            local color = Addon:GetFactionColor(v.info)
            v.bar:SetColorAt(0, color.r, color.g, color.b, 1)
            if (v.info.session == 0) and ((v.info.lastUpdated + 60) < GetTime()) then
                BarsGroup:RemoveBar(v.bar)
                v.bar = nil
            end
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


