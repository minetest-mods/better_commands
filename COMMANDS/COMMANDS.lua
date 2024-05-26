--local bc = better_commands

local command_files = {
    "command_runners",
    "give",
    "kill",
    "chat",
    "execute",
    "scoreboard",
    "teleport",
    "team",
    "time",
    "ability",
    "playsound",
    "setblock",
    "summon",
    "gamemode",
    "spawnpoint",
    "clear",
    "settings",
}

for _, file in ipairs(command_files) do
    better_commands.run_file(file, "COMMANDS")
end

better_commands.register_command("?", table.copy(minetest.registered_chatcommands.help))


--[[
-- Temporary commands for testing
better_commands.register_command("dumpscore",{func=function()minetest.log(dump(better_commands.scoreboard)) return true, nil, 1 end})
better_commands.register_command("dumpteam",{func=function()minetest.log(dump(better_commands.teams)) return true, nil, 1 end})
-- ]]
better_commands.register_command("pause", {func=function()better_commands.paused=true return true, nil, 1 end,privs={server=true}})
better_commands.register_command("resume", {func=function()better_commands.paused=false return true, nil, 1 end,privs={server=true}})