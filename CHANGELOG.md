# v1.4.5a (12.7.2025)

## Fix
- [Faction Addict](https://www.curseforge.com/wow/addons/faction-addict) icon integration is updated to new structure introduced in version 1.102

## Misc
- Updated libraries

# v1.4.5 (18.6.2025)

## Fix
- [Faction Addict](https://www.curseforge.com/wow/addons/faction-addict) icon integration is updated to new structure introduced in version 1.98

## Misc
- Bumped TOC (11.1.7)

# v1.4.4 (21.3.2025)

## New
- New hook for Delver's Journey (for weekly quest and after finishing Delves)

## Misc
- Added category (Other) to TOC

# v1.4.3d (26.2.2025)

## Fix
- Fix for renown level standing text displaying %d

# v1.4.3c (5.2.2025)

## Fix
- Fix for friendship reputation error (reported by [gryphon63](https://www.curseforge.com/members/gryphon63/projects))

# v1.4.3b (18.12.2024)

## Fix
- Fix for guild reputation (maybe?)

## Misc
- TOC update (11.0.7)

# v1.4.3a (4.10.2024)

## Fix
- Fix for `Delver's Journey` not increasing when looting Restored coffer key chest

# v1.4.3 (4.10.2024)

## New
- Added `Delver's Journey` season stages (Delve progression)

## Misc
- Changed `level` and `maxLevel` tags to hide if level = maxLevel

# v1.4.2 (14.9.2024)

## New
- Left-clicking the on-screen reputation bar now allows you to toggle a faction as a favorite. The tooltip will display `(F)` after the faction name to signify it's a favorite. To clarify, favorite factions will automatically be visible upon login.

![Favorite by click](https://i.imgur.com/DnrblPL.png)

- Faction searches are now available within the favorites option section. Also factions from Reputation panel are separated from hidden ones.

![Favorite by click](https://i.imgur.com/ROiY58D.png)

- A new option allows the on-screen bar to prioritize Paragon colors over Renown colors if the faction has Paragon levels. You can find the `paragon standing color overrides renown` option under the `Reputation Bars` tab.
- Custom starting and ending colors for both renown and friendship faction level spans are now available. The color will begin at the `From` color for level 1 and  gradually transition to the `To` color as levels increase, using HSV interpolation.

![Renown colors](https://i.imgur.com/eSnG9Xn.png)

# v1.4.1 (1.9.2024)

## New
- Added [level] and [maxLevel] tags that shows levels of friendship reputations. Can be used for example like so `[{ |}level][{/}maxLevel{|}]` to show `" |5/9|"` if your reputation level with said faction is 5 and maximum level is 9. It will display nothing if faction does not belong to friendship category.

## Fix
- fix for nil faction

# v1.4.0e (27.8.2024)

## Fix
- Faction icon from [FactionAddict](https://www.curseforge.com/wow/addons/faction-addict) was rewriten even if in-game icon was not available
  - This is temporary fix for The War Within missing icons

# v1.4.0d (17.8.2024)

## Fix
- The Inactive faction was accidentally pulled from the Reputation panel in some niche cases (thanks [jon-ault](https://github.com/jon-ault))

# v1.4.0c (16.8.2024)

## Fix
- Blizz messing with Reputation panel again

**Overview:**
This is a (let's hope temporary) fix for the issue where Blizzard isn't listing all valid reputations in the Reputation panel. **WTF Blizz... AGAIN!**

**Changes:**
All unlisted reputations, some of which are quite weird, now appear in red within the "Favorites" section and the "Test" drop-down box. This is a temporary workaround to ensure you can still see and track those reputations until Blizzard resolves the issue.

**Note:**
Please be aware that the "Show splash reputation" feature now has to parse over 600 reputations each time any reputation changes. This might cause a slight performance impact, potentially reaching tens of milliseconds.

**Clean-up:**
If I find the time, I promise I'll clean up the favorite reputations picking process!

# v1.4.0b (15.8.2024)

## Fix
- Get all major factions even if they are not in reputation panel

# v1.4.0a (15.8.2024)

## Fix
- No faction in Blizz list of factions (WTF Blizz)

# v1.4.0 (14.8.2024)

## Fix
- Adjustment for 11.0 (The War Within) expansion reputation changes
- Error when opening options through broker
- Fix for tracking faction
- Fix for Dream Wardens icon

## Misc
- There seems to be a problem with Warbound reputations not loading into the reputation panel until some reputation change occurs. Either Blizzard will fix it, or I will try to.

# v1.4.0-beta (24.7.2024)

## Fix
- First attempt to adjust for 11.0 (The War Within) expansion reputation changes

# v1.3.5c (20.7.2024)

## Fix
- Fix for "script ran too long" error- (thanks [filliph](https://github.com/filliph))

# v1.3.5b (14.7.2024)

## Fix
- Guild reputation was not displayed correctly (thanks [Hyphie24](https://github.com/Hyphie24))

# v1.3.5a (15.6.2024)

## Fix
- On-screen bars for favorite factions not updating correctly when selected in options.

# v1.3.5 (14.6.2024)

#### <u>Note</u>
Since I am not plaing WoW right now, I am not be able to fully test if everything's working smoothly. If you run into any issues, please feel free to report them on [GitHub](https://github.com/BelegCufea/PrettyReputation/issues).

## Added
- <b>Pin Your Favorite Factions:</b>
Choose the factions you care most about from the "<code>Favorites</code>" list. These will become "pinned" bars that always show up, even if there are no current gains for those factions.  This way, you can easily keep an eye on your progress without having to navigate through the full list.
![Favorite factions](https://i.imgur.com/jjzgkpq.png)


# v1.3.4 (23.5.2024)

## Fix
- Profile changing
- Fix Plunderstorm faction issue ([filliph](https://github.com/filliph))

## Misc
- Revert debug to [ViragDevTool](https://www.curseforge.com/wow/addons/varrendevtool) as [DevTool](https://www.curseforge.com/wow/addons/devtool) is still buggy.
- Revamped Debug implemntation

# v1.3.3 (11.5.2023)

## Added
- Added support for Addon compartment system.

## Update
- Minimap icon is hidden by default and compartment button is shown by default.  Both can be toogled on the `General` panel.

## Misc
- Moved debug from [ViragDevTool](https://www.curseforge.com/wow/addons/varrendevtool) to [DevTool](https://www.curseforge.com/wow/addons/devtool).

# v1.3.2 (3.5.2023)

## Added
- Added options for composing text using tags for on-screen reputation bars. This allows users to customize the information displayed on the reputation bars by using tags to dynamically insert data such as faction name, reputation level, progress towards next level, etc (setings on the `Reputation bars` panel).
- Added option to define different pattern for chat frames if `Also display message in following chat frames` on the `Output` panel is enabled.
- Added tags [nameShort] and [c_nameShort].
- Added tags [nc_name] and [nc_nameShort] for faction name without the purplish color. The tag [name] was originally created with that color, but to avoid breaking already used patterns, a new tag was added.
- Added tags [renownLevelNoParagon] and [c_renownLevelNoParagon] that display the renown level only if there is no paragon level gained yet.

## Update
- Bump TOC for 10.1 patch
- Updated formating of all numbers. (from 11659 to 11,659)
- Chnaged `show paragon count in standing text` to `show paragon level instead of standing text` (so you will get `Paragon 6` instead of `Renown25 (6)`).
- Slight change generating tooltip for on-screen reputation bars. Added current bar values to tooltip (i.e. 500/6,000)

## Fixes
- Text from on-screen reputation bars spilling to multiple lines.

## Misc
- Exposed `Short(text, numberOfCharacters)` and `Combine(info, value)` functions in Addon.TAGS.Functions to be used in [custom TAGs](https://github.com/BelegCufea/PrettyReputation_MoreTags) using `local functions = LibStub("PrettyReputationTags").Functions; functions.Short(...)`.
    - Short function will return shortened text as [..Short] tags do.
    - Combine function will combine conditional prefix and/or suffix into tag (introduced in v1.3.0).

# v1.3.1 (13.4.2023)

## Added
- Added option to modify texts for `[signText]` (settings on the `Tags options` panel).
- Added option to override the renown color with paragon (if available) in [c_...] Tags.

## Fixes
- Fix for bars (including textured bars) splitting in the middle when displayed.
- Fix for `PrettyReputation/core.lua:507: attempt to index field "?" (a nil value)` for `Guild` reputation (reported by filliph).

# v1.3.0 (30.3.2023)

## **Conditional prefixes and suffixes for TAGS**
I have added functionality that allows adding conditional prefixes and/or suffixes to any text TAG (except for graphical tags like bar, icon, etc.).

The format is as follows, where both {prefix} and {suffix} are optional:

```
[{prefix}TAG{suffix}]
```
**If `[TAG]`** *(without prefexes and suffixes)* **evaluates to an empty value, neither the prefix nor the suffix in `[{prefix}TAG{suffix}]` will be displayed.**

There cannot be any spaces except inside the prefix or suffix, which can be any text, even with spaces (or only spaces if you wish).

> Here are a few examples:

- `[{Renown level: }renownLevel]` = "Renown level: 25" (If the faction isn't renowned, nothing will be displayed!)
- `[{Next rank: }standingNext]` = "Next rank: Honored" (Again, if [standingNext] does not return a value, nothing will be displayed.)
- `[{Level }paragonLevel{ paragon}]` = "Level 5 paragon" (Nothing will be displayed if there is no Paragon level available.)

## Added
- New `FAQ/Help` section
- Added TAGs `[standingColorStart]` and `[standingColorEnd]`. They will color the text between them in the message with a standing color. **These have to be used in pairs** and `[standingColorStart]` must precede `[standingColorEnd]`. (requested by filliph)
- Added a TAG `[signText]`. It will display "increased" when a reputation is gained and "decreased" when it is lost.
- Added group of TAGs `[standingNext]` (with `[c_...]` and `[...Short]` variants). They will display next standing/renown/paragon standing. They only work for standard  *... -> "Neutral" -> "Friendly" -> "Honored" -> ...* progression or for renown and paragon factions.

## Fixes
- Choosing the "Blizzard" color scheme throwed an error: `PrettyReputation/bars.lua:182: attempt to index local 'color' (a nil value)` (reported by filliph - thanks mate)


# *v1.3.0-beta2 (29.3.2023)*

## Fixes
- When 'Splash' is enabled and faction is renown or has paragon levels then the change and session values can be negative when a rank in the standing is gain.
    - *This should also fixe `bottom` and `top` TAGs*
- Reward bag shows on on-screen bars even, when it should not be there any more.

# *v1.3.0-beta1 (22.3.2023)*

## **Conditional prefixes and suffixes for TAGS**
I have added functionality that allows adding conditional prefixes and/or suffixes to any text TAG (except for graphical tags like bar, icon, etc.).

The format is as follows, where both {prefix} and {suffix} are optional:

```
[{prefix}TAG{suffix}]
```
**If `[TAG]`** *(without prefexes and suffixes)* **evaluates to an empty value, neither the prefix nor the suffix in `[{prefix}TAG{suffix}]` will be displayed.**

There cannot be any spaces except inside the prefix or suffix, which can be any text, even with spaces (or only spaces if you wish).

> Here are a few examples:

- `[{Renown level: }renownLevel]` = "Renown level: 25" (If the faction isn't renowned, nothing will be displayed!)
- `[{Next rank: }standingNext]` = "Next rank: Honored" (Again, if [standingNext] does not return a value, nothing will be displayed.)
- `[{Level }paragonLevel{ paragon}]` = "Level 5 paragon" (Nothing will be displayed if there is no Paragon level available.)

## Added
- Added TAGs `[standingColorStart]` and `[standingColorEnd]`. They will color the text between them in the message with a standing color. **These have to be used in pairs** and `[standingColorStart]` must precede `[standingColorEnd]`. (requested by filliph)
- Added a TAG `[signText]`. It will display "increased" when a reputation is gained and "decreased" when it is lost.
- Added group of TAGs `[standingNext]` (with `[c_...]` and `[...Short]` variants). They will display next standing/renown/paragon standing. They only work for standard  *... -> "Neutral" -> "Friendly" -> "Honored" -> ...* progression or for renown and paragon factions.

## Fixes
- Choosing the "Blizzard" color scheme throwed an error: `PrettyReputation/bars.lua:182: attempt to index local 'color' (a nil value)` (reported by filliph - thanks mate)

# v1.2.2 (21.3.2023)

## Update
- Bump TOC for 10.0.7 patch

# v1.2.1d (20.3.2023)

## Fixes
- Resolved an issue where messages were still being displayed even when the addon was disabled on the `General` panel.
- Reputation bars were showing if they were disabled in previous session (reported by filliph).
- Fixed a situation where the addon wasn't registering the first reputation gain (or loss) for a newly "discovered" faction, if the 'Splash' feature was enabled. However, please note that this fix only applies to factions that are announced by Blizzard. Factions that gain or lose reputation without Blizzard's notification (i.e. 'splashed' factions) won't register the first gain or loss if they are newly discovered.
- Fixed error `PrettyReputation/core.lua:139: attempt to index field '?' (a nil value)` on initial setup of reputations (reported by filliph - thanks mate)

## Misc
- The 'Splash' feature is a nice addition, but it requires the addon to calculate all reputations every time there is a change, even if the addon is not enabled on the `General` panel. Although this process takes only a few milliseconds (on my old computer), it may be worth considering in certain situations.

# v1.2.1c (19.3.2023)

## New
- Added "Last change" to on-screen bar tooltip.

## Fixes
- Removing an on-screen bar by right-clicking was not working properly.

## Misc
- After doing some additional testing, the 'Splash' feature seems to be working properly. The code even throttles down multiple reputation changes for a faction. However, I will leave it turned off by default for now until further testing proves it to be reliable.

# v1.2.1b (19.3.2023)

## New
- Added a feature to hide an on-screen bar by right-clicking it.

## Fixes
- Ever-blinking on-screen bars when "time to display" is set to a non-zero value.

# v1.2.1a (18.3.2023)

## Fixes
- Error `PrettyReputation/core.lua:282: attempt to call global 'GetFactionLabel' (a nil value)`

# v1.2.1 (18.3.2023)

## New
- Added an option for on-screen bars to hide after an adjustable time (set in the `Reputation bars` panel). *If enabled, the TEST bars will only be visible for the set amount of time; otherwise, they will be visible for 60 seconds and then disappear.*
- Added a tooltip for on-screen reputation bars that shows the faction standing and how much reputation is needed to reach the next standing (positioning available on the `Reputation bars` panel).
- Added an option to show "splash" reputation changes (settings available on the `General` panel).
    - *Sometimes Blizzard changes some reputations internally without notifying the user.* **Please note that enabling this option may slow down the game a bit**, so use it only if needed. **It won't catch the first reputation change for a newly discovered "splashed" factions.** None of these "splashes" exist in the latest content (found 5 linked ones {[Alliance Vanguard](https://www.wowhead.com/faction=1037/alliance-vanguard)/[Horde Expedition](https://www.wowhead.com/faction=1052/horde-expedition)} in WotLK expansion so far).

## Fixes
- Toggling the addon using the minimap/databroker or chat command was not affecting the on-screen reputation bars.

# v1.2.0 (16.3.2023)

## New
- Added option to show on-screen Bars for every faction that had a reputation change during current session (settings in new `Reputation bars` panel)
    - *When testing settings (using TEST button), testing Bars will be displayed for at leat 1 minute. After that any reputation change will hide them.*

![On-screen bars](https://i.imgur.com/qp4AvbO.png)

## Update
- Cleaned Libraries
- Slightly changed structure of options section
    - *moved profiles and about panel to their own section*
    - *moved `TEST` above panels*
- Modified paragon count to be more in-line with other addons (it is now one less then it used to)
- Added option to move [barTexture] up or down (settings on `Tag options` panel)

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

# *v1.1.5-beta2 (13.2.2023)*

## Updated
- Streamlined the structure of the Options.
- Changed the behavior of the `standingShort` and `c_standingShort` tags. It is now possible to choose the number of letters from each word in the standing text to be displayed. For example, if you set the number of characters to 3, you will get the following: Friendly => Fri, True Friend => TruFri, Revered => Rev, Renowned 25 => Ren25, and so on. If one character is chosen (default), you will get F, TF, R, R25, respectively.

# *v1.1.5-beta1 (12.2.2023)*

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

# *v1.1.1-beta1 (6.2.2023)*

## New
- Added option to set faction with latest change as watched

## Fixes
- Another try to process new reputations

# v1.1.0 (4.2.2023)

## New
- Added option to define new and modify current TAGS by another addon [see example](https://github.com/BelegCufea/PrettyReputation_MoreTags)

## Fixes
- "Optimized" message composition

# *v1.1.0-beta2 (4.2.2023)*

## Update
- Few modifications for external TAGS editing

# *v1.1.0-beta1 (3.2.2023)*

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