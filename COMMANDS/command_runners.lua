--local bc = better_commands
local S = core.get_translator(core.get_current_modname())

better_commands.register_command("bc", {
    params = S("<command>"),
    description = S("Runs any Better Commands command, so Better Commands don't have to override existing commands"),
    privs = {},
    func = function(name, param, context)
        local command, command_param = param:match("^%/?([%S]+)%s*(.-)$")
        if not command then return false, better_commands.error(S("Missing command")), 0 end
        local def = better_commands.commands[command]
        if def then
            local privs = context.command_block
            local missing
            if not privs then privs, missing = core.check_player_privs(name, def.privs) end
            if privs then
                return def.real_func(name, command_param, context)
            else
                return false, better_commands.error(S("You don't have permission to run this command (missing privileges: @1)", table.concat(missing, ", "))), 0
            end
        else
            return false, better_commands.error(S("Invalid command: @1", command)), 0
        end
    end
})

better_commands.register_command("old", {
    params = S("<command>"),
    description = S("Runs any command that Better Commands has overridden"),
    privs = {},
    func = function(name, param, context)
        local command, command_param = param:match("^%/?([%S]+)%s*(.-)$")
        if not command then return false, better_commands.error(S("Missing command")), 0 end
        local def = better_commands.old_commands[command]
        if def then
            local privs = context.command_block
            local missing
            if not privs then privs, missing = core.check_player_privs(name, def.privs) end
            if privs then
                return def.real_func(name, command_param, context)
            else
                return false, better_commands.error(S("You don't have permission to run this command (missing privileges: @1)", table.concat(missing, ", "))), 0
            end
        else
            return false, better_commands.error(S("Invalid command: @1", command)), 0
        end
    end
})