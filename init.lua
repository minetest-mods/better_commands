better_commands = {commands = {}, old_commands = {}, players = {}}

better_commands.override = minetest.settings:get_bool("better_commands_override", false)
better_commands.mc_time = minetest.settings:get_bool("better_commands_mc_time", false)
better_commands.save_interval = tonumber(minetest.settings:get("better_commands_save_interval")) or 3
better_commands.kill_creative_players = minetest.settings:get_bool("better_commands_kill_creative_players", false)
better_commands.mcl = minetest.get_modpath("mcl_core")

local modpath = minetest.get_modpath("better_commands")
dofile(modpath.."/entity_aliases.lua")
dofile(modpath.."/API/api.lua")
dofile(modpath.."/COMMANDS/commands.lua")

-- Build list of all registered players (https://forum.minetest.net/viewtopic.php?t=21582)
minetest.after(0,function()
	for name in minetest.get_auth_handler().iterate() do
        better_commands.players[name] = true
	end
end)

minetest.register_on_newplayer(function(player)
    better_commands.players[player:get_player_name()] = true
end)