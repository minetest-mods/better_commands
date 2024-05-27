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

better_commands.load("teams", {teams = {}, players = {}})
better_commands.load("scoreboard", {objectives = {}, players = {}, displays = {colors = {}}})
better_commands.load("spawnpoints", {})

better_commands.register_on_update(function ()
    better_commands.save("scoreboard")
    better_commands.save("teams")
    better_commands.save("spawnpoints")
end)

minetest.register_on_shutdown(function()
    better_commands.save("scoreboard")
    better_commands.save("teams")
    better_commands.save("spawnpoints")
    storage:set_string("successful_shutdown", "true")
end)

-- IDK if I'll ever do anything with successful_shutdown
storage:set_string("successful_shutdown", "")