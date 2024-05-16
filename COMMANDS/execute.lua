--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

better_commands.execute_subcommands = {
    ---Aligns relative to certain axes
    ---@param branches contextTable[]
    ---@param index integer
    ---@return boolean
    ---@return string?
    ---@nodiscard
    align = function(branches, index)
        local branch_data = branches[index]
        local param = branches.param[branch_data.i+1]
        if not param then return false, S("Missing argument for subcommand @1", "align") end
        local axes = {param[3]:match("^([xyz])([xyz]?)([xyz]?)$")}
        if not axes[1] then return false, S("Invalid swizzle, expected combination of 'x', 'y', and 'z'") end
        for _ ,axis in pairs(axes) do
            branch_data.pos[axis] = math.floor(branch_data.pos[axis])
        end
        branch_data.i = branch_data.i + 2
        return true
    end,
    ---Sets anchor to feet or eyes
    ---@param branches contextTable[]
    ---@param index integer
    ---@return boolean
    ---@return string?
    ---@nodiscard
    anchored = function(branches, index)
        local branch_data = branches[index]
        local param = branches.param[branch_data.i+1]
        if not param then return false, S("Missing argument for subcommand @1", "anchored") end
        local anchor = tostring(param[3]):lower()
        if anchor == "feet" or anchor == "eyes" then
            branch_data.anchor = anchor
        else
            return false, S("Invalid entity anchor position @1", anchor)
        end
        branch_data.i = branch_data.i + 2
        return true
    end,
    ---Changes executor
    ---@param branches contextTable[]
    ---@param index integer
    ---@return boolean|string
    ---@return string?
    ---@nodiscard
    as = function(branches, index)
        local branch_data = branches[index]
        local param = branches.param[branch_data.i+1]
        if not param then return false, S("Missing argument for subcommand @1", "as") end
        if param.type ~= "selector" then
            return false, S("Invalid target: @1", table.concat(param, "", 3))
        end
        local targets, err = better_commands.parse_selector(param, branch_data)
        if err or not targets then return false, err end
        if #targets > 1 then
            for _, target in ipairs(targets) do
                local new_branch = table.copy(branch_data)
                new_branch.executor = target
                new_branch.i = new_branch.i + 2
                table.insert(branches, new_branch)
            end
            return "branched"
        elseif #targets == 1 then
            branch_data.executor = targets[1]
            branch_data.i = branch_data.i + 2
            return true
        else
            return "notarget"
        end
    end,
    ---Changes position
    ---@param branches contextTable[]
    ---@param index integer
    ---@return boolean|string
    ---@return string?
    ---@nodiscard
    at = function(branches, index)
        local branch_data = branches[index]
        local param = branches.param[branch_data.i+1]
        if not param then return false, S("Missing argument for subcommand @1", "at") end
        if param.type ~= "selector" then
            return false, S("Invalid target: @1", table.concat(param, "", 3))
        end
        local targets, err = better_commands.parse_selector(param, branch_data)
        if err or not targets then return false, err end
        if #targets > 1 then
            for _, target in ipairs(targets) do
                local new_branch = table.copy(branch_data)
                new_branch.pos = target.get_pos and target:get_pos() or target
                branch_data.rot = better_commands.get_entity_rotation(target) or branch_data.rot
                new_branch.i = new_branch.i + 2
                table.insert(branches, new_branch)
            end
            return "branched"
        elseif #targets == 1 then
            branch_data.pos = targets[1].get_pos and targets[1]:get_pos() or targets[1]
            branch_data.rot = better_commands.get_entity_rotation(targets[1]) or branch_data.rot
            branch_data.i = branch_data.i + 2
            return true
        else
            return "notarget"
        end
    end,
    ---Changes rotation
    ---@param branches contextTable[]
    ---@param index integer
    ---@return boolean|string
    ---@return string?
    ---@nodiscard
    facing = function(branches, index)
        local branch_data = branches[index]
        local split_param = branches.param
        local i = branch_data.i
        if split_param[i+1] then
            if split_param[i+1][3] == "entity" and split_param[i+2] then
                local targets, err = better_commands.parse_selector(split_param[i+2], branch_data)
                if err or not targets then return false, err end
                if #targets > 1 then
                    for _, target in ipairs(targets) do
                        local target_pos = target.get_pos and target:get_pos() or target
                        local new_branch = table.copy(branch_data)
---@diagnostic disable-next-line: param-type-mismatch
                        new_branch.rot = better_commands.point_at_pos(branch_data.executor, target_pos)
                        new_branch.i = branch_data.i + 3
                    end
                    return "branched"
                elseif #targets == 1 then
                    local target_pos = targets[1].get_pos and targets[1]:get_pos() or targets[1]
---@diagnostic disable-next-line: param-type-mismatch
                    branch_data.rot = better_commands.point_at_pos(branch_data.executor, target_pos)
                    branch_data.i = branch_data.i + 3
                    return true
                else
                    return "notarget"
                end
            else
                local target_pos, err = better_commands.parse_pos(split_param, i+1, branch_data)
                if err then
                    return false, err
                end
---@diagnostic disable-next-line: param-type-mismatch
                branch_data.rot = better_commands.point_at_pos(branch_data.executor, target_pos)
                branch_data.i = branch_data.i + 4
                return true
            end
        end
        return true
    end,
    ---Changes position
    ---@param branches contextTable[]
    ---@param index integer
    ---@return boolean|string
    ---@return string?
    ---@nodiscard
    positioned = function(branches, index)
        local branch_data = branches[index]
        local param = branches.param[branch_data.i+1]
        if not param then return false, S("Missing argument for subcommand @1", "positioned") end
        if param[3] == "as" then
            local selector = branches.param[branch_data.i+2]
            if not selector or selector.type ~= "selector" then
                return false, S("Invalid argument for @1", "positioned")
            end
            local targets, err = better_commands.parse_selector(selector, branch_data)
            if err or not targets then return false, err end
            if #targets > 1 then
                for _, target in ipairs(targets) do
                    local new_branch = table.copy(branch_data)
                    branch_data.pos = target.get_pos and target:get_pos() or target
                    new_branch.i = new_branch.i + 3
                    table.insert(branches, new_branch)
                end
                return "branched"
            elseif #targets == 1 then
                branch_data.pos = targets[1].get_pos and targets[1]:get_pos() or targets[1]
                branch_data.i = branch_data.i + 3
                return true
            else
                return "notarget"
            end
        else
            local pos, err = better_commands.parse_pos(branches.param, branch_data.i+1, branch_data)
            if err then return false, err end
            branch_data.pos = pos
            branch_data.anchor = "feet"
            branch_data.i = branch_data.i + 4
            return true
        end
    end,
    ---Changes rotation
    ---@param branches contextTable[]
    ---@param index integer
    ---@return boolean|string
    ---@return string?
    ---@nodiscard
    rotated = function(branches, index)
        local branch_data = branches[index]
        local param = branches.param[branch_data.i+1]
        if not param then return false, S("Missing argument for subcommand @1", "rotated") end
        if param[3] == "as" then
            local selector = branches.param[branch_data.i+2]
            if not selector or selector.type ~= "selector" then
                return false, S("Invalid argument for rotated")
            end
            local targets, err = better_commands.parse_selector(selector, branch_data)
            if err or not targets then return false, err end
            if #targets > 1 then
                for _, target in ipairs(targets) do
                    local new_branch = table.copy(branch_data)
                    branch_data.rot = better_commands.get_entity_rotation(target) or branch_data.rot
                    new_branch.i = new_branch.i + 3
                    table.insert(branches, new_branch)
                end
                return "branched"
            elseif #targets == 1 then
                branch_data.rot = better_commands.get_entity_rotation(targets[1]) or branch_data.rot
                branch_data.i = branch_data.i + 3
                return true
            else
                return "notarget"
            end
        else
            if not (branches.param[branch_data.i+1] and branches.param[branch_data.i+2]) then
                return false, S("Missing argument(s) for rotated")
            end
            local victim_rot = branch_data.rot
            if branches.param[branch_data.i+1].type == "number" then
                victim_rot.y = math.rad(tonumber(branches.param[branch_data.i+1][3]) or 0)
            elseif branches.param[branch_data.i+1].type == "relative" then
                victim_rot.y = victim_rot.y+math.rad(tonumber(branches.param[branch_data.i+1][3]:sub(2,-1)) or 0)
            else
                return false, S("Invalid argument for rotated")
            end
            if branches.param[branch_data.i+2].type == "number" then
                victim_rot.x = math.rad(tonumber(branches.param[branch_data.i+2][3]) or 0)
            elseif branches.param[branch_data.i+2].type == "relative" then
                victim_rot.x = victim_rot.x+math.rad(tonumber(branches.param[branch_data.i+2][3]:sub(2,-1)) or 0)
            else
                return false, S("Invalid argument for rotated")
            end
            branch_data.rot = victim_rot
            branch_data.i = branch_data.i + 3
            return true
        end
    end,
    ---Runs a command
    ---@param branches contextTable[]
    ---@param index integer
    ---@return boolean|string
    ---@return string?
    ---@nodiscard
    run = function(branches, index)
        local branch_data = branches[index]
        if not (
            branch_data.executor
            and branch_data.executor.get_pos
            and branch_data.pos and type(branch_data.pos) == "table"
        ) then
            return "notarget"
        end
        if not branches.param[branch_data.i+1] then return false, S("Missing command") end
        local command, command_param
        command, command_param = branch_data.original_command:match(
            "%/?([%S]+)%s*(.-)$",
            branches.param[branch_data.i+1][1]
        )
        while command == "bc" do
            branch_data.i = branch_data.i + 1
            command, command_param = branch_data.original_command:match(
                "%/?([%S]+)%s*(.-)$",
                branches.param[branch_data.i+1][1]
            )
        end
        if command == "execute" then
            branch_data.i = branch_data.i + 2
            return true
        end
        local def = better_commands.commands[command]
        if def and command ~= "old" and (branch_data.command_block or minetest.check_player_privs(branch_data.origin, def.privs)) then
            return "done", def.func(branch_data.origin, command_param, table.copy(branch_data))
        else
            return false, S("Invalid command or privs: @1", command)
        end
    end
}

better_commands.register_command("execute", {
    params = S("<align|anchored|as|at|facing|positioned|rotated|run> ..."),
    description = S("Run any Better Command (not other commands) after changing the context"),
    privs = {server = true, ban = true, privs = true},
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, S("Missing context"), 0 end
        if not context.executor then return false, S("Missing executor"), 0 end
        local split_param = better_commands.parse_params(param)
        if not split_param[1] then return false, nil, 0 end
        local branch = 1
        local branches = {param = split_param}
        branches[1] = table.copy(context)
        branches[1].i = 1
        branches[1].original_command = param
        local success_count = 0
        while true do -- for each branch:
            local status, message, command_output, count
            while true do -- for each subcommand:
                local cmd_index = branches[branch].i
                if cmd_index > #split_param then break end
                local subcmd = split_param[cmd_index][3]
                if better_commands.execute_subcommands[subcmd] then
                    status, message, command_output, count = better_commands.execute_subcommands[subcmd](branches, branch)
                    if not status then return status, message, 0 end
                    if status == "branched" or status == "notarget" or status == "done" then
                        break
                    end
                else
                    return false, S("Invalid subcommand: @1", subcmd), 0
                end
            end
            if status == "done" then
                success_count = success_count + (message and 1 or 0) -- "message" is status when done
                if command_output then
                    minetest.chat_send_player(name, command_output)
                end
            end
            if branch >= #branches then
                break
            else
                branch = branch + 1
            end
        end
        return true, S("Successfully executed @1 times", success_count), success_count
    end
})