# Pretty Reputation

***

## <span style="color:#e03e2d">State of the addon for Midnight expansion</span>

I am sorry to inform you that I am not currently playing WoW due to personal reasons.

Unfortunately, Blizzard has restricted access to the specific values I use to monitor reputation changes, effectively making them "secret". Because the process I rely on to read this data is now broken, I won't be able to fix the addon for the foreseeable future.

That said, if I find some free time, I may try to log in on a trial account to investigate potential workarounds. I would also need to find a reliable reputation farming spot to test any changes.

I apologize for the inconvenience!

PS: If anyone is interested in taking over this addon (or using the code for another project), you have my full permission and I will offer my full cooperation to help you understand the codebase (which is a mess).

<span style="color:#e03e2d">UPDATE: Jan 26, 2026</span> ⚠️ Alpha Release (v1.5-alpha) I’m apparently too stubborn to let this go! I’ve released v1.5-alpha to address the Midnight Lua errors.

- **Use at your own risk**: This is untested in live gameplay.
- **Feedback**: Please report any further errors and I will try to squash them Soon™.

<span style="color:#e03e2d">UPDATE: Jan 28, 2026</span> ⚠️ Alpha Release (v1.5-alpha2) I have fixed "Show splash reputation" Lua errors. This is still an experimental release. Although it works fine on classic reputations, it is untested on Renown and Paragon reputations.

<span style="color:#e03e2d">UPDATE: Feb 3, 2026</span> ⚠️ Alpha Release (v1.5-alpha3) Attempting to fix reputation gains for Paragon factions where the character has not yet reached Paragon level.


***


Show more information about reputation gain in your chat.

![Example](https://i.imgur.com/b1VF8EX.png)

Or

![WithTexture](https://i.imgur.com/nzuDQS7.png)

## Features

- Print a configurable message about the reputation change in your preferred output. There are many options for setting up your message.
- Track session reputation gains or losses on the minimap icon/databroker.
- Show on-screen bars with session reputation changes.
- Pick <code>Favorite</code> factions to be always shown as on-screen bar.
- Set the faction with the latest reputation change as watched.
- Add your own tags or modify existing ones. (See [Example with instructions here](https://github.com/BelegCufea/PrettyReputation_MoreTags))

## Configuration

Locate the 'Pretty Reputation' section within the 'Options -> Addon' section, or right-click the minimap icon. You can also use `/pr` in chat to get a list of available commands.

- In the `pattern` field, compose your desired message format. You can choose from several predefined tags.
- Define your ideal bar to represent your reputation progress.
    - Choose an optimal character, and determine how many of these will form the bar.
    - Or use texture for the bar. Define its width and height.
- Define colors for each reputation standing. Choose from several predefined color schemes.
- Set your preferred output method (Chat, Floating text, etc.)

---
> Compose a message

![Compose your message](https://i.imgur.com/Pm7V3hX.png)

> Modify several TAGs behaviour

![Modify TAGs](https://i.imgur.com/i4e8zuR.png)

> Select output for your message

![Select output](https://i.imgur.com/ncqgJoM.png)

> Choose if and how you want your on-screen reputation bars to apear

![Modify On-Screen bars](https://i.imgur.com/wv4Isro.png)

> Pick color scheme or define your own colors

![Choose your colors](https://i.imgur.com/EJWI8lp.png)

> Pick <code>Favorite</code> factions

![Favorite factions](https://i.imgur.com/jjzgkpq.png)

## Issues

If you encounter any problems or have a suggestion, please [open an issue on Github](https://github.com/BelegCufea/PrettyReputation/issues).