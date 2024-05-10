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
* Added `ascending|descending` argument for `/scoreboard objectives setdisplay`
* Added `/gamemode` (grants/revokes `creative` priv in non-MCL games)
* Added `gamemode`/`m` selector argument
* Added `level`/`l`/`lm` selector arguments
### Bugfixes
* The `/kill` command is more likely to successfully kill entities.
* The `rm`/`r` selector arguments now actually treat their values as numbers (not strings), and are now inclusive as intended.
* Fixed a potential issue with the `/execute` command that *might* have caused unintended behavior.