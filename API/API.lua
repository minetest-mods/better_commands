---@alias contextTable {executor: minetest.ObjectRef, pos: vector.Vector, rot: vector.Vector, anchor: string, origin: string, [any]: any}
---@alias splitParam {[1]: integer, [2]: integer, [3]: string, type: string, any: string}
---@alias betterCommandFunc fun(name: string, param: string, context: contextTable): success: boolean, message: string?, count: number
---@alias betterCommandDef {description: string, param?: string, privs: table<string, boolean>, func: betterCommandFunc}

--local bc = better_commands
local storage = minetest.get_mod_storage()


local modpath = minetest.get_modpath("better_commands")
function better_commands.run_file(file, subfolder)
    dofile(string.format("%s%s%s.lua", modpath, subfolder and "/"..subfolder.."/" or "", file))
end

local api_files = {
    "damage",
    "entity",
    "parsing",
    "register",
    "scoreboard",
    "teams",
}

for _, file in ipairs(api_files) do
    better_commands.run_file(file, "API")
end

local scoreboard_string = storage:get_string("scoreboard")
if scoreboard_string and scoreboard_string ~= "" then
    better_commands.scoreboard = minetest.deserialize(scoreboard_string)
else
    better_commands.scoreboard = {objectives = {}, displays = {colors = {}}}
end

local team_string = storage:get_string("teams")
if team_string and team_string ~= "" then
    better_commands.teams = minetest.deserialize(team_string)
else
    better_commands.teams = {teams = {}, players = {}}
end

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer > better_commands.settings.save_interval then
        timer = 0
        storage:set_string("scoreboard", minetest.serialize(better_commands.scoreboard))
        storage:set_string("teams", minetest.serialize(better_commands.teams))
        better_commands.update_hud()
    end
end)

minetest.register_on_shutdown(function()
    storage:set_string("scoreboard", minetest.serialize(better_commands.scoreboard))
    storage:set_string("teams", minetest.serialize(better_commands.teams))
    storage:set_string("successful_shutdown", "true")
end)

minetest.register_on_joinplayer(function(player)
    better_commands.sidebars[player:get_player_name()] = {}
end)

minetest.register_on_item_pickup(function(itemstack, player)
    for _, objective in pairs(better_commands.scoreboard.objectives) do
        local score = objective.scores[player:get_player_name()]
        if score then -- don't bother with other players' scores
            if objective.criterion:sub(1, 10) == "picked_up." then
                local criterion_item = objective.criterion:sub(11, -1)
                local handled = better_commands.handle_alias(criterion_item)
                if handled and handled == itemstack:get_name() then
                    score.score = score.score + 1
                elseif criterion_item:sub(1, 6) == "group:" then
                    if minetest.get_item_group(itemstack:get_name(), criterion_item:sub(7, -1)) ~= 0 then
                        score.score = score.score + 1
                    end
                end
            end
        end
    end
end)