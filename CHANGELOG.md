# v1.1.8a (11.3.2023)

## New
- Added option to show [icon] without border (settings on `Tag options` panel)
- Added TEST on `Tag options` panel

## Fixes
- Fixed missing libraries (thanks Pingumania for reporting)

# v1.1.8 (9.3.2023)

## New
- Added option (in Message tab) to test current settings

# v1.1.7a (6.3.2023)

## New
- Added option to set icon size (0 for text size) for icon TAG

## Fixes
- Fixed edge cases for barTexture TAG

# v1.1.7 (6.3.2023)

## New
- Added [barTexture] and [c_barTexture] TAGs. They are similar to their [bar] counterparts, but they use textures instead of characters. You can choose the texture and modify the overall width and height of the bar.

## Update
- Reorganized some options to be clearer.
- Added current images to ReadMe.

# v1.1.6a (3.3.2023)

## Update
- The [icon] TAG will show icons from [Faction Addict](https://www.curseforge.com/wow/addons/faction-addict) addon if installed and used.

# v1.1.6 (2.3.2023)

## New
- Added the [icon] TAG, which displays the icon of the faction. Currently, it only works for Renown Dragonflight factions.

## Update
- The Output Options for Chatframes have been filtered to only show visible frames.

## Misc
- Debug tweaks have been made, using [ViragDevTool](https://www.curseforge.com/wow/addons/varrendevtool) for complex results.
- Code cleanup has been performed.

# v1.1.5 (15.2.2023)

## New
- Added an option to output the reputation message to multiple chat frames in addition to the selected output (request from Goss444).

## Update
- Streamlined options by rearranging some settings to make them more understandable.
- Changed the behavior of the `standingShort` and `c_standingShort` tags. Now, it is possible to choose the number of letters from each word in the standing text that will be displayed. For example, if you set the number of characters to 3, you will get the following shortened forms: 'Friendly' => 'Fri', 'True Friend' => 'TruFri', 'Revered' => 'Rev', 'Renowned 25' => 'Ren25', and so on. By default, only the first letter of each word is displayed (i.e. 'F', 'TF', 'R', 'R25').

# v1.1.5-beta2 (13.2.2023)

## Updated
- Streamlined the structure of the Options.
- Changed the behavior of the `standingShort` and `c_standingShort` tags. It is now possible to choose the number of letters from each word in the standing text to be displayed. For example, if you set the number of characters to 3, you will get the following: Friendly => Fri, True Friend => TruFri, Revered => Rev, Renowned 25 => Ren25, and so on. If one character is chosen (default), you will get F, TF, R, R25, respectively.

# v1.1.5-beta1 (12.2.2023)

## New

- Added option (to General tab) to output into multiple chat frames

# v1.1.4 (12.2.2023)

## New

- Added option (General tab) to choose the output of reputation message (Chat - default, Floating text, Error message ...). Included option (default false) to always output to chat frame.
- Added few TAGS:
    - more - how many more of current reputation gains (or losses) is needed for next standing
    - c_bar - colored `bar` TAG by standing color
    - standingShort - 1 character (first character) representation of `standing` TAG (renown level is displayed if available)
    - c_standingShort - `standingShort` TAG colored by standing color

# v1.1.3 (10.2.2023)

## New
- Added option to sort factions in tooltip of minimap/broker by session gain/loss or by faction name
- Added more option for auto tracking faction with latest reputation change (exclude loss, exclude guild)

## Update
- Updated structure of config (moved some options to General tab)

# v1.1.2 (9.2.2023)

## Update
- Changed event so it catches that elusive `Cobalt Assembly` faction (let's hope I have not broken EVERYTHING)
- Some more work to maintain collapsed reputation headers in Blizzard UI

# v1.1.1 (7.2.2023)

## New
- Added option to set faction with latest change as watched

## Fixes
- Another try to process new reputations

# v1.1.1-beta1 (6.2.2023)

## New
- Added option to set faction with latest change as watched

## Fixes
- Another try to process new reputations

# v1.1.0 (4.2.2023)

## New
- Added option to define new and modify current TAGS by another addon [see example](https://github.com/BelegCufea/PrettyReputation_MoreTags)

## Fixes
- "Optimized" message composition

# v1.1.0-beta2 (4.2.2023)

## Update
- Few modifications for external TAGS editing

# v1.1.0-beta1 (3.2.2023)

## New
- Modified TAGS logic so they can be added or modified externally

# v1.0.5a (2.2.2023)

## Fix
- Reward bag for paragon not showing

# v1.0.5 (1.2.2023) - **Initial public release**

## New
- Profiles
- Debug option

## Update
- Ace3

## Fixes
- Paragon level color
- Renown level tag showing Paragon level

# v1.0.3 (31.1.2023)

## New
- Tracking session gain/losses
- Separate paragon and renown level tags
- Paragon reward icon

## Update
- Current percentage change rounded to two decimal places (instead of one)

## Fix
- Initializing all (hopefully) available factions

# v1.0.0 (30.1.2023)



