local Addon = select(2, ...)

local CONST = {}
Addon.CONST = CONST

CONST.METADATA = {
    NAME = C_AddOns.GetAddOnMetadata(..., "Title"),
    VERSION = C_AddOns.GetAddOnMetadata(..., "Version")
}

CONST.PATTERN = "[name] ([c_standing]): [c_change]/[c_session] ([currentPercent]) [bar]"

CONST.CONFIG_COLORS = {
    TAG = "|cffd4756a"
}

CONST.MESSAGE_COLORS = {
    NAME = '|cffbbbbff',
    BAR_FULL = '|cff00ff00',
    BAR_EMPTY = '|cff666666',
    BAR_EDGE = '|cff00ffff',
    POSITIVE = '|cff3ce13f',
    NEGATIVE = '|cffff4700'
}

CONST.ICON = {
    CLEAN = "|T%s:%d:%d:0:0:64:64:4:60:4:60:255:255:255|t",
    DEFAULT = "|T%s:%d:%d:0:0:64:64:0:64:0:64:255:255:255|t",
}

CONST.REP_COLORS = {
    blizzardColors = {
        [1]   = FACTION_BAR_COLORS[1],      -- hated
        [2]   = FACTION_BAR_COLORS[2],      -- hostile
        [3]   = FACTION_BAR_COLORS[3],      -- unfriendly
        [4]   = FACTION_BAR_COLORS[4],      -- neutral
        [5]   = FACTION_BAR_COLORS[5],      -- friendly
        [6]   = FACTION_BAR_COLORS[6],      -- honored
        [7]   = FACTION_BAR_COLORS[7],      -- revered
        [8]   = FACTION_BAR_COLORS[8],      -- exalted
        [9]   = { r= 0,   g= .6,  b= .1  }, -- paragon
        [10]  = { r= 0,  g= .75,  b= .94 }, -- renown
    },
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
    },
    wowproColors = {
        [1]   = { r= 204/255, g=  34/255, b=  34/255 }, -- hated
        [2]   = { r= 255/255, g=   0/255, b=   0/255 }, -- hostile
        [3]   = { r= 242/255, g=  96/255, b=   0/255 }, -- unfriendly
        [4]   = { r= 228/255, g= 228/255, b=   0/255 }, -- neutral
        [5]   = { r=  51/255, g= 255/255, b=  51/255 }, -- friendly
        [6]   = { r=  95/255, g= 230/255, b=  93/255 }, -- honored
        [7]   = { r=  83/255, g= 233/255, b= 188/255 }, -- revered
        [8]   = { r=  46/255, g= 230/255, b= 230/255 }, -- exalted
        [9]   = { r= 204/255, g= 102/255, b= 204/255 }, -- paragon
        [10]  = { r=  65/255, g= 105/255, b= 225/255 }, -- renown
    },
    tiptacColors = {
        [1]   = { r= 1,   g= 0,   b= 0   }, -- hated
        [2]   = { r= 1,   g= 0,   b= 0   }, -- hostile
        [3]   = { r= 1,   g= .5,  b= 0   }, -- unfriendly
        [4]   = { r= 1,   g= 1,   b= 0   }, -- neutral
        [5]   = { r= 0,   g= .76, b= 0   }, -- friendly
        [6]   = { r= 0,   g= .76, b= .36 }, -- honored
        [7]   = { r= 0,   g= .76, b= .56 }, -- revered
        [8]   = { r= 0,   g= .76, b= .76 }, -- exalted
        [9]   = { r= 0,   g= .76, b= .76 }, -- paragon
        [10]  = { r= 0,   g= .76, b= .76 }, -- renown
    },
    elvuiColors = {
        [1]   = { r= 255/255, g=   0/255, b=   0/255 }, -- hated
        [2]   = { r= 255/255, g=  99/255, b=  71/255 }, -- hostile
        [3]   = { r= 255/255, g= 165/255, b=   0/255 }, -- unfriendly
        [4]   = { r= 255/255, g= 255/255, b=   0/255 }, -- neutral
        [5]   = { r=   0/255, g= 128/255, b=   0/255 }, -- friendly
        [6]   = { r= 100/255, g= 149/255, b= 237/255 }, -- honored
        [7]   = { r= 138/255, g=  43/255, b= 226/255 }, -- revered
        [8]   = { r= 128/255, g=   0/255, b= 128/255 }, -- exalted
        [9]   = { r= 255/255, g= 105/255, b= 179/255 }, -- paragon
        [10]  = { r=   0/255, g= 189/255, b= 242/255 }, -- renown
    },
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

CONST.REP_COLOR_INDEX_LOW     = 5
CONST.REP_COLOR_INDEX_HIGH    = 10
CONST.REP_COLOR_INDEX_PARAGON = 9

CONST.MAJOR_FACTON_ICONS_OVERRIDE = {
    [2574] = "Denizens",
}