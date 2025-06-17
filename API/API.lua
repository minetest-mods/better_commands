---@alias contextTable {executor: core.ObjectRef, pos: vector.Vector, rot: vector.Vector, anchor: string, origin: string, [any]: any}
---@alias splitParam {[1]: integer, [2]: integer, [3]: string, type: string, any: string}
---@alias betterCommandFunc fun(name: string, param: string, context: contextTable): success: boolean, message: string?, count: number
---@alias betterCommandDef {description: string, param?: string, privs: table<string, boolean>, func: betterCommandFunc, real_func: betterCommandFunc?}

--local bc = better_commands


local modpath = core.get_modpath("better_commands")

---Runs a file
---@param file string
---@param subfolder string?
function better_commands.run_file(file, subfolder)
    dofile(string.format("%s%s%s.lua", modpath, subfolder and "/"..subfolder.."/" or "", file))
end

local api_files = {
    "storage",
    "damage",
    "entity",
    "parsing",
    "register",
    "scoreboard",
    "teams",
    "scoreboard_criteria",
    "spawnpoint",
}

better_commands.registered_on_update = {}

---Registers a function to be called every save_interval
---@param func function
function better_commands.register_on_update(func)
    table.insert(better_commands.registered_on_update, func)
end

better_commands.paused = false
local timer = 0
core.register_globalstep(function(dtime)
    if better_commands.paused then return end
    timer = timer + dtime
    if timer > better_commands.settings.save_interval then
        timer = 0
        for _, func in ipairs(better_commands.registered_on_update) do
            func()
        end
    end
end)

core.register_on_joinplayer(function(player)
    better_commands.sidebars[player:get_player_name()] = {}
end)

for _, file in ipairs(api_files) do
    better_commands.run_file(file, "API")
end

---Runs a Better Command (useful for debugging and stuff)
---@param input string
---@param player string?
function better_commands.run(input, executor_name)
    local command, param = input:match("%/?(%S+)%s+(.*)$")
    local context
    if executor_name then
        context = {executor = executor_name}
    else
        context = {executor = {x=0,y=0,z=0}, command_block = true, pos = {x=0,y=0,z=0}, dir = {x=0,y=0,z=0}}
    end
    if better_commands.commands[command] then
        better_commands.commands[command].func(executor_name or "", param, context)
    end
end