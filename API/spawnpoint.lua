minetest.register_on_mods_loaded(function()
    minetest.register_on_respawnplayer(function(player)
        local name = player:get_player_name()
        if better_commands.spawnpoints[name] then
            player:set_pos(better_commands.spawnpoints[name])
            return true
        end
    end)
end)