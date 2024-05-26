# Changelog

## v1.0 (May 5, 2024)
Initial release. Missing *lots* of commands, several `execute` subcommands, lots of scoreboard objectives, and lots of selector arguments.

## v1.1 (May 5, 2024)
### Changes
* Removed a reference to ACOVG (hopefully the last)
* Added TODO.md
* Redid settings slightly (so it's easy to add more)
* Removed debug logging when using the `/kill` command

## v2.0
### New features
* Added node/item scoreboard criteria (support itemstrings, `group:groupname` and `\*`)
  * `picked_up.<itemstring>`
  * `mined.<itemstring>`
  * `dug.<itemstring>` (same as `mined`)
  * `placed.<itemstring>`
  * `crafted.<itemstring>`
  * `awards.<award>` (requires Awards mod)
* Added `ascending|descending` argument for `/scoreboard objectives setdisplay`
* Added `/gamemode` command (grants/revokes `creative` priv in non-MCL games)
* Added `/spawnpoint` and `/clearspawnpoint` commands
* Added `gamemode`/`m` selector argument
* Added `level`/`l`/`lm` selector arguments
* Added `/clear` command
* Added `/teammsg` command
* Added `/gamerule` and `/changesetting` commands
### Bugfixes
* Fixed a bug with the `/kill` command (it should work now).
* The `rm`/`r` selector arguments now actually treat their values as numbers (not strings), and are now inclusive as intended.
* Fixed a potential issue with the `/execute` command that *might* have caused unintended behavior.
* Fixed crashing when trying to divide by 0 using `scoreboard players operation ... /= ...`
* Scoreboard values are now forced to be integers.
* Fixed a bug when trying to run on case-sensitive operating systems (I just switched to Linux, so that's been fun).