--local bc = better_commands
local S = core.get_translator(core.get_current_modname())

-- some duplicate code
better_commands.register_command("teleport", {
    params = S("[<targets>] <location/entity> [<rot>]"),
    description = S("Teleports and rotates things"),
    privs = {server = true},
    func = function(name, param, context)
        local split_param = better_commands.parse_params(param)
        if not split_param[1] then return false, nil, 0 end
        if split_param[1].type == "selector" then
            if not split_param[2] then
                if not context.executor.is_player then
                    return false, better_commands.error(S("Command blocks can't teleport (although I did consider making it possible)")), 0
                end
                local targets, err = better_commands.parse_selector(split_param[1], context, true)
                if err or not targets then return false, better_commands.error(err), 0 end
                local target_pos = targets[1].is_player and targets[1]:get_pos() or targets[1]
                context.executor:set_pos(target_pos)
                context.executor:add_velocity(-context.executor:get_velocity())
                local rotation = better_commands.get_entity_rotation(targets[1])
                better_commands.set_entity_rotation(context.executor, rotation)
                return true, S("Teleported @1 to @2", better_commands.get_entity_name(context.executor), better_commands.get_entity_name(targets[1])), 1
            elseif split_param[2].type == "selector" then
                if not context.executor.is_player and split_param[1][3] == "@s" then
                    return false, better_commands.error(S("Command blocks can't teleport (although I did consider making it possible)")), 0
                end
                local victims, err = better_commands.parse_selector(split_param[1], context)
                if err or not victims then return false, better_commands.error(err), 0 end
                if #victims == 0 then
                    return false, better_commands.error(S("No entity was found")), 0
                end
                local targets, err  = better_commands.parse_selector(split_param[2], context, true)
                if err or not targets then return false, better_commands.error(err), 0 end
                local target_pos = targets[1].is_player and targets[1]:get_pos() or targets[1]
                local count = 0
                local last
                for _, victim in ipairs(victims) do
                    if victim.is_player then
                        count = count + 1
                        last = better_commands.get_entity_name(victim)
                        victim:set_pos(target_pos)
                        victim:add_velocity(-victim:get_velocity())
                        local rotation = better_commands.get_entity_rotation(targets[1])
                        better_commands.set_entity_rotation(victim, rotation)
                    end
                end
                if count < 1 then
                    return false, better_commands.error(S("No entities found")), 0
                elseif count == 1 then
                    return true, S(
                        "Teleported @1 to @2",
                        last,
                        better_commands.get_entity_name(targets[1])
                    ),
                    1
                else
                    return true, S(
                        "Teleported @1 entities to @2",
                        count,
                        better_commands.get_entity_name(targets[1])
                    ),
                    count
                end
            elseif split_param[2].type == "number" or split_param[2].type == "relative" or split_param[2].type == "look_relative" then
                if not context.executor.is_player and split_param[1][3] == "@s" then
                    return false, better_commands.error(S("Command blocks can't teleport (although I did consider making it possible)")), 0
                end
                local victims, err = better_commands.parse_selector(split_param[1], context)
                if err or not victims then return false, better_commands.error(err), 0 end
                local target_pos, err = better_commands.parse_pos(split_param, 2, context)
                if err then return false, better_commands.error(err), 0 end
                local count = 0
                local last
                for _, victim in ipairs(victims) do
                    if victim.is_player then
                        count = count+1
                        last = better_commands.get_entity_name(victim)
                        victim:set_pos(target_pos)
                        if not (split_param[2].type == "look_relative"
                        or split_param[2].type == "relative"
                        or split_param[3].type == "relative"
                        or split_param[4].type == "relative") then
                            victim:add_velocity(-victim:get_velocity())
                        end
                        local victim_rot, err = better_commands.get_tp_rot(context, victim, split_param, 5)
                        if err then return false, better_commands.error(err), 0 end
                        if victim_rot then
                            better_commands.set_entity_rotation(victim, victim_rot)
                        end
                    end
                end
                if count < 1 then
                    return false, better_commands.error(S("No entities found")), 0
                elseif count == 1 then
                    return true, S("Teleported @1 to @2", last, core.pos_to_string(target_pos, 1)), 1
                else
                    return true, S("Teleported @1 entities to @2", count, core.pos_to_string(target_pos, 1)), count
                end
            end
        elseif split_param[1].type == "number" or split_param[1].type == "relative" or split_param[1].type == "look_relative" then
            if not context.executor.is_player and split_param[1][3] == "@s" then
                return false, better_commands.error(S("Command blocks can't teleport (although I did consider making it possible)")), 0
            end
            local target_pos, err = better_commands.parse_pos(split_param, 1, context)
            if err then
                return false, better_commands.error(err), 0
            end
            context.executor:set_pos(target_pos)
            if not (split_param[1].type == "look_relative"
            or split_param[1].type == "relative"
            or split_param[2].type == "relative"
            or split_param[3].type == "relative") then
                context.executor:add_velocity(-context.executor:get_velocity())
            end
            local victim_rot, err = better_commands.get_tp_rot(context, context.executor, split_param, 4)
            if err or not victim_rot then return false, better_commands.error(err), 0 end
            better_commands.set_entity_rotation(context.executor, victim_rot)
            return true, S("Teleported @1 to @2", better_commands.get_entity_name(context.executor), core.pos_to_string(target_pos, 1)), 1
        end
        return false, nil, 0
    end
})

better_commands.register_command_alias("tp", "teleport")