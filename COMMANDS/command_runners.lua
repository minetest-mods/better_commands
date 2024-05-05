--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("bc", {
    params = "<command data>",
    description = S("Runs any Better Commands command, so Better Commands don't have to override existing commands"),
    privs = {},
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, S("Missing context"), 0 end
        if not context.executor then return false, S("Missing executor"), 0 end
        local command, command_param = param:match("^%/?([%S]+)%s*(.-)$")
        local def = better_commands.commands[command]
        if def then
            local privs = context.command_block
            local missing
            if not privs then privs, missing = minetest.check_player_privs(name, def.privs) end
            if privs then
                return def.func(name, command_param, context)
            else
                return false, S("You don't have permission to run this command (missing privileges: @1)", table.concat(missing, ", ")), 0
            end
        else
            return false, S("Invalid command: @1", command), 0
        end
    end
})

better_commands.register_command("old", {
    params = "<command data>",
    description = S("Runs any command that Better Commands has overridden"),
    privs = {},
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, S("Missing context"), 0 end
        if not context.executor then return false, S("Missing executor"), 0 end
        local command, command_param = param:match("^%/?([%S]+)%s*(.-)$")
        local def = better_commands.old_commands[command]
        if def then
            local privs = context.command_block
            local missing
            if not privs then privs, missing = minetest.check_player_privs(name, def.privs) end
            if privs then
                return def.func(name, command_param, context)
            else
                return false, S("You don't have permission to run this command (missing privileges: @1)", table.concat(missing, ", ")), 0
            end
        else
            return false, S("Invalid command: @1", command), 0
        end
    end
})