local Addon = select(2, ...)

-- A thin reputation bar under the Broker text in EllesmereUI's data bars.
-- EUI's Broker Plugin block only renders text, so the bar is hung on it from
-- outside: find the block's button inside EUI's named data bars
-- (EllesmereUIDataBarsBar<id>) by the text it shows, then add a track and a
-- progress texture under the label. EUI keeps owning the layout; we only nudge
-- the label up to make room. The progress is coloured like [c_bar] (the
-- faction's standing colour from the Colors options).
-- Ported from EUI_CufeaTweaks' Broker/BarOverlay.lua.

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded

local WHITE = "Interface\\Buttons\\WHITE8X8"
local EUI_DATABARS = "EllesmereUIDataBars"

local private = {}
-- label FontString -> decoration; one label must only ever carry one set of hooks
local decorated = setmetatable({}, { __mode = "k" })
local lastText, lastInfo

function Addon:IsEUIDataBarsLoaded()
    return IsAddOnLoaded(EUI_DATABARS) and true or false
end

-- EUI shows "Label: text" when the block's Show Label option is on
function private.Matches(want, shown)
    if type(shown) ~= "string" or type(want) ~= "string" or want == "" then return false end
    return shown == want or shown:sub(-(#want + 2)) == ": " .. want
end

function private.Wanted()
    local info = lastInfo
    return Addon.db.profile.Broker.euiBar and Addon:IsEUIDataBarsLoaded()
        and info ~= nil and info.color ~= nil and (info.maximum or 0) > 0
end

function private.Kids(f)
    return f and f.GetChildren and { f:GetChildren() } or {}
end

function private.FindBlockTexts(want)
    local found = {}
    for id = 1, 64 do
        local bar = _G["EllesmereUIDataBarsBar" .. id]
        if bar then
            for _, slot in ipairs(private.Kids(bar)) do
                for _, content in ipairs(private.Kids(slot)) do
                    for _, btn in ipairs(private.Kids(content)) do
                        if btn.GetObjectType and btn:GetObjectType() == "Button" then
                            for _, r in ipairs({ btn:GetRegions() }) do
                                if r.GetObjectType and r:GetObjectType() == "FontString" and private.Matches(want, r:GetText()) then
                                    found[#found + 1] = { button = btn, text = r }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return found
end

function private.Hide(d)
    d.track:Hide()
    d.fill:Hide()
    if d.shift ~= 0 then d.shift = 0; d.Reanchor() end
end

function private.Paint(d)
    local info = lastInfo
    local text = d.text
    local _, size = text:GetFont()
    size = size or 13
    -- same proportion as EUI's own XP strip (font 0.4333, strip 0.2 of the base)
    local h = math.max(2, math.floor(size * 0.2 / 0.4333 + 0.5) - 1)
    local shift = math.floor((h + 2) / 2 + 0.5)
    if d.shift ~= shift then d.shift = shift; d.Reanchor() end

    local width = math.max(20, text:GetStringWidth() or 20)
    d.track:ClearAllPoints()
    d.track:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -2)
    d.track:SetSize(width, h)
    d.track:Show()

    local progress = math.max(0, math.min(1, (info.current or 0) / info.maximum))
    local w = width * progress
    d.fill:ClearAllPoints()
    d.fill:SetPoint("TOPLEFT", d.track, "TOPLEFT", 0, 0)
    d.fill:SetSize(math.max(0.001, w), h)
    d.fill:SetVertexColor(info.color.r or 1, info.color.g or 1, info.color.b or 1, 1)
    d.fill:SetShown(w > 0)
end

function private.Repaint(d)
    if private.Matches(lastText, d.text:GetText()) and private.Wanted() then
        private.Paint(d)
    else
        private.Hide(d)
    end
end

function private.Decorate(btn, text)
    local d = decorated[text]
    if d then return d end
    d = { button = btn, text = text, shift = 0 }
    d.track = btn:CreateTexture(nil, "BACKGROUND")
    d.track:SetColorTexture(1, 1, 1, 0.1)
    d.track:Hide()
    d.fill = btn:CreateTexture(nil, "ARTWORK")
    d.fill:SetTexture(WHITE)
    d.fill:Hide()
    -- Horizontal bars centre the label in the block; lift it by half the bar
    -- so label + bar sit centred together. EUI's own SetPoint on this label is
    -- a wrapper adding the block's Text X/Y Offset, so re-anchor from EUI's
    -- ORIGINAL arguments (remembered here) through that same wrapper: the
    -- offset is applied exactly once.
    local busy = false
    local function Apply()
        local a = d.lastArgs
        if not a or a[1] ~= "LEFT" or type(a[2]) == "number" then return end
        busy = true
        text:SetPoint(a[1], a[2], a[3], a[4] or 0, (a[5] or 0) + (d.shift or 0))
        busy = false
    end
    hooksecurefunc(text, "SetPoint", function(_, point, rel, relPoint, x, y)
        if busy then return end
        d.lastArgs = { point, rel, relPoint, x, y }
        if d.shift and d.shift ~= 0 then Apply() end
    end)
    -- EUI re-sets the label on every block refresh (hover, font or bar changes)
    hooksecurefunc(text, "SetText", function()
        local ok, err = pcall(private.Repaint, d)
        if not ok then geterrorhandler()(err) end
    end)
    d.Reanchor = function()
        if d.lastArgs then Apply(); d.rawShift = nil; return end
        -- hooked after EUI's last layout, so no original arguments yet: nudge the
        -- live anchor with the widget's own SetPoint; EUI's next refresh replaces it
        local point, rel, relPoint, x, y = text:GetPoint(1)
        if point ~= "LEFT" then return end
        local raw = getmetatable(text).__index.SetPoint
        local delta = (d.shift or 0) - (d.rawShift or 0)
        if delta == 0 then return end
        busy = true
        raw(text, point, rel, relPoint, x, (y or 0) + delta)
        busy = false
        d.rawShift = d.shift
    end
    decorated[text] = d
    return d
end

function private.Update(text, info)
    lastText, lastInfo = text, info
    local any = false
    for fs, d in pairs(decorated) do
        private.Repaint(d)
        if private.Matches(text, fs:GetText()) and fs:IsVisible() then any = true end
    end
    if not any and private.Wanted() then
        for _, hit in ipairs(private.FindBlockTexts(text)) do
            private.Repaint(private.Decorate(hit.button, hit.text))
        end
    end
end

-- Call after setting the broker's text; info is the shown faction's info (nil for none)
function Addon:UpdateEUIBrokerBar(text, info)
    if not next(decorated) and not Addon:IsEUIDataBarsLoaded() then return end
    local ok, err = pcall(private.Update, text, info)
    if not ok then geterrorhandler()(err) end
end
