# Changelog

## v3.2
* Disabled unnecessary logging that was accidentally left in
* Updated license year and translation template.
* The repo is in the Minetest Mods organization now, which is pretty neat.

## v3.1
Fixes a crash caused by nodes being dug by non-players.

## v3.0
This is a small update, mostly composed of bugfixes. Lots of bugfixes. It's been over a year since I last updated this, and now I'm finally back.
### New features
* Added `/stop` command
* Added `/weather` command
* Added `/toggledownfall` command
* Added `/ride` command
* Added `@n` selector
### Bugfixes
* Leaving out arguments no longer fails to show the `params` string.
* Fixed `/old` and `/bc` crashing when used without arguments.
* Fixed unnecessary logging
* Fixed `/scoreboard objectives remove <objective>` causing a crash
* Maybe fixed command registration issue? For some reason, I can't reproduce it anymore, so I probably just fixed it months ago and then completely forgot about it.
* Fixed wrong argument order for `/scoreboard players operation ...`
* Fixed a LOT of random things.

## v2.0 (May 31, 2024)
### New features
* Added `gamemode`/`m` selector argument
* Added `level`/`l`/`lm` selector arguments
* Added node/item scoreboard criteria (support itemstrings, `group:groupname` and `\*`)
  * `picked_up.<itemstring>`
  * `mined.<itemstring>`
  * `dug.<itemstring>` (same as `mined`)
  * `placed.<itemstring>`
  * `crafted.<itemstring>`
  * `awards.<award>` (requires Awards mod)
* Added `ascending|descending` argument for `/scoreboard objectives setdisplay` (only if using the sidebar)
* Added `below_name` scoreboard display slot
* Added `/gamemode` command (grants/revokes `creative` priv in non-MCL games)
* Added `/spawnpoint` and `/clearspawnpoint` commands
* Added `/clear` command
* Added `/teammsg` command
* Added `/gamerule` and `/changesetting` commands
* Added `/remove` (removes entities instead of killing them)
* Added `/enchant` and `/forceenchant` commands (MCL only)
* Added `/damage` command
* Added `/op` and `/deop` (`/op` grants all privs, `/deop` revokes all but `default_privs`)
### Changes
* Reorganized the changelog (older versions are now at the bottom).
* Removed `anchored` execute subcommand (if you want to have rotation anchors, make a PR, because I can't think of any good way to do it)
* Command results are now shown to other players as well, unless `better_commands.send_command_feedback` is disabled
* Error messages are now red
* Some command messages now match ACOVG's better
### Bugfixes
* Fixed a bug with the `/kill` command (it should work now).
* The `rm`/`r` selector arguments now actually treat their values as numbers (not strings), and are now inclusive as intended.
* Fixed a potential issue with the `/execute` command that *might* have caused unintended behavior.
* Fixed crashing when trying to divide by 0 using `scoreboard players operation ... /= ...`
* Scoreboard values are now forced to be integers.
* Fixed a bug when trying to run on case-sensitive operating systems (I just switched to Linux, so that's been fun).
* Added missing wiki entries for `/playsound` and `/time` (don't know how I missed them).
* Objectives are now correctly removed from display slots when removed.

## v1.1 (May 5, 2024)
### Changes
* Removed a reference to ACOVG (hopefully the last)
* Added TODO.md
* Redid settings slightly (so it's easy to add more)
* Removed debug logging when using the `/kill` command

## v1.0 (May 5, 2024)
Initial release. Missing *lots* of commands, several `execute` subcommands, lots of scoreboard objectives, and lots of selector arguments.