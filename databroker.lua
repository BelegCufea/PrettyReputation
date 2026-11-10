local Addon = select(2, ...)
local ADDON_NAME = ...

local LibDataBroker = LibStub("LibDataBroker-1.1")
local QTip = LibStub("LibQTip-1.0")

local GetWatchedFactionData = C_Reputation.GetWatchedFactionData
local SetWatchedFactionByID = C_Reputation.SetWatchedFactionByID

local factions = Addon.Factions
local Const = Addon.CONST

local TOOLTIP_KEY = "PrettyReputationBrokerTooltip"
local COL_SEPARATOR = "%[col([lcr]?)%]" -- [col] and [colr] right, [colc] center, [coll] left
local COL_SEPARATOR_ANY = "%[col[lcr]?%]"
local COL_JUSTIFICATION = { l = "LEFT", c = "CENTER", r = "RIGHT" }
local FAVORITES = "Favorites"
local OTHER = OTHER or "Other"
local ALL = REPUTATION or "Reputation"
local ICON_EXPAND = "|TInterface\\Buttons\\UI-PlusButton-Up:14:14|t "
local ICON_COLLAPSE = "|TInterface\\Buttons\\UI-MinusButton-Up:14:14|t "
local COLOR_GROUP = "|cffffd200"
local COLOR_HINT = "|cFFFFFFCC"
local COLOR_DIM = "|cff808080"

local ldbLabelText = ""
local private = {}
local updatePending = false

local function Options()
    return Addon.db.profile
end

------------------------------------------------------------------------------
-- Broker text
------------------------------------------------------------------------------

-- The broker shows the faction watched in the game (with Auto track that is the last changed one)
function private.GetTextFaction()
    local watched = GetWatchedFactionData()
    if watched and watched.name and watched.factionID and watched.factionID ~= 0 then
        return watched.name, watched.factionID
    end
end

function private.StatusText()
    if Options().Enabled then
        return Const.MESSAGE_COLORS.POSITIVE .. "Enabled|r"
    end
    return Const.MESSAGE_COLORS.NEGATIVE .. "Disabled|r"
end

function private.SetLabelText()
    local options = Options()
    local text
    if options.Broker.textMode == "faction" then
        local name, factionID = private.GetTextFaction()
        local info = name and Addon:GetFreshInfo(name, factionID)
        if info then
            text = Addon:ConstructMessage(info, options.Broker.textPattern):gsub(COL_SEPARATOR_ANY, " ")
            if not options.Enabled then
                text = text .. " " .. COLOR_DIM .. "(off)|r"
            end
        end
    end
    ldbLabelText = text or private.StatusText()
    -- the broker is created a few seconds after login; InitializeDataBroker sets the text then
    if Addon.BrokerModule then
        Addon.BrokerModule.text = ldbLabelText
    end
end

-- coalesce bursts (UPDATE_FACTION fires a lot)
function Addon:UpdateDataBrokerText()
    if updatePending then return end
    updatePending = true
    C_Timer.After(0.2, function()
        updatePending = false
        private.SetLabelText()
    end)
end

------------------------------------------------------------------------------
-- Tooltip helpers
------------------------------------------------------------------------------

-- "[a][col][b][colc][c]" -> { {pattern = "[a]", justification = "LEFT"}, {"[b]", "RIGHT"}, {"[c]", "CENTER"} }
-- The separator sets the alignment of the column it starts; the first column is left aligned.
function private.SplitColumns(pattern)
    local columns = {}
    local start = 1
    local justification = "LEFT"
    while true do
        local s, e, align = pattern:find(COL_SEPARATOR, start)
        if not s then
            columns[#columns + 1] = { pattern = pattern:sub(start), justification = justification }
            break
        end
        columns[#columns + 1] = { pattern = pattern:sub(start, s - 1), justification = justification }
        justification = COL_JUSTIFICATION[align] or "RIGHT"
        start = e + 1
    end
    return columns
end

function private.AddRow(tooltip, columns, info, numColumns)
    local line = tooltip:AddLine()
    for i, column in ipairs(columns) do
        local colSpan = (i == #columns) and (numColumns - i + 1) or 1
        tooltip:SetCell(line, i, Addon:ConstructMessage(info, column.pattern), nil, column.justification, colSpan)
    end
    return line
end

function private.AddFullLine(tooltip, text, numColumns, justification)
    local line = tooltip:AddLine()
    tooltip:SetCell(line, 1, text, nil, justification or "LEFT", numColumns)
    return line
end

function private.IsMaxed(info)
    if not info then return false end
    if info.standingId == 8 then return true end
    if info.isRenown and info.renown and info.maxLevel and info.renown == info.maxLevel and (info.paragon or "") == "" then return true end
    if not info.isRenown and info.level and info.maxLevel and info.maxLevel > 0 and info.level == info.maxLevel then return true end
    return false
end

function private.IsVisible(name, faction)
    local options = Options()
    if not faction.id or faction.isHeader then return false end
    if options.FavoriteFactions[name] then return true end
    if (faction.session or 0) ~= 0 then return true end
    if options.Broker.hideHidden and not faction.order and not faction.special then return false end
    if options.Broker.hideInactive and faction.inactive then return false end
    if options.Broker.hideMaxed and private.IsMaxed(faction.info) then return false end
    return true
end

-- groups in display order: { name, order, entries = { {name, faction}, ... } }
function private.CollectGroups()
    local options = Options()
    local byName = {}
    local groups = {}
    local function GetGroup(groupName, order)
        local group = byName[groupName]
        if not group then
            group = { name = groupName, order = order, entries = {} }
            byName[groupName] = group
            groups[#groups + 1] = group
        elseif order < group.order then
            group.order = order
        end
        return group
    end

    for name, faction in pairs(factions) do
        if private.IsVisible(name, faction) then
            local groupName, order
            if options.Broker.favoritesGroup and options.FavoriteFactions[name] then
                groupName, order = FAVORITES, -1
            elseif options.Broker.grouping == "headers" then
                groupName, order = faction.header or OTHER, faction.order or math.huge
            else
                groupName, order = ALL, 0
            end
            table.insert(GetGroup(groupName, order).entries, { name = name, faction = faction })
        end
    end

    table.sort(groups, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return a.name < b.name
    end)

    local changedFirst = options.Broker.changedFirst
    for _, group in ipairs(groups) do
        table.sort(group.entries, function(a, b)
            if changedFirst then
                local ca, cb = (a.faction.session or 0) ~= 0, (b.faction.session or 0) ~= 0
                if ca ~= cb then return ca end
                if ca and cb and (a.faction.lastChange or 0) ~= (b.faction.lastChange or 0) then
                    return (a.faction.lastChange or 0) > (b.faction.lastChange or 0)
                end
            end
            local oa, ob = a.faction.order or math.huge, b.faction.order or math.huge
            if oa ~= ob then return oa < ob end
            return a.name < b.name
        end)
    end
    return groups
end

function private.IsCollapsed(group, index)
    local stored = Options().Broker.collapsed[group.name]
    if stored ~= nil then return stored end
    -- default: favorites and the first other group (the current expansion on retail) open, the rest closed
    if group.name == FAVORITES then return false end
    return index > 1
end

function private.SessionEntries()
    local options = Options()
    local window = options.Broker.sessionWindow or 0
    local now = time()
    local entries = {}
    for name, faction in pairs(factions) do
        local changed = (faction.session or 0) ~= 0 and (window == 0 or (now - (faction.lastChange or 0)) <= window)
        local favorite = options.Broker.sessionFavorites and options.FavoriteFactions[name]
        if faction.id and (changed or favorite) then
            local info = Addon:GetFreshInfo(name)
            if info then entries[#entries + 1] = { name = name, faction = faction, info = info } end
        end
    end
    local sort = options.Broker.sessionSort
    table.sort(entries, function(a, b)
        if sort == "session" and a.info.session ~= b.info.session then
            return a.info.session > b.info.session
        elseif sort == "overall" then
            local va, vb = (a.info.bottom or 0) + (a.info.current or 0), (b.info.bottom or 0) + (b.info.current or 0)
            if va ~= vb then return va > vb end
        elseif sort == "recent" and (a.faction.lastChange or 0) ~= (b.faction.lastChange or 0) then
            return (a.faction.lastChange or 0) > (b.faction.lastChange or 0)
        end
        return a.name < b.name
    end)
    return entries
end

------------------------------------------------------------------------------
-- Tooltip
------------------------------------------------------------------------------

function private.OnFactionClick(_, entry, button)
    if button == "LeftButton" then
        if entry.faction.id and entry.faction.id ~= Addon:GetDelveFactionID() and not entry.faction.special then
            SetWatchedFactionByID(entry.faction.id)
        end
    elseif button == "RightButton" then
        local favorites = Options().FavoriteFactions
        favorites[entry.name] = not favorites[entry.name]
        Addon:UpdateBars()
    end
    -- watching a faction updates the game data a moment later
    C_Timer.After(0.1, private.RefreshTooltip)
end

function private.OnGroupClick(_, group)
    local options = Options()
    options.Broker.collapsed[group.name] = not group.collapsed
    private.RefreshTooltip()
end

function private.AddSession(tooltip, sessionColumns, numColumns)
    local entries = private.SessionEntries()
    if #entries == 0 then return end
    private.AddFullLine(tooltip, COLOR_GROUP .. "Session gains/losses|r", numColumns)
    for _, entry in ipairs(entries) do
        local line = private.AddRow(tooltip, sessionColumns, entry.info, numColumns)
        tooltip:SetLineScript(line, "OnMouseUp", private.OnFactionClick, entry)
    end
    tooltip:AddSeparator()
end

function private.AddList(tooltip, rowColumns, numColumns)
    local options = Options()
    local groups = private.CollectGroups()
    local showHeaders = not (#groups == 1 and groups[1].name == ALL)
    local watched = GetWatchedFactionData()
    local watchedName = watched and watched.name
    local groupIndex = 0
    for _, group in ipairs(groups) do
        if group.name ~= FAVORITES then groupIndex = groupIndex + 1 end
        group.collapsed = showHeaders and private.IsCollapsed(group, group.name == FAVORITES and 0 or groupIndex)
        if showHeaders then
            local text = (group.collapsed and ICON_EXPAND or ICON_COLLAPSE) .. COLOR_GROUP .. group.name .. "|r"
            if group.collapsed then text = text .. COLOR_DIM .. " (" .. #group.entries .. ")|r" end
            local line = private.AddFullLine(tooltip, text, numColumns)
            tooltip:SetLineScript(line, "OnMouseUp", private.OnGroupClick, group)
        end
        if not group.collapsed then
            for _, entry in ipairs(group.entries) do
                local info = Addon:GetFreshInfo(entry.name)
                if info then
                    local line = private.AddRow(tooltip, rowColumns, info, numColumns)
                    tooltip:SetLineScript(line, "OnMouseUp", private.OnFactionClick, entry)
                    if entry.name == watchedName then
                        tooltip:SetLineColor(line, 1, 1, 1, 0.12)
                    end
                end
            end
        end
    end
    if options.Broker.showList and #groups > 0 then
        tooltip:AddSeparator()
    end
end

function private.FillTooltip(tooltip)
    local options = Options()
    local rowColumns = private.SplitColumns(options.Broker.rowPattern)
    local sessionColumns = private.SplitColumns(options.Broker.sessionPattern)
    local numColumns = math.max(#rowColumns, options.Broker.sessionShow and #sessionColumns or 1, 1)

    tooltip:Clear()
    local justifications = {}
    for i = 1, numColumns do justifications[i] = (i == 1) and "LEFT" or "RIGHT" end
    tooltip:SetColumnLayout(numColumns, unpack(justifications))

    local header = tooltip:AddHeader()
    tooltip:SetCell(header, 1, Const.METADATA.NAME .. " " .. COLOR_DIM .. "v" .. Const.METADATA.VERSION .. "|r  " .. private.StatusText(), nil, "LEFT", numColumns)
    tooltip:AddSeparator()

    if options.Broker.sessionShow and options.Broker.sessionPosition == "top" then
        private.AddSession(tooltip, sessionColumns, numColumns)
    end
    if options.Broker.showList then
        private.AddList(tooltip, rowColumns, numColumns)
    end
    if options.Broker.sessionShow and options.Broker.sessionPosition == "bottom" then
        private.AddSession(tooltip, sessionColumns, numColumns)
    end

    private.AddFullLine(tooltip, COLOR_HINT .. "Click|r a faction to watch it, " .. COLOR_HINT .. "Right-Click|r to toggle favorite", numColumns)
    private.AddFullLine(tooltip, COLOR_HINT .. "Click|r the icon to toggle messages, " .. COLOR_HINT .. "Right-Click|r for options", numColumns)
end

function private.RefreshTooltip()
    if not QTip:IsAcquired(TOOLTIP_KEY) then return end
    local tooltip = QTip:Acquire(TOOLTIP_KEY)
    private.FillTooltip(tooltip)
    tooltip:UpdateScrolling(Options().Broker.maxHeight)
end

function private.ShowTooltip(anchor)
    local tooltip = QTip:Acquire(TOOLTIP_KEY)
    private.FillTooltip(tooltip)
    tooltip:SmartAnchorTo(anchor)
    tooltip:SetAutoHideDelay(0.25, anchor)
    tooltip:Show()
    tooltip:UpdateScrolling(Options().Broker.maxHeight)
end

------------------------------------------------------------------------------
-- Data object
------------------------------------------------------------------------------

local settings = {
    type = "data source",
    label = ADDON_NAME,
    text = ldbLabelText,
    icon = "Interface\\AddOns\\PrettyReputation\\textures\\icon",
    OnEnter = function(self)
        private.ShowTooltip(self)
    end,
    OnLeave = function(self)
        -- the tooltip hides itself (auto-hide), so the mouse can move into it
    end,
    OnClick = function(self, button, down)
        if button == "LeftButton" then
            Addon.db.profile.Enabled = not Addon.db.profile.Enabled
            Addon:OnToggle()
            private.RefreshTooltip()
        end
        if button == "RightButton" then
            Addon:OpenOptions()
        end
    end,
};

function Addon:InitializeDataBroker()
    local options = Options()
    -- the old tooltip sort setting becomes the session sort
    if not options.Broker.sortMigrated then
        if options.TooltipSort == "faction" then options.Broker.sessionSort = "faction" end
        options.Broker.sortMigrated = true
    end

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
