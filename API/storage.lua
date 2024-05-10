local storage = minetest.get_mod_storage()

function better_commands.load(key)
    local value = storage:get_string("teams")
    if value and value ~= "" then
        better_commands[key] = minetest.deserialize(value)
    else
        better_commands[key] = {teams = {}, players = {}}
    end
end

better_commands.load("teams")
better_commands.load("scoreboard")
better_commands.load("spawnpoints")

better_commands.register_on_update(function ()
    storage:set_string("scoreboard", minetest.serialize(better_commands.scoreboard))
    storage:set_string("teams", minetest.serialize(better_commands.teams))
    storage:set_string("spawnpoints", minetest.serialize(better_commands.spawnpoints))
end)

minetest.register_on_shutdown(function()
    storage:set_string("scoreboard", minetest.serialize(better_commands.scoreboard))
    storage:set_string("teams", minetest.serialize(better_commands.teams))
    storage:set_string("spawnpoints", minetest.serialize(better_commands.spawnpoints))
    storage:set_string("successful_shutdown", "true")
end)

storage:set_string("successful_shutdown", "")