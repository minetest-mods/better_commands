better_commands = {commands = {}, old_commands = {}, players = {}}

better_commands.mcl = core.get_modpath("mcl_core")
better_commands.awards = core.get_modpath("awards")

local modpath = core.get_modpath("better_commands")
dofile(modpath.."/settings.lua")
dofile(modpath.."/entity_aliases.lua")
dofile(modpath.."/API/API.lua")
dofile(modpath.."/COMMANDS/COMMANDS.lua")

-- Build list of all registered players (https://forum.luanti.org/viewtopic.php?t=21582)
core.after(0,function()
	for name in core.get_auth_handler().iterate() do
        better_commands.players[name] = true
	end
end)

core.register_on_newplayer(function(player)
    better_commands.players[player:get_player_name()] = true
end)