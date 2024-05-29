--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("gamerule", {
    description = S("Sets or queries settings"),
    params = S("<setting> [<value>]"),
    privs = {server = true},
    func = function(name, param, context)
        local split_param = better_commands.parse_params(param)
        if not split_param[1] then return false, nil, 0 end
        local setting = split_param[1][3]
        local value = split_param[2] and split_param[2][3]
        if value then
            if setting:sub(1, 7) == "secure." then
                return false, S("Failed. Cannot modify secure settings. Edit the settings file manually"), 0
            end
            local new = not minetest.settings:get(setting)
            minetest.settings:set(setting, value)
            better_commands.reload_settings()
            if new then
                return true, S("Set @1 to @2 (new setting)", setting, value), 1
            else
                return true, S("Set @1 to @2", setting, value), 1
            end
        else
            value = minetest.settings:get(setting)
            if value then
                return true, S("@1 = @2", setting, value), 1
            else
                return false, better_commands.error(S("Setting @1 has not been set", setting)), 1
            end
        end
    end
})

better_commands.register_command_alias("changesetting", "gamerule")