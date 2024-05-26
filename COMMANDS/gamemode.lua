local S = minetest.get_translator("better_commands")

better_commands.gamemode_aliases = {
    [0] = "survival",
    [1] = "creative",
    --[2] = "adventure",
    s = "survival",
    c = "creative",
    --a = "adventure"
}

better_commands.register_command("gamemode", {
    description = S("Sets a player's gamemode"),
    params = S("<gamemode> [player]"),
    privs = {server = true},
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, S("Missing context"), 0 end
        if not context.executor then return false, S("Missing executor"), 0 end
        local split_param, err = better_commands.parse_params(param)
        if err then return false, err, 0 end
        local gamemode = split_param[1] and split_param[1][3]
        if not gamemode then return false, S("Missing gamemode"), 0 end
        gamemode = better_commands.gamemode_aliases[gamemode] or gamemode
        if better_commands.mcl then
            if table.indexof(mcl_gamemode.gamemodes, gamemode) == -1 then
                return false, S("Invalid gamemode @1", gamemode), 0
            end
        elseif gamemode ~= "creative" and gamemode ~= "survival" then
            return false, S("Invalid gamemode @1", gamemode), 0
        end
        local targets = {context.executor}
        local self = true
        if split_param[2] then
            local err
            targets, err = better_commands.parse_selector(split_param[2], context)
            if err or not targets then return false, err, 0 end
            self = false
        end
        local count = 0
        local last
        for _, target in ipairs(targets) do
            if target.is_player and target:is_player() then
                local current_gamemode = better_commands.get_gamemode(target)
                if current_gamemode ~= gamemode then
                    count = count + 1
                    last = better_commands.get_entity_name(target)
                    if better_commands.mcl then
                        mcl_gamemode.set_gamemode(target, gamemode)
                    else
                        local privs = minetest.get_player_privs(target:get_player_name())
                        if gamemode == "creative" then
                            privs.creative = true
                        else
                            privs.creative = nil
                        end
                        minetest.set_player_privs(target:get_player_name(), privs)
                    end
                end
            end
        end
        if count < 1 then
            return false, S("No player was found"), 0
        elseif count == 1 then
            if self then
                return true, S("Set own gamemode to @1", gamemode)
            end
            return true, S("Set gamemode of @1 to @2", last, gamemode), 1
        else
            return true, S("Set gamemode of @1 players to @2", count, gamemode), count
        end
    end
})