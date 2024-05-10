--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

---Gets matching names in a scoreboard
---@param selector splitParam
---@param context contextTable
---@param objective string?
---@param require_one boolean?
---@return table<string, true>? result
---@return string? err
---@nodiscard
function better_commands.get_scoreboard_names(selector, context, objective, require_one)
    local result = {}
    local objectives = better_commands.scoreboard.objectives
    if objective and not objectives[objective] then
        return nil, S("Invalid objective: @1", objective)
    end
    if selector[3] == "*" then
        if objective then
            for name in pairs(objectives[objective].scores) do
                result[name] = true
            end
        else
            for _, data in pairs(objectives) do
                for name in pairs(data.scores) do
                    result[name] = true
                end
            end
        end
    elseif selector.type == "selector" and selector[3]:sub(1,1) == "@" then
        local targets, err = better_commands.parse_selector(selector, context)
        if err or not targets then return nil, err end
        for _, target in ipairs(targets) do
            if target.is_player and target:is_player() then
                result[target:get_player_name()] = true
            end
        end
    else
        result = {[selector[3]] = true}
    end
    local result_count = better_commands.count_table(result)
    if result_count < 1 then
        return nil, S("No targets found")
    end
    if require_one then
        if result_count > 1 then
            return nil, S("Multiple targets found")
        else
            result = {next(result)}
            return {result[1]}
        end
    else
        return result
    end
end

local sidebar_template = {
    bg = {
        hud_elem_type = "image",
        position = {x = 1, y = 0.5},
        alignment = {x = 0, y = 1},
        offset = {x = -70, y = 0},
        text = "better_commands_scoreboard_bg.png",
        scale = {x = 10, y = 10},
        z_index = -1
    },
    title = {
        hud_elem_type = "text",
        text = "Title",
        position = {x = 1, y = 0.5},
        alignment = {x = 0, y = -1},
        offset = {x = -70, y = 10},
        number = 0xffffff,
    },
    names = {
        hud_elem_type = "text",
        position = {x = 1, y = 0.5},
        alignment = {x = 1, y = 1},
        offset = {x = -120, y = 0},
        text = "Score\nScore2",
        number = 0xffffff,
    },
    scores = {
        hud_elem_type = "text",
        position = {x = 1, y = 0.5},
        alignment = {x = -1, y = 1},
        offset = {x = -20, y = 0},
        text = "5\n20",
        number = 0xffffff,
    }
}

local function sort_scores(a, b)
    return (a.score == b.score) and (a.name < b.name) or (tonumber(a.score) > tonumber(b.score))
end

function better_commands.update_hud()
    local bg_width = 16
    for _, player in ipairs(minetest.get_connected_players()) do
        local playername = player:get_player_name()
        local sidebar = better_commands.sidebars[playername]
        if not sidebar then
            sidebar = {}
            better_commands.sidebars[playername] = sidebar
        end
        local team = better_commands.teams.players[playername]
        local team_color, display, objective
        if team then
            team_color = better_commands.teams.teams[team].color
            display = better_commands.scoreboard.displays.colors[team_color] or better_commands.scoreboard.displays.sidebar
        else
            display = better_commands.scoreboard.displays.sidebar
        end
        objective = display and display.objective
        local objective_data = better_commands.scoreboard.objectives[objective]
        if objective_data then
            local name_text, score_text, max_width = "", "", #objective
            local title = objective_data.display_name or objective
            local scores = objective_data.scores
            local count = 0
            local sortable_scores = {}
            for name, data in pairs(scores) do
                count = count + 1
                local display_name = better_commands.format_name(name)
                local score
                local format_data = objective_data.format or data.format
                if format_data then
                    if format_data.type == "blank" then
                        score = ""
                    elseif format_data.type == "fixed" then
                        score = minetest.colorize("#ffffff", format_data.data)
                    else
                        score = minetest.colorize(format_data.data, tostring(data.score))
                    end
                else
                    score = tostring(data.score)
                end
                local width = #minetest.strip_colors(display_name) + #minetest.strip_colors(score)
                max_width = math.max(width + 2, max_width)
                table.insert(sortable_scores, {name = display_name, score = score})
            end
            if not display.ascending then
                table.sort(sortable_scores, sort_scores)
            else
                table.sort(sortable_scores, function(...) return not sort_scores(...) end)
            end
            for _, data in ipairs(sortable_scores) do
                name_text = name_text..data.name.."\n"
                score_text = score_text..data.score.."\n"
            end
            if not title then
                if sidebar.title then
                    for name, id in pairs(sidebar) do
                        player:hud_remove(id)
                        sidebar[name] = nil
                    end
                    return
                end
            end
            if not sidebar.title then
                for name, def in pairs(sidebar_template) do
                    sidebar[name] = player:hud_add(def)
                end
            end
            local pixel_width = max_width*13
            local pixel_height = (count+2)*21
            local center_x_offset = -(pixel_width/2 + 10)
            player:hud_change(sidebar.title, "text", title)
            player:hud_change(sidebar.title, "offset", {x = center_x_offset, y = -10})
            player:hud_change(sidebar.bg, "scale", {x = pixel_width/bg_width, y = pixel_height/bg_width})
            player:hud_change(sidebar.bg, "offset", {x = center_x_offset, y = -30})
            player:hud_change(sidebar.names, "text", name_text)
            player:hud_change(sidebar.names, "offset", {x = center_x_offset*2+20, y = 0})
            player:hud_change(sidebar.scores, "text", score_text)
        else
            for name, id in pairs(sidebar) do
                player:hud_remove(id)
                sidebar[name] = nil
            end
            return
        end
    end
end

better_commands.sidebars = {}

---Gets the display name, given a name and objective
---@param name string
---@param objective? string
---@return string
function better_commands.get_display_name(name, objective)
    if not objective then return name end
    local objective_data = better_commands.scoreboard.objectives[objective]
    if not objective_data then return name end
    if not objective_data.players[name] then return name end
    if objective_data.display_name then
        return objective_data.display_name
    elseif objective_data.players[name].display_name then
        return objective_data.players[name].display_name
    end
    return name
end

better_commands.register_on_update(better_commands.update_hud)