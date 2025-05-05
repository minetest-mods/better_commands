# Better Commands
Adds commands and syntax from a certain other voxel game (such as `/kill @e[type=mobs_mc:zombie, distance = 2..]`) to Luanti. For compatible command blocks, use my [Better Command Blocks](https://content.luanti.org/packages/ThePython/better_command_blocks/) mod. I'm basically copying them from a certain other voxel game (whose name will not be mentioned), hereafter referred to as ACOVG.

## Links
* [Wiki](https://thepython10110.gitbook.io/better-commands)
* [GitHub](https://github.com/thepython10110/better_commands)
* [ContentDB](https://content.luanti.org/packages/ThePython/better_commands)
* [Forum](https://forum.luanti.org/viewtopic.php?t=30370)
* [Changelog](./CHANGELOG.md)
* [Translation](https://hosted.weblate.org/guide/better-commands/better-commands/) (Weblate)

### PLEASE help with bug reports and PR's
This is kind of a huge project. ACOVG's commands are complicated.

## Known Issues:
1. I ~~can't~~ am too lazy to figure out how to do quotes or escape characters. This means that you cannot do things like `/kill @e[name="Trailing space "]` or have `]` in any part of entity/item/node data.
2. `/tp` does not support the `checkForBlocks` argument present in one version of ACOVG. This *might* change in the future.
3. Only entities that use `luaentity.nametag` or `luaentity._nametag` for nametags (and players, of course) are supported by the `name` selector argument. This includes all mobs from MCLA/VL and Mobs Redo, but potentially not others.
4. `/setblock` only supports `replace` or `keep`, not destroy, and only places nodes using `set_node`. Some nodes may not act right since they weren't placed by a player. You could, in theory, look at the node's code and set its metadata...
5. `/time` does not properly add to the day count. This will not be fixed.
6. Only players and fake players (not other entities) are supported by scoreboards, teams, and entity tags, since other entities don't have UUIDs. This *might* change.
7. Except in MCLA/VL, the `playerKillCount` and `killed_by`, `teamkill`, and `killedByTeam` objectives can only track direct kills (so not arrows or explosions, for example).
8. Objectives cannot be displayed as hearts, although literally the only reason is that there's no good half heart character.
9.  Team prefixes and suffixes have been replaced with `nameFormat` (for example, `/team modify a_nice_team nameFormat [Admin] %s the great`), where any `%s` is replaced with the player's name. If your name was `singleplayer`, it would appear as `[Admin] singleplayer the great`. The reason for this is pretty simple: I don't want to figure out how to do quotes, and Luanti removes trailing space, meaning prefixes ending in spaces are impossible. This fixes that.
10. The `/give` command is currently unable to give multiple tools (so `/give @s default:pick_wood 5` will only give 1). This may change.
11. If you have a respawn point set with `/spawnpoint`, there is *no way* to clear it besides the `/clearspawnpoint` command. This will probably not change, since various games and mods set respawn points in different ways, and there's no way to make it compatible with all of them.