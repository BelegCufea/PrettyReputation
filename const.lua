local Addon = select(2, ...)

local CONST = {}
Addon.CONST = CONST

CONST.PATTERN = "[name] ([c_standing]): [c_change]/[c_session] ([currentPercent]) [bar]"

CONST.CONFIG_COLORS = {
    TAG = "|cffd4756a"
}

CONST.MESSAGE_COLORS = {
    NAME = '|cffbbbbff',
    BAR_FULL = '|cff00ff00',
    BAR_EMPTY = '|cff666666',
    BAR_EDGE = '|cff00ffff',
    POSITIVE = '|cff00ff00',
    NEGATIVE = '|cffff0000'
}

CONST.REP_COLORS = {
    blizzardColors = FACTION_BAR_COLORS,  --hack to add back Blizzard colors
    asciiColors = {
        [1]   = { r= .54, g= 0,   b= 0   }, -- hated
        [2]   = { r= 1,   g= .10, b= .1  }, -- hostile
        [3]   = { r= 1,   g= .55, b= 0   }, -- unfriendly
        [4]   = { r= .87, g= .87, b= .87 }, -- neutral
        [5]   = { r= 1,   g= 1,   b= 0   }, -- friendly
        [6]   = { r= .1,  g= .9,  b= .1  }, -- honored
        [7]   = { r= .25, g= .41, b= .88 }, -- revered
        [8]   = { r= .6,  g= .2,  b= .8  }, -- exalted
        [9]   = { r= .4,  g= 0,   b= .6  }, -- paragon
        [10]  = { r= 0,   g= .75, b= .94 }, -- renown
    }
}

CONST.REP_STANDING = {
    FACTION_STANDING_LABEL1, -- Hated
    FACTION_STANDING_LABEL2, -- Hostile
    FACTION_STANDING_LABEL3, -- Unfriendly
    FACTION_STANDING_LABEL4, -- Neutral
    FACTION_STANDING_LABEL5, -- Friendly
    FACTION_STANDING_LABEL6, -- Honored
    FACTION_STANDING_LABEL7, -- Revered
    FACTION_STANDING_LABEL8, -- Exalted
    "Paragon", -- Paragon
    RENOWN_LEVEL_LABEL, -- Renown
}