# Enter the Ancient Grotto

Many adventurers enter the Ancient Grotto -- a dangerous, shifting dungeon full of danger, adventure, and treasure. Many enter, but few live to see daylight once more. The Grotto changes, shifts, providing each venture with an entirely different landscape of death.

Ancient Grotto is a roguelike, made in RPG Maker.

# Implementation Details

## Overview

- The `Events` map contains tile data and template events which are copied to each floor. 
- The game uses a slightly extended version of the RTP for monster sprites (including big monster support)
- Stairs on the `EndGame` and `Town` map are copied (and tweaked) from the `Events` map.
- You can only save from the town
- Shops change their wares on an interval of N minutes
- Potions and status items always appear in the item shop


## Modifying the Project

Here are some things you need to know to make everything work smoothly:

- Tweak the game as normal; items, equipment, classes, skills, troops, etc. are all modifyiable as usual
- All of the variables in `dungeon_generator.rb` can be tweaked to your liking. Follow the examples.
- To create custom maps, copy the sample of the `EndGame` map. 
- The first block of constants in `dungeon_generator` represent events which are copied when generating the dungeon
- The `MONSTERS` collection maps monster sprites to troops, and sets movement speed and patterns.
- `CUSTOM_FLOORS` lets you add custom maps on particular floor numbers.
- The size of the `Dungeon` map is the size of the generated dungeon


## Challenges

RPG Maker VX Ace is not yet ready for a full code-only solution necessary for a roguelike. This roguelike template contains many patterns, and works around many caveats and issues.

---

**Problem: changing any maps breaks in-dungeon saves.** If you start your game, save in the dungeon, change any of your maps, and reload your save game, you get a blank screen. This is probably due to how RPG Maker internally handles the change and recreates the maps; the actual map data is set at runtime, so maybe that's why it doesn't persist.

**Solution: don't allow saving in-dungeon.** The bottom of `dungeon_generator.rb` disables the save menu; you can only save via an event explicitly showing the save screen.

**Other solutions:**
- Tell players to save in town before upgrading to the latest version of the game
- (Provided) an always-available Town Portal option (item or skill) to return to the town if this happens

---

**Problem: There's no easy way to know the tile ID to set for a tile.** When creating walls/floors, how do we know what indicies to use? It depends completely on your tileset.

**Solution:** The `Dungeon` map contains sample tiles, one column per floor, indicating which tiles to use. This gives us the right IDs (except auto tiles; see below).

---

**Problem: Auto-tiles don't tile directly.** Setting map data with fixed ID results in exactly that instance of the auto-tile being copied all over the dungeon.

**Solution: fix auto-tile indicies manually.** KilloZappit's script (included) does this for us.

---

**Problem: Big Monster sprites don't have the same invariant as other images.** For normal sprites,  you set the file and index of the character; for big monsters, this doesn't work.

**Solution:** 
- Create a separate event for big monsters with `Direction Fix enabled
- If the sprite is a big monster, set the index to zero and the direction appropriately

---

**Problem: when is the class instantiated, and how?** Although `DungeonGenerator` contains a constructor, it's never called, even when `new` is explicitly invoked. This results in wierd behavior, like instance variables (eg. `@floor_num`) being `nil`.

**Solution:** Defensively consume and set these variables to reasonable values if they're `nil`.

---

**Problem: Map name doesn't displayw when floors change.** Changing the map's `display_name` doesn't force it to redraw.

**Solution:** Transfer the player first to a dummy location on the map to force the map name to draw.

---

**Problem: Map generation is ugly.** We need to hide the "glitchiness" of tiles changing.

**Solution: use fade commands.** These hide the map until it's ready to appear.

---

**Problem: copying events "links" them such that changing one changes all of them.**

**Solution:** When copying events, you need to explicitly set a new event ID. Archeia's `spawn_events` (included) does this.

---

**Problem: Can't spawn events under the player; they don't appear.**

**Solution:** Move the player somewhere else, spawn the event, and move the player back on top.

---

**Problem: Switches on copied events persist even when the events are re-created.** This is probably because we use a single map and re-use event IDs (eg. 2, 3, ... 7)

**Solution:** Manually decativate switch A so that treasure chests don't stay open forever (on future floors) once opened.

---

**Problem: reserve_transfer isn't the same as a Transfer Player event. `map_id` doesn't update immediately.** This is because these methods are asycnhronous requests; they are executed later. (See [this forum post](http://forums.rpgmakerweb.com/index.php?/topic/30438-reserve-transfer-is-not-the-same-as-transfer-player/?view=getnewpost).)

**Solution:** Copy the semantics of `Game_Interpreter.command_201` (Transfer Player): namely, wait for it to succeed. This means custom map stairs are copies of the master stairs, but the town stairs are not.

# Future Direction

Ancient Grotto is currently a prototype shell of a game. It needs to be fleshed out into a proper game:

- A real intro, story, and proper (stunning) conclusion
- Game balancing: classes, equipment, skills, troops

The bulk of the work is tweaking the classes, equipment, skills, troops, and items to make sense for a single-character roguelike. (For example, rats, which are quite weak and appear on early floors, inflict blindness; once blind, it's almost impossible to kill them.)
