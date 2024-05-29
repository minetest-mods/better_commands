local S = minetest.get_translator(minetest.get_current_modname())
--local bc = better_commands

better_commands.register_command("summon", {
    description = S("Summons an entity"),
    params = S("<entity> [<pos>] [<rot>]"),
    privs = {server = true},
    func = function(name, param, context)
        local split_param = better_commands.parse_params(param)
        local entity = split_param[1]
        if not entity then return false, better_commands.error(S("Missing entity")), 0 end
        local checked_entity = better_commands.entity_from_alias(entity[3])
        if not checked_entity then return false, better_commands.error(S("Invalid entity: @1", entity[3])), 0 end
        local summoned
        if split_param[2] then
            local pos, err = better_commands.parse_pos(split_param, 2, context)
            if err or not pos then return false, better_commands.error(err), 0 end
            summoned = minetest.add_entity(pos, checked_entity, entity[4])
            if not summoned then return false, better_commands.error(S("Could not summon @1", entity[3])), 0 end
            if split_param[5] then
                local victim_rot, err = better_commands.get_tp_rot(context, summoned, split_param, 5)
                if err or not victim_rot then return false, better_commands.error(err), 0 end
                better_commands.set_entity_rotation(summoned, victim_rot)
            end
        else
            summoned = minetest.add_entity(context.pos, checked_entity, entity[4])
            if not summoned then return false, better_commands.error(S("Could not summon @1", entity[3])), 0 end
        end
        return true, S("Summoned @1", better_commands.get_entity_name(summoned)), 1
    end
  })
