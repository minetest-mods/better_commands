S = core.get_translator(core.get_current_modname())

better_commands.register_command("ride", {
    description = "Allows entities to mount or dismount other entities.",
    params = "<target> <action> [vehicle|entityType] [bone] [pos] [rot] [teleportRules]",
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
---@diagnostic disable-next-line: cast-local-type
                pos, err = better_commands.parse_pos(split_param, 5, context)
                if err or not pos then return false, better_commands.error(err), 0 end
                if split_param[8] then
---@diagnostic disable-next-line: cast-local-type
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
            if not target[1].is_player then
                return false, better_commands.error(S("Command blocks cannot be ridden")), 0
            end
            local vehicle, err = better_commands.parse_selector(vehicle_selector, context, true)
            if err or not vehicle then return false, better_commands.error(err), 0 end
            local parent_check = vehicle[1]
            while parent_check do
                if target[1] == parent_check then
                    return false, better_commands.error("Can't mount entity on itself or any of its passengers"), 0
                end
                parent_check = parent_check:get_attach()
            end
            if teleport_ride then
                vehicle[1]:set_pos(target[1]:get_pos())
            end
            target[1]:set_attach(vehicle[1], bone, pos, rot)
            return true, S("@1 started riding @2", better_commands.get_entity_name(target[1]), better_commands.get_entity_name(vehicle[1])), 1
        elseif action == "dismount" or action == "stop_riding" then
            local target, err = better_commands.parse_selector(target_selector, context, true)
            if err or not target then return false, better_commands.error(err), 0 end
            if not target[1].is_player then
                return false, better_commands.error(S("Command blocks cannot be ridden")), 0
            end
            local vehicle = target[1]:get_attach()
            if not vehicle then return false, better_commands.error(S("@1 is not riding any vehicle", better_commands.get_entity_name(target[1]))), 0 end
            target[1]:set_detach()
            return true, S("@1 stopped riding @2", better_commands.get_entity_name(target[1]), better_commands.get_entity_name(vehicle)), 1
        end
        return false, nil, 0
    end
})