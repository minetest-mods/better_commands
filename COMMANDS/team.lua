local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("team", {
    params = S("add|empty|join|leave|list|modify|remove ..."),
    description = S("Controls teams"),
    privs = {server = true},
    func = function (name, param, context)
        local split_param, err = better_commands.parse_params(param)
        if err then return false, better_commands.error(err), 0 end
        if not split_param[1] then return false, better_commands.error(S("Missing subcommand")), 0 end
        local subcommand = split_param[1] and split_param[1][3]
        if subcommand == "add" then
            local team_name = split_param[2] and split_param[2][3]
            if not team_name then return false, better_commands.error(S("Missing team name")), 0 end
            if better_commands.teams.teams[team_name] then
                return false, better_commands.error(S("Team @1 already exists", team_name)), 0
            end
            if team_name:find("[^%w_]") then
                return false, better_commands.error(S("Invalid team name @1: Can only contain letters, numbers, and underscores", team_name)), 0
            end
            local display_name = split_param[3] and split_param[3][3]
            if not display_name then display_name = team_name end
            better_commands.teams.teams[team_name] = {name = team_name, display_name = display_name}
            return true, S("Added team @1", team_name), 1
        elseif subcommand == "empty" or subcommand == "remove" then
            local team_name = split_param[2] and split_param[2][3]
            if not team_name then return false, better_commands.error(S("Missing team name")), 0 end
            if better_commands.teams.teams[team_name] then
                local display_name = better_commands.format_team_name(team_name)
                if subcommand == "remove" then
                    better_commands.teams.teams[team_name] = nil
                end
                for player_name, player_team in pairs(better_commands.teams.players) do
                    if player_team == team_name then
                        better_commands.teams.players[player_name] = nil
                    end
                end
                if subcommand == "remove" then
                    return true, S("Removed team [@1]", display_name), 1
                end
                return true, S("Removed all players from team [@1]", display_name), 1
            else
                return false, better_commands.error(S("Team @1 does not exist", team_name)), 0
            end
        elseif subcommand == "join" then
            local team_name = split_param[2] and split_param[2][3]
            if not team_name then return false, better_commands.error(S("Missing team name")), 0 end
            if not better_commands.teams.teams[team_name] then
                return false, better_commands.error(S("Team @1 does not exist", team_name)), 0
            end
            local selector = split_param[3]
            if not selector then
                if context.executor.is_player and context.executor:is_player() then
                    better_commands.teams.players[context.executor:get_player_name()] = team_name
                    return true, S("Joined team [@1]", better_commands.format_team_name(team_name)), 1
                end
            else
                local count = 0
                local last
                local names, err = better_commands.get_scoreboard_names(selector, context)
                if err or not names then return false, better_commands.error(err), 0 end
                for name in pairs(names) do
                    if count < 1 then last = better_commands.format_name(name) end
                    count = count + 1
                    better_commands.teams.players[name] = team_name
                end
                if count < 1 then
                    return false, better_commands.error(S("No target entities found")), 0
                elseif count == 1 then
                    return true, S("Added @1 to team [@2]", better_commands.format_name(last), better_commands.format_team_name(team_name)), 1
                else
                    return true, S("Added @1 entities to [@2]", count, better_commands.format_team_name(team_name)), 1
                end
            end
        elseif subcommand == "leave" then
            local selector = split_param[2]
            local count = 0
            local last
            if not selector then
                if context.executor.is_player and context.executor:is_player() then
                    last = context.executor:get_player_name()
                    count = 1
                    better_commands.teams.players[last] = nil
                else
                    return false, better_commands.error(S("Non-players cannot be on a team")), 0
                end
            else
                local names, err = better_commands.get_scoreboard_names(selector, context)
                if err or not names then return false, better_commands.error(err), 0 end
                for _, name in ipairs(names) do
                    if better_commands.teams.players[name] then
                        count = count + 1
                        last = name
                        better_commands.teams.players[name] = nil
                    end
                end
            end
            if count < 1 then
                return false, better_commands.error(S("No target entities found")), 0
            elseif count == 1 then
                return true, S("Removed @1 from any team", better_commands.format_name(last)), 1
            else
                return true, S("Removed @1 from any team", count), 1
            end
        elseif subcommand == "list" then
            local team_name = split_param[2] and split_param[2][3]
            if not team_name then
                local count = 0
                local result = ""
                local comma
                for team, team_data in pairs(better_commands.teams.teams) do
                    count = count + 1
                    local color = team_data.color or "white"
                    color = better_commands.team_colors[color] or color
                    if comma then result = result..", " else comma = true end
                    result = result..string.format("[%s]", minetest.colorize(color, team_data.display_name or team))
                end
                if count > 0 then
                    return true, S("There are @1 team(s): @2", count, result), 1
                else
                    return true, S("There are no teams"), 1
                end
            elseif better_commands.teams.teams[team_name] then
                local count = 0
                local result = ""
                local comma
                local display_name = better_commands.format_team_name(team_name)
                for name, team in pairs(better_commands.teams.players) do
                    if team == team_name then
                        count = count + 1
                        local formatted_name = better_commands.format_name(name)
                        if comma then result = result..", " else comma = true end
                        result = minetest.colorize("#00ff00", minetest.strip_colors(formatted_name)) -- not sure why ACOVG makes it green
                    end
                end
                if count > 0 then
                    return true, S("Team [@1] has @2 member(s): @3", display_name, count, result), count
                else
                    return true, S("There are no members on team [@1]", display_name), 1
                end
            else
                return false, better_commands.error(S("Team [@1] does not exist", team_name)), 0
            end
        elseif subcommand == "modify" then
            local team_name = split_param[2] and split_param[2][3]
            if not team_name then return false, better_commands.error(S("Team name is required")), 0 end
            local team_data = better_commands.teams.teams[team_name]
            if not team_data then return false, better_commands.error(S("Unknown team '@1'", team_name)), 0 end
            local key = split_param[3] and split_param[3][3]
            if not key then return false, better_commands.error(S("Missing key")), 0 end
            local value = split_param[4] and split_param[4][3]
            if key == "color" then
                if value then
                    if not better_commands.team_colors[value] then return false, better_commands.error(S("Invalid color: @1", value)), 0 end
                    team_data.color = value
                    return true, S("Set color of team [@1] to @2", better_commands.format_team_name(team_name), value), 1
                else
                    team_data.color = nil
                    return true, S("Reset color of team [@1]", better_commands.format_team_name(team_name)), 1
                end
            elseif key == "displayName" then
                if value then
                    team_data.display_name = value
                    return true, S("Set display name of team [@1] to @2", better_commands.format_team_name(team_name), value), 1
                else
                    team_data.display_name = team_name
                    return true, S("Reset display name of team [@1]", better_commands.format_team_name(team_name)), 1
                end
            elseif key == "friendlyFire" then
                if value == "true" then
                    team_data.pvp = true
                elseif value == "false" then
                    team_data.pvp = false
                else
                    return false, better_commands.error(S("Value must be 'true' or 'false', not @1", value)), 0
                end
                return true, S("Set friendly fire for team [@1] to @2", better_commands.format_team_name(team_name), value), 1
            elseif key == "nameFormat" then
                if not split_param[4] then
                    team_data.name_format = nil
                    return true, S("Reset name format for team [@1]", better_commands.format_team_name(team_name)), 1
                end
                local name_format = param:sub(split_param[4][1], -1)
                team_data.name_format = name_format
                return true, S("Set name format for team [@1] to @2", better_commands.format_team_name(team_name), value), 1
            else
                return false, better_commands.error(S("Value must be 'color', 'displayName', 'friendlyFire', or 'nameFormat'")), 0
            end
        end
        return false, better_commands.error(S("Must be 'add', 'empty', 'join', 'leave', 'list', 'modify', or 'remove', not @1", subcommand)), 0
    end
})