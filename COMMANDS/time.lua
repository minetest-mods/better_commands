--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

better_commands.times = {
    day = 7000/24000,
    night = 19000/24000,
    noon = 12000/24000,
    midnight = 0/24000,
    sunrise = 5000/24000,
    sunset = 18000/24000
}

better_commands.register_command("time", {
    params = S("add|set|query ..."),
    description = S("Sets or gets the time"),
    privs = {settime = true, server = true},
    func = function(name, param, context)
        local split_param = better_commands.parse_params(param)
        if not (split_param[1] and split_param[2]) then return false, nil, 0 end
        local action = split_param[1][3]:lower()
        local time = split_param[2][3]:lower()
        if action == "add" then
            local new_time, err = better_commands.parse_time_string(time)
            if err then return false, better_commands.error(err), 0 end
            minetest.set_timeofday(new_time)
            return true, S("Time set"), 1
        elseif action == "query" then
            if time == "daytime" then
                if better_commands.settings.acovg_time then
                    return true, S("Current time: @1", math.floor(minetest.get_timeofday()*24000+18000) % 24000), 1
                else
                    return true, S("Current time: @1", math.floor(minetest.get_timeofday()*24000)), 1
                end
            elseif time == "gametime" then
                return true, S("Time since world creation: @1", (minetest.get_gametime() or 0)*24000), 1
            elseif time == "day" then
                return true, S("Day count: @1", minetest.get_day_count()), 1
            end
            return false, better_commands.error(S("Must be 'daytime', 'gametime', or 'day', got @1", time)), 0
        elseif action == "set" then
            local new_time, err = better_commands.parse_time_string(time, true)
            if err then return false, better_commands.error(err), 0 end
            minetest.set_timeofday(new_time)
            return true, S("Time set"), 1
        end
        return false, better_commands.error(S("Must be 'add', 'set', or 'query'")), 0
    end
})