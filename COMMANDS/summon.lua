local S = minetest.get_translator(minetest.get_current_modname())
--local bc = better_commands

better_commands.register_command("summon", {
    description = S("Summons an entity"),
    params = S("<entity> [pos] [ (<yRot> [xRot]) | (facing <entity>) ])"),
    privs = {server = true},
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, minetest.colorize("red", S("Missing context")), 0 end
        if not context.executor then return false, minetest.colorize("red", S("Missing executor")), 0 end
        local split_param = better_commands.parse_params(param)
        local entity = split_param[1]
        if not entity then return false, minetest.colorize("red", S("Missing entity")), 0 end
        local checked_entity = better_commands.entity_from_alias(entity[3])
        if not checked_entity then return false, minetest.colorize("red", S("Invalid entity: @1", entity[3])), 0 end
        local summoned
        if split_param[2] then
            local pos, err = better_commands.parse_pos(split_param, 2, context)
            if err or not pos then return false, err, 0 end
            summoned = minetest.add_entity(pos, checked_entity, entity[4])
            if not summoned then return false, minetest.colorize("red", S("Could not summon @1", entity[3])), 0 end
            if split_param[5] then
                local victim_rot, err = better_commands.get_tp_rot(context, summoned, split_param, 5)
                if err or not victim_rot then return false, err, 0 end
                better_commands.set_entity_rotation(summoned, victim_rot)
            end
        else
            summoned = minetest.add_entity(context.pos, checked_entity, entity[4])
            if not summoned then return false, minetest.colorize("red", S("Could not summon @1", entity[3])), 0 end
        end
        return true, S("Summoned @1", better_commands.get_entity_name(summoned)), 1
    end
  })
