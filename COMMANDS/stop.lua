local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("stop", {
    description = "Stops the server",
    privs = {server = true},
    func = function(name, param, context)
        minetest.request_shutdown(S("Server stopping."), true, 0)
        return true, "", 1
    end
})