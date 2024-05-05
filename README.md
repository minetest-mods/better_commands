# Better Commands
Adds commands and syntax from a certain other voxel game (such as `/kill @e[type=mobs_mc:zombie, distance = 2..]`) to Minetest. For compatible command blocks, use my [Better Command Blocks](https://content.minetest.net/packages/ThePython/better_command_blocks/) mod. I'm basically copying them from a certain other voxel game (whose name will not be mentioned), hereafter referred to as ACOVG. I may eventually make a wiki to explain the differences.

### PLEASE help with bug reports and PR's
This is kind of a huge project. ACOVG's commands are complicated. If you would like, you can also help translate it on Weblate.

## Current command list:
* `/bc`\*: Allows players to run any command added by this mod even if its name matches the name of an existing command (for example, `/bc give @a default:dirt` or even `/bc bc /bc /bc bc give @a default:dirt`)
* `/old`\* Basically the opposite of `bc`, running any command overridden by commands from this mod.
* `/?`: Alias for `/help`
* `/ability <player> <priv> [true/false]`: Shows or sets `<priv>` of `<player>`.
* `/execute align|anchored|as|at|facing|positioned|rotated|run ...`: Runs other Better Commands (not other commands) after changing the context. If you want more information, check ACOVG's wiki because I'm not explaining it all here. Some arguments will not be added, others will be but haven't yet.
* `/give <player> <item>`: Gives `<item>` to `<player>`
* `/giveme <item>`\*: Equivalent to `/give @s <item>`
* `/kill [target]`: Kills entities (or self if left empty)
* `/killme`\*: Equivalent to `/kill @s`
* `/me <message>`: Broadcasts a message about yourself
* `/msg`: Alias for `/tell`
* `/say <message>`: Sends a message to all connected players (supports entity selectors in `<message>`)
* `/summon <entity> [pos] [rotation]` Summons an entity
* `/scoreboard objectives|players ...`: Manipulates the scoreboard
* `/setblock <pos> <node> [destroy|keep|replace]`: Places nodes (supports metadata/param1/param2).
* `/setnode`: Alias for `/setblock`
* `/team add|empty|join|leave|list|modify|remove ...`: Manipulates teams.
* `/teleport [too many argument combinations]`: Sets entities' position and rotation
* `/tell <player> <message>`: Sends a message to specific players (supports entity selectors in `<message>`)
* `/trigger <objective> [add|set <value>]`: Allows players to set their own scores in controlled ways
* `/tp`: Alias for `/teleport`
* `/w`: Alias for `/tell`

\* Not in ACOVG

## Entity selectors
Everywhere you would normally enter a player name, you can use an entity selector instead. Entity selectors let you choose multiple entities and narrow down exactly which ones you want to include.

There are 5 selectors:
* `@s`: Self (the player running the command)
* `@a`: All players
* `@e`: All entities
* `@r`: Random player
* `@p`: Nearest player

`@r` and `@p` can also select multiple players or other entities if using the `type` or `limit`/`c` **arguments** (explained below).

### Selector arguments
Selectors support various arguments, which allow you to select more specific entities. To add arguments to a selector, put them in `[square brackets]` like this:
```
@e[type=mobs_mc:zombie,name=Bob]
```
You can include spaces if you want (although this many spaces seems a bit excessive):
```
@e [ type = mobs_mc:zombie , name = Bob ]
```
This selector selects all MCLA/VL zombies named Bob.

All arguments must be satisfied for an entity to be selected.

`@s` ignores all arguments, unlike in ACOVG.

Here is the current list of arguments:
* `x`/`y`/`z`: Sets the position for the `distance`/`rm`/`r` arguments. If one or more are left out, they stay the same.
* `distance`: Distance from where the command was run. This supports ranges (described below).
* `rm`/`r`: Identical to `distance=<rm>..<r>` (this is slightly different from ACOVG's usage).
* `name`: The name of the entity
* `type`: The entity ID (for example `mobs_mc:zombie`).
* `sort`: The method for sorting entities. Can be `arbitrary` (default for `@a` and `@e`), `nearest` (default for `@p`), `furthest`, or `random` (default for `@r`).
* `limit`/`c`: The maximum number of entites to match. `limit` and `c` do exactly the same thing, and only one can be included.

#### Entity aliases
Some entities have aliases. For example, you can type use `@e[type=zombie]` to select all zombies, instead of having to use `@e[type=mobs_mc:zombie]`. Aliases currently exist for items (`item` instead of `__builtin:item`), falling nodes (`falling_node` or `falling_block`), and mobs from the following mods:
* Animalia
* Dmobs
* Draconis
* Wilhelmines Living Nether
* Mobs Animal
* balrug (flux's fork)
* Water Mobs (`mobs_crocs`, `mobs_fish`, `mobs_jellyfish`, `mobs_sharks`, `mobs_turtles`)
* Mob Horse
* Mob Mese Monster Classic
* Mobs Monster
* Mobs Skeletons
* VoxeLibre and Mineclonia
* Not So Simple Mobs

You can add or change aliases in `entity_aliases.lua`.

#### Number ranges
Some arguments (currently just `distance` at the moment) support number ranges. These are basically `min..max` (you don't need both). Everywhere a range is accepted, a normal number will also be accepted.
Examples of ranges:
* `1..1`: Matches exactly 1
* `1..2`: Matches any number between 1 and 2 (inclusive)
* `1..`: Matches any number greater than or equal to 1
* `..-1.5`: Matches any number less than or equal to -1.5
* `1..-1`: Matches no numbers (since it would have to be greater than 1 *and* less than -1, which is impossible).

#### Excluding with arguments
Some arguments (such as `name` and `type`) allow you to prefix the value with `!`. This means that it will match anything *except* the entered value. For example, since `@e[type=player]` matches all players, `@e[type=!player]` matches all entities that are *not* players. Arguments testing for equality cannot be duplicated, while arguments testing for inequality can. In other words, you can have as many `type=!<something>` as you want but only one `type=<something>`.

## Known Issues:
1. I can't figure out how to do quotes or escape characters. This means that you cannot do things like `/kill @e[name="Trailing space "]` or have `]` in any part of entity/item/node data.
2. `/tp` does not support the `checkForBlocks` argument in one version of ACOVG. This *might* change in the future.
3. Only entities that use `luaentity.nametag` or `luaentity._nametag` for nametags (and players, of course) are supported by the `name` selector argument. This includes all mobs from MCLA/VL and Mobs Redo, but potentially not others.
4. `/setblock` only supports `replace` or `keep`, not destroy, and only places nodes using `set_node`. Some nodes may not act right since they weren't placed by a player. You could, in theory, look at the node's code and set its metadata...
5. `/time` does not properly add to the day count.
6. Only players (not other entities) are supported by scoreboards, teams, and entity tags, since other entities don't have UUIDs. This *might* change.
7. Except in MCLA/VL, the `playerKillCount` and `killed_by`, `teamkill`, and `killedByTeam` objectives can only track direct kills (so not arrows or explosions, for example).
8. Objectives cannot be displayed as hearts, although literally the only reason is that there's no good half heart character.
9. Team prefixes and suffixes have been replaced with `nameFormat` (for example, `/team modify a_nice_team nameFormat [Admin] %s the great`), where any `%s` is replaced with the player's name. If your name was `singleplayer`, it would appear as `[Admin] singleplayer the great`. The reason for this is pretty simple: I don't want to figure out how to do quotes, and Minetest removes trailing space, meaning prefixes ending in spaces are impossible. This fixes that.
10. The `/give` command is currently unable to give multiple tools (so `/give @s default:pick_wood 5` will only give 1). This may change.

## TODO
- [ ] Add scoreboard playerlist and nametags (?)
- [ ] Figure out feet/eyes since most entities don't have that
- [ ] Make output match ACOVG's (error messages, number results, etc.)
- [ ] Add more scoreboard criteria (settings to disable)
  - [ ] `xp`/`level` (MCLA/VL only)
  - [ ] `food` (MCLA/VL/stamina)
  - [ ] `air`
  - [ ] `armor` (MCLA/VL/3D Armor)
  - [x] `trigger`
  - [ ] `picked_up.<itemstring>`
  - [ ] `mined.<itemstring>`
  - [ ] `crafted.<itemstring>`
  - [ ] `total_world_time`
  - [ ] `leave_game`
- [ ] Add missing `execute` subcommands
  - [ ] `in`
  - [ ] `summon`
  - [ ] `if/unless`
    - [ ] `biome`
    - [ ] `block`/`node`
    - [ ] `blocks`/`nodes`
    - [ ] `data`
    - [ ] `dimension`
    - [ ] `entity`
    - [ ] `loaded`
    - [ ] `score`
  - [ ] `store`
    - [ ] `block`/`node`
    - [ ] `bossbar`
    - [ ] `entity`
    - [ ] `score`
- [ ] Add more commands
  - [x] `trigger`
  - [ ] `alwaysday`/`daylock`
  - [ ] `ban`/`ban-ip`/`banlist`
  - [ ] `bossbar`? (probably significantly modified)
  - [ ] `advancement`
  - [ ] `fill` (Extra argument for LBM vs `set_node(s)`)
  - [ ] `changesetting`?
  - [ ] `clear`
  - [ ] `spawnpoint`
  - [ ] `clearspawnpoint`
  - [ ] `clone`
  - [ ] `damage`
  - [ ] `data`
  - [ ] `deop` (removes all but basic privs)
  - [ ] `op` (grants certain privs, including `server`)
  - [ ] `effect` (MCLA/VL only)
  - [ ] `enchant` (MCLA/VL only, also override forceenchant?)
  - [ ] `experience`/`xp` (MCLA/VL only)
  - [ ] `fog`
  - [ ] `forceload`
  - [ ] `gamemode` (in MTG, grants/revokes `creative`)
  - [ ] `gamerule`? (maybe equivalent to `changesetting`?)
  - [ ] `item`?
  - [ ] `kick`
  - [ ] `list`
  - [ ] `locate` (copy from or depend on Wuzzy's `findbiome`, maybe also support MCLA/VL end shrines)
  - [ ] `loot`
  - [ ] `music` (depending on various mods)
  - [ ] `pardon`
  - [ ] `pardon-ip`
  - [ ] `particle`
  - [ ] `place`
  - [ ] `random` (although seeds seem to be somewhat inconsistent in MT)
  - [ ] `recipe` (MCLA/VL only)
  - [ ] `remove`
  - [ ] `replaceitem`
  - [ ] `return`
  - [ ] `ride`?
  - [ ] `seed`
  - [ ] `setidletimeout`?
  - [ ] `spreadplayers`?
  - [ ] `stop`
  - [ ] `structure`?
  - [x] `summon`
  - [ ] `tag`
  - [ ] `teammsg`/`tm`
  - [ ] `testfor`
  - [ ] `testforblock`
  - [ ] `testforblocks`
  - [ ] `tickingarea`?
  - [ ] `toggledownfall` (depending on mods)
  - [ ] `weather` (depending on mods)
  - [ ] `whitelist`
  - [ ] `worldborder`? (maybe not visible, probably no collision)
- [ ] Add more selector arguments
  - [ ] `dx`/`dy`/`dz`
  - [ ] `x_rotation`/`rx`/`rxm`/`y_rotation`/`ry`/`rym`
  - [ ] `scores`
  - [ ] `tag`
  - [ ] `team`
  - [ ] `level`/`l`/`lm` (MCLA/VL only)
  - [ ] `gamemode`/`l`/`lm` (more of an "is creative?" command)
  - [ ] `advancements` (with MCLA/VL/awards), change syntax
  - [ ] `haspermission` (privs)