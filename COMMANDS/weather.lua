local S = minetest.get_translator(minetest.get_current_modname())

local set_weather, get_weather, validate_weather

if better_commands.mcl and minetest.settings:get_bool("mcl_doWeatherCycle", true) and mcl_weather then
    ---@param w string
    ---@param end_time? integer
    ---@return boolean, string?
    set_weather = function(w, end_time)
        if w == "clear" then w = "none" end
        return mcl_weather.change_weather(w or "none", end_time)
    end

    ---@return string
    get_weather = mcl_weather.get_weather

    ---@param w string
    ---@return string?
    validate_weather = function (w)
        if mcl_weather.reg_weathers and mcl_weather.reg_weathers[w] then
            return w
        else
            return
        end
    end
elseif minetest.get_modpath("weather") and weather and weather_mod then
    ---@param w string
    ---@return boolean
    set_weather = function(w)
        if w == "clear" then w = "none" end
        weather.type = w or "none"
        weather_mod.handle_lightning()
        weather_mod.handle_weather_change({type = w or "none"})
        return true
    end

    ---@return string
    get_weather = function() return weather.type end

    ---@param w string
    ---@return string?
    validate_weather = function (w)
        if w == "clear" then return "none" end
        if not weather_mod.registered_downfalls[w] then
            for downfall in pairs(weather_mod.registered_downfalls) do
                if downfall:match("[%w_]+:"..w) then
                    return downfall
                end
            end
            return
        end
        return w
    end
else -- Don't bother registering the commands if there's no weather mod.
    return
end

better_commands.register_command("weather", {
    description = "Sets or outputs the current weather",
    privs = {server = true},
    params = "query|"..
        (better_commands.mcl and "(" or "")..
        "<weather>"..
        (better_commands.mcl and " [<duration>])" or ""),
    func = function (name, param, context)
        local split_param, err = better_commands.parse_params(param)
        if err or not split_param then return false, better_commands.error(err), 0 end
        if not split_param[1] then
            return false, nil, 0
        end
        if split_param[1][3] == "query" then
            if split_param[2] then
                return false, better_commands.error(S("Unexpected argument: @1", split_param[2][3])), 0
            end
            local w = get_weather()
            if w == "none" then w = "clear" end
            return true, S("Weather state is: @1", w), 1
        end
        local w = validate_weather(split_param[1][3])
        if w then
            local end_time
            if split_param[2] then
                if not better_commands.mcl then
                    return false, better_commands.error(S("Unexpected argument: @1", split_param[2][3])), 0
                else
                    local duration, err = better_commands.parse_time_string(split_param[2][3], true)
                    if err or not duration then return false, better_commands.error(err), 0 end
                    local tps = tonumber(minetest.settings:get("time_speed"))
                    -- Don't ask how the math works; I already forgot.
                    local duration_s = duration*24000/(tps/3.6)
                    end_time = minetest.get_gametime() + duration_s
                end
            end
            set_weather(w, end_time)
            return true, S("Set weather to @1", split_param[1][3])
        else
            return false, better_commands.error(S("Invalid weather: @1", split_param[1][3]))
        end
    end
})

better_commands.register_command("toggledownfall", {
    description = "Toggles weather",
    privs = {server = true},
    func = function (name, param, context)
        local w = get_weather()
        if w == "none" or w == "clear" then
            local new_weather = validate_weather("rain")
            if new_weather then
                set_weather(new_weather)
            else
                return false, better_commands.error(S("No weather called 'rain'")), 0
            end
        else
            set_weather("none")
        end
        return true, S("Toggled downfall"), 1
    end
})