local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("spawnpoint", {
    description = S("Sets players' spawnpoints"),
    privs = {server = true},
    params = S("[targets]"),
    func = function (name, param, context)
        local split_param, err = better_commands.parse_params(param)
        if err then return false, better_commands.error(err), 0 end
        local selector = split_param[1]
        if not selector then
            if context.executor.is_player and context.executor:is_player() then
                better_commands.spawnpoints[context.executor:get_player_name()] = context.pos
                return true, S("Spawn point set"), 1
            else
                return false, better_commands.error(S("Non-player entities are not supported by this command"))
            end
        else
            local targets, err = better_commands.parse_selector(selector, context)
            if err or not targets then return false, better_commands.error(err), 0 end
            local last
            local count = 0
            for _, target in ipairs(targets) do
                if target.is_player and target:is_player() then
                    better_commands.spawnpoints[target:get_player_name()] = context.pos
                    count = count + 1
                    last = better_commands.get_entity_name(target)
                end
            end
            if count < 1 then
                return false, better_commands.error(S("No player was found.")), 0
            elseif count == 1 then
                return true, S("Set spawn point to @1 for @2", minetest.pos_to_string(context.pos, 1), last), 1
            else
                return true, S("Set spawn point to @1 for @2 players", minetest.pos_to_string(context.pos, 1), count), count
            end
        end
    end
})

better_commands.register_command("clearspawnpoint", {
    description = S("Clear players' spawnpoints"),
    privs = {server = true},
    params = S("[targets]"),
    func = function (name, param, context)
        local split_param, err = better_commands.parse_params(param)
        if err then return false, better_commands.error(err), 0 end
        local selector = split_param[1]
        if not selector then
            if context.executor.is_player and context.executor:is_player() then
                better_commands.spawnpoints[context.executor:get_player_name()] = nil
                return true, S("Spawn point cleared"), 1
            else
                return false, better_commands.error(S("Non-player entities are not supported by this command"))
            end
        else
            local targets, err = better_commands.parse_selector(selector, context)
            if err or not targets then return false, better_commands.error(err), 0 end
            local last
            local count = 0
            for _, target in ipairs(targets) do
                if target.is_player and target:is_player() then
                    better_commands.spawnpoints[target:get_player_name()] = nil
                    count = count + 1
                    last = better_commands.get_entity_name(target)
                end
            end
            if count < 1 then
                return false, better_commands.error(S("No player was found.")), 0
            elseif count == 1 then
                return true, S("Cleared spawn point for @2", last), 1
            else
                return true, S("Set spawn point for @2 players", count), count
            end
        end
    end
})