--local bc = better_commands
local S = core.get_translator(core.get_current_modname())

better_commands.register_command("kill", {
    params = S("[<targets>]"),
    description = S("Kills entities (or self if <targets> left out)"),
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
                if better_commands.settings.kill_creative_players or not (target:is_player() and core.is_creative_enabled(target:get_player_name())) then
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
    params = S("[<target>]"),
    description = S("Removes entities (or self if <entity> left out)"),
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
                    if better_commands.settings.kill_creative_players or not (core.is_creative_enabled(target:get_player_name())) then
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

better_commands.register_command("damage", {
    params = S("<targets> <amount> [type] [by <cause>]"),
    description = S("Damages entities."),
    privs = {server = true},
    func = function (name, param, context)
        local split_param = better_commands.parse_params(param)
        local selector = split_param[1]
        local amount = split_param[2] and tonumber(split_param[2][3])
        if not (selector and amount) then return false, better_commands.error(S("Missing argument")), 0 end
        amount = math.floor(amount)
        if amount < 1 then return false, better_commands.error(S("<amount> must not be negative")), 0 end
        local damage_type = split_param[3] and split_param[3][3] or "set_hp"
        local cause = (split_param[4] and split_param[4][3] == "by") and split_param[5]
        local damage_source
        if cause then
            local results, err = better_commands.parse_selector(cause, context, true)
            if err or not results then return false, better_commands.error(err), 0 end
            damage_source = results[1]
        end
        local reason = {
            type = damage_type,
            object = damage_source,
        }
        if better_commands.mcl2 and damage_type then
            if mcl_damage.types[damage_type] then
                reason._mcl_reason = table.copy(reason)
                reason.type = nil
            end
        end
        local targets, err = better_commands.parse_selector(selector, context)
        if err or not targets then return false, better_commands.error(err), 0 end
        local count = 0
        local last
        for _, target in ipairs(targets) do
            if target.is_player then
                count = count + 1
                last = better_commands.get_entity_name(target)
---@diagnostic disable-next-line: param-type-mismatch
                better_commands.deal_damage(target, amount, reason, true)
            end
        end
		if count < 1 then
			return false, better_commands.error(S("No entity was found")), 0
		elseif count == 1 then
			return true, S("Applied @1 damage to @2", amount, last), 1
		else
			return true, S("Applied @1 damage to @2 entities", amount, count), count
		end
    end
})