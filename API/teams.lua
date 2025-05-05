--local bc = better_commands

---Formats a name according to team data
---@param name string
---@param player_only boolean?
---@param objective string?
---@return string
function better_commands.format_name(name, player_only, objective)
    local display_name = better_commands.get_display_name(name, objective)
    if player_only then
        if not better_commands.players[name] then
            return display_name
        end
    end
    local team = better_commands.teams.players[name]
    if not team then
        return display_name
    else
        local team_data = better_commands.teams.teams[team]
        local name_format = (team_data.name_format or "%s")
        display_name = name_format:gsub("%%s", display_name)
        local color = better_commands.team_colors[team_data.color or "white"]
        return core.colorize(color, display_name)
    end
end

function better_commands.format_team_name(name)
    local team_data = better_commands.teams.teams[name]
    if not team_data then
        core.log("error", "Team "..name.." does not exist.")
        return name
    end
    local color = better_commands.team_colors[team_data.color or "white"]
    local result = core.colorize(color, team_data.display_name or name)
    return result
end

better_commands.team_colors = {
    dark_red = "#aa0000",
    red = "#ff5555",
    gold = "#ffaa00",
    yellow = "#ffff55",
    dark_green = "#00aa00",
    green = "#55ff55",
    aqua = "#55ffff",
    dark_aqua = "#00aaaa",
    dark_blue = "#0000aa",
    blue = "#5555ff",
    light_purple = "#ff55ff",
    dark_purple = "#aa00aa",
    white = "#ffffff",
    gray = "#aaaaaa",
    dark_gray = "#555555",
    black = "#000000"
}

local old = core.format_chat_message

---@diagnostic disable-next-line: duplicate-set-field
core.format_chat_message = function(name, message)
    name = better_commands.format_name(name)
    local result = old(name, message)
    return result
end