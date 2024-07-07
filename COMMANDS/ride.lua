S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("ride", {
    description = "Allows entities to mount or dismount other entities.",
    params = "<target> <action> [vehicle|entityType] [bone] [pos] [rot] [teleportRules] [nameTag] [rideRules]",
    privs = {server = true},
    func = function (name, param, context)
        local split_param, err = better_commands.parse_params(param)
        if err or not split_param then return false, better_commands.error(err), 0 end
        local target_selector = split_param[1]
        if not target_selector then return false, better_commands.error(S("Missing target")), 0 end
        local action = split_param[2] and split_param[2][3]
        if not action then return false, better_commands.error(S("Missing action")), 0 end
        if action == "mount" or action == "start_riding" then
            local vehicle_selector = split_param[3]
            local teleport_ride, bone, pos,           rot, err =
                  false,         "",   vector.zero(), vector.zero()
            if not vehicle_selector then return false, better_commands.error(S("Missing vehicle")), 0 end
            bone = split_param[4] and split_param[4][3]
            if not bone or bone == "_" then bone = "" end
            if split_param[5] then
                pos, err = better_commands.parse_pos(split_param, 5, context)
                if err or not pos then return false, better_commands.error(err), 0 end
                if split_param[8] then
                    rot, err = better_commands.handle_vector2_rot(rot, split_param, 8, false)
                    if err or not rot then return false, better_commands.error(err), 0 end
                    local teleport_rules = split_param[10] and split_param[10][3]
                    if teleport_rules then
                        if teleport_rules == "teleport_ride" then
                            teleport_ride = true
                        elseif teleport_rules ~= "teleport_rider" then
                            return false, better_commands.error(S("Expected teleport_ride|teleport_rider, got @1", teleport_rules)), 0
                        end
                    end
                end
            end
            local target, err = better_commands.parse_selector(target_selector, context, true)
            if err or not target then return false, better_commands.error(err), 0 end
            local vehicle, err = better_commands.parse_selector(vehicle_selector, context, true)
            if err or not vehicle then return false, better_commands.error(err), 0 end
            if target[1] == vehicle[1] then
                return false, better_commands.error("Cannot attach entity to itself"), 0
            end
            target[1]:set_attach(vehicle[1], bone, pos, rot)
            return true, S("Attached @1 to @2", better_commands.get_entity_name(target[1]), better_commands.get_entity_name(vehicle[1])), 1
        end
        return false, nil, 0
    end
})