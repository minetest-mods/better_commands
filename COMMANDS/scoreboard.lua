--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

local playerlist = minetest.get_modpath("playerlist")

local scoreboard_operators = {
    ["+="] = true,
    ["-="] = true,
    ["*="] = true,
    ["/="] = true,
    ["%="] = true,
    ["="] = true,
    ["<"] = true,
    [">"] = true,
    ["><"] = true,
}

better_commands.register_command("scoreboard", {
    params = S("objectives|players ..."),
    description = S("Manupulates the scoreboard"),
    privs = {server = true},
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, S("Missing context"), 0 end
        local split_param = better_commands.parse_params(param)
        if not (split_param[1] and split_param[2]) then
            return false, S("Missing arguments"), 0
        end
        --minetest.log(dump(split_param))
        if split_param[1][3] == "objectives" then
            local subcommand = split_param[2][3]
            if subcommand == "add" then
                local objective_name = split_param[3] and split_param[3][3]
                if not objective_name then return false, S("Missing name"), 0 end
                if better_commands.scoreboard.objectives[objective_name] then
                    return false, S("Objective @1 already exists", objective_name), 0
                end
                local criterion = split_param[4] and split_param[4][3]
                if not criterion then return false, S("Missing criterion"), 0 end
                if not better_commands.validate_criterion(criterion) then
                    return false, S("Invalid criterion @1", criterion), 0
                end
                local display_name = (split_param[5] and param:sub(split_param[5][1], -1)) or objective_name
                better_commands.scoreboard.objectives[objective_name] = {
                    name = objective_name,
                    criterion = criterion,
                    display_name = display_name,
                    scores = {}
                }
                return true, S("Added objective @1", objective_name), 1
            elseif subcommand == "list" then
                local objective_count = better_commands.count_table(better_commands.scoreboard.objectives) or 0
                if objective_count < 1 then
                    return true, S("There are no objectives"), 1
                end
                local result = ""
                local first = true
                for _, def in pairs(better_commands.scoreboard.objectives) do
                    if not first then
                        result = result..", "
                    else
                        first = false
                    end
                    result = result..string.format("[%s]", def.display_name)
                end
                return true, S("There are @1 objective(s): @2", objective_count, result), objective_count
            elseif subcommand == "modify" then
                local objective = split_param[3] and split_param[3][3]
                if not objective then return false, S("Missing objective"), 0 end
                if not better_commands.scoreboard.objectives[objective] then
                    return false, S("Unknown scoreboard objective '@1'", objective), 0
                end
                local key = split_param[4] and split_param[4][3]
                if not key then return false, S("Must be 'displayname' or 'numberformat'"), 0 end
                local value = split_param[5] and split_param[5][3]
                if key == "displayname" then
                    if not value then return false, S("Missing display name"), 0 end
                    local display_name = param:sub(split_param[5][1], -1):trim() -- Allow spaces
                    better_commands.scoreboard.objectives[objective].display_name = display_name
                    return true, S("@1 set to @2", "displayname", display_name), 1
                elseif key == "numberformat" then
                    local format = split_param[6] and split_param[6][3]
                    if not value then
                        better_commands.scoreboard.objectives[objective].format = nil
                        return true, S("Cleared numberformat for @1", objective), 1
                    elseif value == "blank" then
                        better_commands.scoreboard.objectives[objective].format = {type = "blank"}
                        return true, S("@1 set to @2", "numberformat", "blank"), 1
                    elseif value == "fixed" then
                        if not split_param[6] then return false, S("Missing argument"), 0 end
                        local fixed = param:sub(split_param[6][1], -1):trim() -- Allow spaces
                        better_commands.scoreboard.objectives[objective].format = {type = "fixed", data = fixed}
                        return true, S("@1 set to @2", "numberformat", fixed), 1
                    elseif value == "styled" then
                        format = format:lower()
                        if better_commands.team_colors[format] then
                            format = better_commands.team_colors[format]
                        else
                            format = minetest.colorspec_to_colorstring(format)
                            if not value then
                                return false, S("Invalid color"), 0
                            end
                        end
                        better_commands.scoreboard.objectives[objective].format = {type = "color", data = format}
                        return true, S("@1 set to @2", "numberformat", format), 1
                    else
                        return false, S("Must be 'blank', 'fixed', or 'styled'"), 0
                    end
                else
                    return false, S("Must be 'displayname' or 'numberformat'"), 0
                end
            elseif subcommand == "remove" then
                local objective = split_param[3] and split_param[3][3]
                if not objective then return false, S("Missing objective"), 0 end
                if not better_commands.scoreboard.objectives[objective] then
                    return false, S("Unknown scoreboard objective '@1'", objective), 0
                end
                better_commands.scoreboard.objectives[objective] = nil
                return true, S("Removed objective @1", objective), 1
            elseif subcommand == "setdisplay" then
                local location = split_param[3] and split_param[3][3]
                if not location then return false, S("Missing argument"), 0 end
                local objective = split_param[4] and split_param[4][3]
                if objective and not better_commands.scoreboard.objectives[objective] then
                    return false, S("Unknown scoreboard objective '@1'", objective), 0
                end
                local display, sortable
                if location == "list" then
                    return false, S("`list` support has not been added yet."), 0
                elseif location == "below_name" then
                    return false, S("`below_name` support has not been added yet."), 0
                elseif location == "sidebar" then
                    better_commands.scoreboard.displays.sidebar = {objective = objective}
                    display = better_commands.scoreboard.displays.sidebar
                    sortable = true
                else
                    local color = location:match("^sidebar%.team.(.+)")
                    if not color then
                        return false, S("Must be 'list', 'below_name', 'sidebar', or 'sidebar.team.<color>"), 0
                    elseif better_commands.team_colors[color] then
                        display = better_commands.scoreboard.displays.colors[color]
                        better_commands.scoreboard.displays.colors[color] = {objective = objective}
                    else
                        return false, S("Invalid color: @1", color), 0
                    end
                end
                local sort = split_param[5] and split_param[5][3]
                if sort then
                    if sortable then
                        if sort == "ascending" then
                            display.ascending = true
                        elseif sort ~= "descending" then
                            return false, S("Expected ascending|descending, got @1", sort), 0
                        end
                    else
                        return false, S("Display slot @1 does not support sorting.", location), 0
                    end
                end
                return true, S("Set display slot @1 to show objective @2", location, objective), 1
            else
                return false, S("Expected 'add', 'list', 'modify', 'remove', or 'setdisplay', got '@1'", subcommand), 0
            end
        elseif split_param[1][3] == "players" then
            local subcommand = split_param[2][3]
            if subcommand == "add" or subcommand == "set" or subcommand == "remove" then
                local selector = split_param[3]
                if not selector then return false, S("Missing target"), 0 end
                local objective = split_param[4] and split_param[4][3]
                if not objective then return false, ("Missing objective"), 0 end
                if not better_commands.scoreboard.objectives[objective] then
                    return false, S("Unknown scoreboard objective '@1'", objective), 0
                end
                local score = tonumber(split_param[5] and split_param[5][3])
                if not score then return false, S("Missing score"), 0 end
                score = math.floor(score)
                local names, err = better_commands.get_scoreboard_names(selector, context, objective)
                if err or not names then return false, err, 0 end
                local last
                local scores = better_commands.scoreboard.objectives[objective].scores
                for name in pairs(names) do
                    last = name
                    if not scores[name] then
                        scores[name] = {score = 0}
                    end
                    if subcommand == "add" then
                        scores[name].score = scores[name].score + score
                    elseif subcommand == "remove" then
                        scores[name].score = scores[name].score - score
                    else --if subcommand == "set"
                        scores[name].score = score
                    end
                end
                local name_count = better_commands.count_table(names) or 0
                if name_count < 1 then
                    return false, S("No scores found"), 0
                elseif name_count == 1 then 
                    return true, S("Set score for @1", better_commands.format_name(last)), 1
                else
                    return true, S("Set score for @1 entities", name_count), name_count
                end
            elseif subcommand == "display" then
                local key = split_param[3] and split_param[3][3]
                if not key then return false, S("Must be 'name' or 'numberformat'"), 0 end
                if key == "name" then
                    local selector = split_param[4]
                    if not selector then return false, S("Missing target"), 0 end
                    local objective = split_param[5] and split_param[5][3]
                    if not objective then return false, ("Missing objective"), 0 end
                    if not better_commands.scoreboard.objectives[objective] then
                        return false, S("Invalid objective: @1", objective), 0
                    end
                    local display_name = nil
                    if split_param[6] then
                        display_name = param:sub(split_param[6][1], -1):trim() -- Allow spaces
                    end
                    local scores = better_commands.scoreboard.objectives[objective].scores
                    local names, err = better_commands.get_scoreboard_names(selector, context, objective)
                    if err or not names then return false, err, 0 end
                    local last
                    for name in pairs(names) do
                        last = name
                        if not scores[name] then scores[name] = {score = 0} end
                        scores[name].display_name = display_name
                    end
                    local name_count = better_commands.count_table(names) or 0
                    if name_count < 1 then
                        return false, S("No entities found"), 0
                    elseif name_count == 1 then
                        return true, S("Set display name of @1 to @2", better_commands.format_name(last), display_name or "default"), 1
                    else
                        return true, S("Set display name of @1 entities to @2", name_count, display_name or "default"), name_count
                    end
                elseif key == "numberformat" then
                    local selector = split_param[4] and split_param[4]
                    if not selector then return false, S("Missing target"), 0 end
                    local objective = split_param[5] and split_param[5][3]
                    if not objective then return false, ("Missing objective"), 0 end
                    if not better_commands.scoreboard.objectives[objective] then
                        return false, S("Invalid objective: @1", objective), 0
                    end
                    local value = split_param[5] and split_param[5][3]
                    local format = split_param[6] and split_param[6][3]
                    local result, return_value
                    if value == nil then
                        result = nil
                        return_value = S("Cleared format for @1", objective)
                    elseif value == "blank" then
                        result = {type = "blank"}
                        return_value = S("@1 set to @2", "numberformat", "blank")
                    elseif value == "fixed" then
                        if not split_param[6] then return false, S("Missing argument"), 0 end
                        local fixed = param:sub(split_param[6][1], -1):trim() -- Allow spaces
                        result = {type = "fixed", data = fixed}
                        return_value = S("@1 set to @2", "numberformat", fixed)
                    elseif value == "styled" then
                        format = format:lower()
                        if better_commands.team_colors[format] then
                            format = better_commands.team_colors[format]
                        else
                            format = minetest.colorspec_to_colorstring(format)
                            if not value then
                                return false, S("Invalid color"), 0
                            end
                        end
                        result = {type = "color", data = format}
                        return_value = S("@1 set to @2", "numberformat", format)
                    else
                        return false, S("Must be 'blank', 'fixed', or 'styled'"), 0
                    end
                    local names, err = better_commands.get_scoreboard_names(selector, context, objective)
                    if err or not names then return false, err, 0 end
                    local scores = better_commands.scoreboard.objectives[objective].scores
                    local count = 0
                    for name in pairs(names) do
                        if not scores[name] then scores[name] = {score = 0} end
                        scores[name].format = result and table.copy(result)
                        count = count + 1
                    end
                    return true, return_value, count
                else
                    return false, S("Must be 'name' or 'numberformat', not @1", key), 0
                end
            elseif subcommand == "enable" then
                local selector = split_param[3]
                if not selector then return false, S("Missing target"), 0 end
                local objective = split_param[4] and split_param[4][3]
                if not objective then return false, ("Missing objective"), 0 end
                local objective_data = better_commands.scoreboard.objectives[objective]
                if not (objective_data) then
                    return false, S("Invalid objective: @1", objective), 0
                end
                if objective_data.criterion ~= "trigger" then
                    return false, S("@1 is not a trigger objective", objective), 0
                end
                local names, err = better_commands.get_scoreboard_names(selector, context, objective)
                if err or not names then return false, err, 0 end
                local scores = objective_data.scores
                local display_name = objective_data.display_name or objective
                local last
                for name in pairs(names) do
                    last = name
                    if not scores[name] then scores[name] = {score = 0} end
                    scores[name].enabled = true
                end
                local name_count = better_commands.count_table(names) or 0
                if name_count < 1 then
                    return false, S("No players found"), 0
                elseif name_count == 1 then
                    return true, S("Enabled trigger [@1] for @2", display_name, better_commands.format_name(last)), 1
                else
                    return true, S("Enabled trigger [@1] for @2 players", display_name, name_count), name_count
                end
            elseif subcommand == "get" then
                local selector = split_param[3] and split_param[3]
                if not selector then return false, S("Missing target"), 0 end
                local objective = split_param[4] and split_param[4][3]
                if not objective then return false, ("Missing objective"), 0 end
                if not better_commands.scoreboard.objectives[objective] then
                    return false, S("Unknown scoreboard objective '@1'", objective), 0
                end
                local names, err = better_commands.get_scoreboard_names(selector, context, objective, true)
                if err or not names then return false, err, 0 end
                local name = names[1]
                if name then
                    local score = better_commands.scoreboard.objectives[objective].scores[name]
                    local display_name = better_commands.scoreboard.objectives[objective].display_name or objective
                    return true, S("@1 has @2 [@3]", better_commands.format_name(name), score, display_name), 1
                else
                    return false, S("@1 does not have a score for @2", better_commands.format(name), objective), 1
                end
            elseif subcommand == "list" then
                local selector = split_param[3]
                if not selector then
                    local results = {}
                    for _, data in pairs(better_commands.scoreboard.objectives) do
                        for name in pairs(data.scores) do
                            results[name] = true
                        end
                    end
                    local result_string = ""
                    local first = true
                    local result_count = 0
                    for result in pairs(results) do
                        if not first then
                            result_string = result_string..", "
                        else
                            first = false
                        end
                        result_string = result_string..better_commands.format_name(result)
                        result_count = result_count + 1
                    end
                    if result_count < 1 then
                        return true, S("There are no tracked players"), 1
                    end
                    return true, S("There are @1 tracked player(s): @2", result_count, result_string), result_count
                else
                    local names, err = better_commands.get_scoreboard_names(selector, context, nil, true)
                    if err or not names then return false, err, 0 end
                    local name = names[1]
                    local results = {}
                    for _, data in pairs(better_commands.scoreboard.objectives) do
                        for score_name, score_data in pairs(data.scores) do
                            if score_name == name then
                                results[data.display_name] = score_data.score
                            end
                        end
                    end
                    local result_string = ""
                    local result_count = 0
                    for objective, score in pairs(results) do
                        result_string = result_string..string.format("\n[%s]: %s", objective, score)
                        result_count = result_count + 1
                    end
                    if result_count < 1 then
                        return true, S("@1 has no scores", better_commands.format_name(name)), 0
                    end
                    return true, S("@1 has @2 score(s): @3", better_commands.format_name(name), result_count, result_string), 1
                end
            elseif subcommand == "operation" then
                local source_selector = split_param[3]
                if not source_selector then return false, S("Missing source selector"), 0 end
                local source_objective = split_param[4] and split_param[4][3]
                if not source_objective then return false, S("Missing source objective"), 0 end
                if not better_commands.scoreboard.objectives[source_objective] then
                    return false, S("Invalid source objective"), 0
                end
                local operator = split_param[5] and split_param[5][3]
                if not operator then return false, S("Missing operator"), 0 end
                if not scoreboard_operators[operator] then
                    return false, S("Invalid operator: @1", operator), 0
                end
                local target_selector = split_param[6]
                if not target_selector then return false, S("Missing target selector"), 0 end
                local target_objective = split_param[7] and split_param[7][3]
                if not target_objective then return false, S("Missing target objective"), 0 end
                if not better_commands.scoreboard.objectives[target_objective] then
                    return false, S("Invalid target objective"), 0
                end
                local sources, err = better_commands.get_scoreboard_names(source_selector, context)
                if err or not sources then return false, err, 0 end
                local targets, err = better_commands.get_scoreboard_names(target_selector, context)
                local source_scores = better_commands.scoreboard.objectives[source_objective].scores
                local target_scores = better_commands.scoreboard.objectives[target_objective].scores
                if err or not targets then return false, err, 0 end
                local change_count, score_count = 0, 0
                local last_source, last_target, op_string, preposition
                local swap = false
                for target in pairs(targets) do
                    score_count = score_count + 1
                    if not target_scores[target] then
                        target_scores[target] = {score = 0}
                    end
                    for source in pairs(sources) do
                        last_source, last_target = source, target
                        change_count = change_count + 1
                        if not source_scores[source] then
                            source_scores[source] = {score = 0}
                        end
                        if operator == "+=" then
                            target_scores[target].score = math.floor(target_scores[target].score + source_scores[source].score)
                            op_string, preposition = "Added", "to"
                        elseif operator == "-=" then
                            target_scores[target].score = math.floor(target_scores[target].score - source_scores[source].score)
                            op_string, preposition = "Subtracted", "from"
                        elseif operator == "*=" then
                            target_scores[target].score = math.floor(target_scores[target].score * source_scores[source].score)
                            op_string, preposition, swap = "Multiplied", "by", true
                        elseif operator == "/=" then
                            if source_scores[source].score == 0 then
                                minetest.chat_send_player(name, S("Skipping attempt to divide by zero"))
                            else
                                target_scores[target].score = math.floor(target_scores[target].score / source_scores[source].score)
                                op_string, preposition, swap = "Divided", "by", true
                            end
                        elseif operator == "%=" then
                            if source_scores[source].score == 0 then
                                minetest.chat_send_player(name, S("Skipping attempt to divide by zero"))
                            else
                                target_scores[target].score = math.floor(target_scores[target].score % source_scores[source].score)
                                op_string, preposition, swap = "Modulo-ed (?)", "and", true
                            end
                        elseif operator == "=" then
                            target_scores[target].score = source_scores[source].score
                            op_string, preposition, swap = "Set", "to", true
                        elseif operator == "<" then
                            if source_scores[source].score < target_scores[target].score then
                                target_scores[target].score = source_scores[source].score
                                op_string, preposition, swap = "Set", "to", true
                            end
                        elseif operator == ">" then
                            if source_scores[source].score > target_scores[target].score then
                                target_scores[target].score = source_scores[source].score
                                op_string, preposition, swap = "Set", "to", true
                            end
                        else --if operator == "><" then
                            source_scores[source].score, target_scores[target].score
                            = target_scores[target].score, source_scores[source].score
                            op_string, preposition, swap = "Set", "to", true
                        end
                    end
                end
                if change_count < 1 then
                    return false, S("No matching entity found"), 0
                elseif change_count == 1 then
                    return true, S(
                        "@1 [@2] score of @3 @4 [@5] score of @6", -- a bit unnecessary, perhaps.
                        op_string,
                        swap and better_commands.scoreboard.objectives[target_objective].display_name or better_commands.scoreboard.objectives[source_objective].display_name,
                        swap and better_commands.format_name(last_target) or better_commands.format_name(last_source),
                        preposition,
                        swap and better_commands.scoreboard.objectives[source_objective].display_name or better_commands.scoreboard.objectives[target_objective].display_name,
                        swap and better_commands.format_name(last_source) or better_commands.format_name(last_target)
                    ), 1
                else
                    return true, S("Changed @1 scores (@2 total operations)", score_count, change_count), score_count
                end
            elseif subcommand == "random" then
                local selector = split_param[3]
                if not selector then return false, S("Missing selector"), 0 end
                local objective = split_param[4] and split_param[4][3]
                if not objective then return false, S("Missing objective"), 0 end
                if not better_commands.scoreboard.objectives[objective] then
                    return false, S("Invalid objective"), 0
                end
                local min = split_param[5] and split_param[5][3]
                if not min then return false, S("Missing min"), 0 end
---@diagnostic disable-next-line: cast-local-type
                min = tonumber(min)
                if not min then return false, S("Must be a number"), 0 end
                local max = split_param[6] and split_param[6][3]
                if not max then return false, S("Missing max"), 0 end
                max = tonumber(max)
                if not max then return false, S("Must be a number"), 0 end
                local names, err = better_commands.get_scoreboard_names(selector, context)
                if err or not names then return false, err, 0 end
                local scores = better_commands.scoreboard.objectives[objective].scores
                local count = 0
                local last
                for name in pairs(names) do
                    count = count + 1
                    last = name
                    if not scores[name] then scores[name] = {} end
                    scores[name].score = math.random(min, max)
                end
                if count < 1 then
                    return false, S("No target entities found"), 0
                elseif count == 1 then
                    return true, S("Randomized score for @1", better_commands.format_name(last)), 1
                else
                    return true, S("Randomized @2 scores", count), count
                end
            elseif subcommand == "reset" then
                local selector = split_param[3]
                if not selector then return false, S("Missing selector"), 0 end
                local objective = split_param[4] and split_param[4][3]
                if objective and not better_commands.scoreboard.objectives[objective] then
                    return false, S("Invalid objective"), 0
                end
                local names, err = better_commands.get_scoreboard_names(selector, context)
                if err or not names then return false, err, 0 end
                local count = 0
                local last
                for name in pairs(names) do
                    count = count + 1
                    last = name
                    if objective then
                        better_commands.scoreboard.objectives[objective].scores[name] = nil
                    else
                        for _, objective in pairs(better_commands.scoreboard.objectives) do
                            objective.scores[name] = nil
                        end
                    end
                end
                if count < 1 then
                    return true, S("No target entities found"), 0
                elseif count == 1 then
                    return true, S("Reset score for @1", better_commands.format_name(last)), 1
                else
                    return true, S("Reset @2 scores", count), 1
                end
            elseif subcommand == "test" then
                local selector = split_param[3]
                if not selector then return false, S("Missing selector"), 0 end
                local objective = split_param[4] and split_param[4][3]
                if not objective then return false, S("Missing objective"), 0 end
                if not better_commands.scoreboard.objectives[objective] then
                    return false, S("Invalid objective"), 0
                end
                local min = split_param[5] and split_param[5][3]
                if not min then return false, S("Missing min"), 0 end
                if min == "*" then min = -99999999999999 end -- the minimum value before losing precision
                min = tonumber(min)
                if not min then return false, S("Must be a number"), 0 end
                local max = split_param[6] and split_param[6][3]
                if not max then return false, S("Missing max"), 0 end
                if max == "*" then max = 100000000000000 end -- the maximum value before losing precision
                max = tonumber(max)
                if not max then return false, S("Must be a number"), 0 end
                local names, err = better_commands.get_scoreboard_names(selector, context, objective, true)
                if err or not names then return false, err, 0 end
                local scoreboard_name = names[1]
                local scores = better_commands.scoreboard.objectives[objective].scores
                if not scores[scoreboard_name] then
                    return false, S("Player @1 has no scores recorded", better_commands.format_name(scoreboard_name)), 0
                elseif scores[scoreboard_name].score >= min and scores[scoreboard_name].score <= max then
                    return true, S("Score @1 is in range @2 to @3", scores[scoreboard_name].score, min, max), 1
                else
                    return false, S("Score @1 is NOT in range @2 to @3", scores[scoreboard_name].score, min, max), 0
                end
            else
                return false, S("Expected 'add', 'display', 'enable', 'get', 'list', 'operation', 'random', 'reset', 'set', or 'test', got @1", subcommand), 0
            end
        else
            return false, nil, 0
        end
    end
})

better_commands.register_command("trigger", {
    description = S("Allows players to set their own scores in certain conditions"),
    privs = {},
    param = "<objective> [add|set <value>]",
    func = function (name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, S("Missing context"), 0 end
        if not context.executor then return false, S("Missing executor"), 0 end
        if not (context.executor.is_player and context.executor:is_player()) then
            return false, S("/trigger can only be used by players"), 0
        end
        local player_name = context.executor:get_player_name()
        local split_param = better_commands.parse_params(param)
        local objective = split_param[1] and split_param[1][3]
        if not objective then return false, nil, 0 end
        local objective_data = better_commands.scoreboard.objectives[objective]
        if not objective_data then
            return false, S("Unknown scoreboard objective '@1'", objective), 0
        end
        if objective_data.criterion ~= "trigger" then
            return false, S("You can only trigger objectives that are 'trigger' type"), 0
        end
        local scores = objective_data.scores[player_name]
        if not scores then
            return false, S("You cannot trigger this objective yet"), 0
        end
        if not scores.enabled then
            return false, S("You cannot trigger this objective yet"), 0
        end
        local subcommand = split_param[2] and split_param[2][3]
        local display_name = objective_data.display_name or objective
        if not subcommand then
            scores.score = scores.score + 1
            scores.enabled = false
            return true, S("Triggered [@1]", display_name), scores.score
        else
            local value = split_param[3] and split_param[3][3]
            if not value then return false, S("Missing value"), 0 end
            value = tonumber(value)
            if not value then return false, S("Value must be a number"), 0 end
            if subcommand == "add" then
                scores.score = scores.score + math.floor(value)
                scores.enabled = false
                return true, S("Triggered [@1] (added @2 to value)", display_name, value), scores.score
            elseif subcommand == "set" then
                scores.score = math.floor(value)
                scores.enabled = false
                return true, S("Triggered [@1] (set value to @2)", display_name, value), scores.score
            else
                return false, S("Expected 'add' or 'set', got @1", subcommand), 0
            end
        end
    end
})