better_commands.settings = {}

---Gets a setting and stores it in better_commands.settings
---@param setting string
---@param default any
---@param type string?
local function get_setting(setting, default, type)
    local long_setting = "better_commands_"..setting
    if not type or type == "string" then
        better_commands.settings[setting] = core.settings:get(long_setting) or default
    elseif type == "bool" then
        better_commands.settings[setting] = core.settings:get_bool(long_setting, default)
    elseif type == "number" then
        better_commands.settings[setting] = tonumber(core.settings:get(long_setting)) or default
    elseif type == "comma_separated" then
        local value = core.settings:get(long_setting)
        better_commands.settings[setting] = value and value:split(",") or default
    end
end

local settings = {
    {"override", false, "bool"},
    {"acovg_time", false, "bool"},
    {"save_interval", 3, "number"},
    {"kill_creative_players", false, "bool"},
    {"clear_lists", {"main", "craft", "offhand"}, "comma_separated"},

    {"scoreboard_picked_up", true, "bool"},
    {"scoreboard_mined", true, "bool"},
    {"scoreboard_placed", true, "bool"},
    {"scoreboard_crafted", true, "bool"},
    {"scoreboard_health", true, "bool"},
    {"scoreboard_death", true, "bool"},
}

function better_commands.reload_settings()
    for _, setting in ipairs(settings) do
        get_setting(unpack(setting))
    end
end

better_commands.reload_settings()