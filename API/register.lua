--local bc = better_commands

---Registers an ACOVG command
---@param name string The name of the command (/<name>)
---@param def betterCommandDef The command definition
function better_commands.register_command(name, def)
    better_commands.commands[name] = def
end

---Registers an alias for an ACOVG command
---@param new string The name of the alias
---@param old string The original command
function better_commands.register_command_alias(new, old)
    better_commands.register_command(new, better_commands.commands[old])
end


-- Register commands last (so overriding works properly)
minetest.register_on_mods_loaded(function()
    for name, def in pairs(better_commands.commands) do
        if minetest.registered_chatcommands[name] then
            if better_commands.override then
                minetest.log("action", "[Better Commands] Overriding "..name)
                better_commands.old_commands[name] = minetest.registered_chatcommands[name]
                minetest.unregister_chatcommand(name, def)
            else
                minetest.log("action", "[Better Commands] Not registering "..name.." as it already exists.")
                return
            end
        end
        minetest.register_chatcommand(name, def)
        -- Since this is in an on_mods_loaded function, mod_origin is "??" by default
        ---@diagnostic disable-next-line: inject-field
        minetest.registered_chatcommands[name].mod_origin = "better_commands"
    end
end)