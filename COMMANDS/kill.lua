--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("kill", {
    params = S("[target]"),
    description = S("Kills [target] or self"),
    privs = {server = true},
    func = function(name, param, context)
        if param == "" then param = "@s" end
        local split_param = better_commands.parse_params(param)
        local targets, err = better_commands.parse_selector(split_param[1], context)
        if err or not targets then return false, better_commands.error(err), 0 end
        local count = 0
        local last
        for _, target in ipairs(targets) do
            if target.is_player then
                if better_commands.settings.kill_creative_players or not (target:is_player() and minetest.is_creative_enabled(target:get_player_name())) then
                    last = better_commands.get_entity_name(target)
                    better_commands.deal_damage(
                        ---@diagnostic disable-next-line: param-type-mismatch
                        target,
                        math.max(target:get_hp(), 1000000000000), -- 1 trillion damage to make sure they die :D
                        {
                            type = "set_hp",
                            bypasses_totem = true,
                            flags = {bypasses_totem = true},
                            better_commands = "kill"
                        },
                        true
                    )
                    count = count + 1
                end
            end
        end
        if count < 1 then
            return false, better_commands.error(S("No entity was found")), 0
        elseif count == 1 then
            return true, S("Killed @1", last), count
        else
            return true, S("Killed @1 entities", count), count
        end
    end
})

better_commands.register_command("killme", {
    params = S(""),
    description = S("Kills self"),
    privs = {server = true},
    func = function(name, param, context)
        if param ~= "" then return false, better_commands.error(S("Unexpected argument(s) '@1'", param)), 0 end
        return better_commands.commands.kill.real_func(name, "", context)
    end
})

better_commands.register_command("remove", {
    params = S("[target]"),
    description = S("Kills players and removes entities"),
    privs = {server = true},
    func = function (name, param, context)
        if param == "" then param = "@s" end
        local split_param = better_commands.parse_params(param)
        local targets, err = better_commands.parse_selector(split_param[1], context)
        if err or not targets then return false, better_commands.error(err), 0 end
        local count = 0
        local last
        for _, target in ipairs(targets) do
            if target.is_player then
                if target:is_player() then
                    if better_commands.settings.kill_creative_players or not (minetest.is_creative_enabled(target:get_player_name())) then
                        last = better_commands.get_entity_name(target)
                        better_commands.deal_damage(
                            ---@diagnostic disable-next-line: param-type-mismatch
                            target,
                            math.max(target:get_hp(), 1000000000000), -- 1 trillion damage to make sure they die :D
                            {
                                type = "set_hp",
                                bypasses_totem = true,
                                flags = {bypasses_totem = true},
                                better_commands = "kill"
                            },
                            true
                        )
                        count = count + 1
                    end
                else
                    count = count + 1
                    last = better_commands.get_entity_name(target)
                    target:remove()
                end
            end
        end
        if count < 1 then
            return false, better_commands.error(S("No entity was found")), 0
        elseif count == 1 then
            return true, S("Killed @1", last), count
        else
            return true, S("Killed @1 entities", count), count
        end
    end
})