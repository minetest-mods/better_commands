local storage = minetest.get_mod_storage()

function better_commands.load(key, default)
    local value = storage:get_string(key)
    if value and value ~= "" then
        better_commands[key] = minetest.deserialize(value) or default
    else
        better_commands[key] = default
    end
end

function better_commands.save(key)
    storage:set_string(key, minetest.serialize(better_commands[key]))
end

better_commands.load("teams", {teams = {}})
better_commands.load("scoreboard", {objectives = {}, players = {}, displays = {colors = {}}})
better_commands.load("spawnpoints", {})

better_commands.register_on_update(function ()
    better_commands.save("scoreboard")
    better_commands.save("teams")
    better_commands.save("spawnpoints")
end)

minetest.register_on_shutdown(function()
    storage:set_string("scoreboard", minetest.serialize(better_commands.scoreboard))
    storage:set_string("teams", minetest.serialize(better_commands.teams))
    storage:set_string("spawnpoints", minetest.serialize(better_commands.spawnpoints))
    storage:set_string("successful_shutdown", "true")
end)

storage:set_string("successful_shutdown", "")