--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("kill", {
    params = S("[target]"),
    description = S("Kills [target] or self"),
    privs = {server = true},
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, minetest.colorize("red", S("Missing context")), 0 end
        if not context.executor then return false, minetest.colorize("red", S("Missing executor")), 0 end
        if param == "" then param = "@s" end
        local split_param = better_commands.parse_params(param)
        local targets, err = better_commands.parse_selector(split_param[1], context)
        if err or not targets then return false, err, 0 end
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
            return false, minetest.colorize("red", S("No matching entity found")), 0
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
        if param ~= "" then return false, minetest.colorize("red", S("Unexpected argument: @1", param)), 0 end
        return better_commands.commands.kill.func(name, "", context)
    end
})