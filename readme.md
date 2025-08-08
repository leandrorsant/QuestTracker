# Pet Daily Quest Tracker

A lightweight World of Warcraft addon to help you keep track of which pet battle daily quests you haven't completed for the day.

## Features

*   **Automatic Tracking:** Displays a simple, clean list of incomplete pet battle daily quests.
*   **Smart Visibility:** The tracker window only appears when you have the [Safari Hat](https://www.wowhead.com/item=92738/safari-hat) equipped, keeping your UI uncluttered when you're not focused on pet battles.
*   **Movable & Memorable:** Drag the tracker frame anywhere on your screen. Its position is saved automatically across sessions.
*   **Highly Configurable:** Use a simple configuration panel to choose exactly which quests you want to track.
*   **Darkmoon Faire Aware:** The Darkmoon Faire pet battle daily only shows up in the tracker when the faire is active.
*   **Quest Progress:** Shows completion progress for multi-part quests like "Beasts of Fable".

## How to Use

The tracker frame will automatically appear on your screen when you equip the **Safari Hat**.

To move the frame, simply click and drag it with your left mouse button. The position will be saved for your next session.

  <!-- You would replace this with an actual screenshot -->

## Configuration

To open the configuration panel, type the following command in your chat window and press Enter:

```
/qt config
```

In the configuration window, you can check or uncheck quests to enable or disable tracking for them.

*   **Tracked Pet Battle Dailies:** These are the main dailies that reward a [Sack of Pet Supplies](https://www.wowhead.com/item=98586/sack-of-pet-supplies). They are tracked by default.
*   **Optional Pet Dailies:** These quests do not reward a supply sack. They are not tracked by default.

Changes are saved and applied instantly.

## Tracked Quests

The addon can track the following quests:

### Main Dailies (Reward a Sack of Pet Supplies)

*   Aki - Eternal Blossoms
*   Antari - Shadowmoon Valley
*   Beasts of Fable Book I
*   Beasts of Fable Book II
*   Beasts of Fable Book III
*   Burning Pandaren Spirit - Townlong Steppes
*   Farmer Nishi - The Four Winds
*   Flowing Pandaren Spirit - Dread Wastes
*   Hyuna - Jade Forest
*   Jeremy - Darkmoon Faire
*   Lydia Accoste - Karazhan
*   Major Payne - Icecrown
*   Moruk - Krasarang Wilds
*   Obalis - Uldum
*   Shu - Dread Wastes
*   Thundering Pandaren Spirit - Eternal Blossoms
*   Trixxy - Everlook
*   Whispering Pandaren Spirit - Jade Forest
*   Yon - Kun-Lai Summit
*   Zusshi - Townlong Steppes

### Optional Dailies (No Sack of Pet Supplies)

*   Analynn - Ashenvale
*   Beegle Blastfuse - Howling Fjord
*   Bill Buckler - Cape of Stranglethorn
*   Bordin Steadyfist - Deepholm
*   Brok - Mount Hyjal
*   Cassandra Kaboom - Northern Stranglethorn
*   Dagra the Fierce - Northern Barrens
*   David Kosse - The Hinterlands
*   Durin Darkhammer - Shadowmoon Valley
*   Elena Flutterfly - Moonglade
*   Eric Davidson - Duskwood
*   Goz Banefury - Twilight Highlands
*   Grazzle the Great - Dustwallow Marsh
*   Gutretch - Zul'Drak
*   Julia Stevens - Elwynn Forest
*   Kela Grimtotem - Thousand Needles
*   Kortas Darkhammer - Searing Gorge
*   Lindsay - Redridge Mountains
*   Merda Stronghoof - Desolace
*   Morulu the Elder - Shattrath City
*   Narrok - Nagrand
*   Nearly Headless Jacob - Crystalsong Forest
*   Nicki Tinytech - Hellfire Peninsula
*   Okrut Dragonwaste - Dragonblight
*   Old MacDonald - Westfall
*   Ras'an - Zangarmarsh
*   Steven Lisbane - Deadwind Pass
*   Traitor Gluk - Feralas
*   Zoltan - Felwood
*   Zonya the Sadist - Stonetalon Mountains
*   Zunta - Durotar

## Installation

1.  Download the latest version of the addon.
2.  Unzip the downloaded file.
3.  Copy the `QuestTracker` folder into your `World of Warcraft\_classic_\Interface\AddOns` directory.
4.  Restart World of Warcraft or run `/reload` in the chat.