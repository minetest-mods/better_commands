--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("ability", {
    params = S("<player> <priv> [value]"),
    description = S("Sets <priv> of <player> to [value] (true/false). If [value] is not supplied, returns the existing value of <priv>"),
    privs = {privs = true},
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, S("Missing context"), 0 end
        if not context.executor then return false, S("Missing executor"), 0 end
        local split_param = better_commands.parse_params(param)
        if not split_param[1] then
            return false, nil, 0
        end
        local set = split_param[3] and split_param[3][3]:lower()
        if set and set ~= "true" and set ~= "false" then
            return false, S("[value] must be true or false (or missing), not '@1'", set), 0
        end
        local targets, err = better_commands.parse_selector(split_param[1], context, true)
        if err or not targets then return false, err, 0 end
        local priv = split_param[2] and split_param[2][3]
        local target = targets[1]
        if target.is_player and target:is_player() then
            local target_name = target:get_player_name()
            local privs = minetest.get_player_privs(target_name)
            if not set then
                if not priv then
                    local message = ""
                    local first = true
                    local count = 0
                    local sortable_privs = {}
                    for player_priv, value in pairs(privs) do
                        if value then
                            table.insert(sortable_privs, player_priv)
                            count = count + 1
                        end
                    end
                    table.sort(sortable_privs)
                    for _, player_priv in ipairs(sortable_privs) do
                        if not first then message = message..", " else first = false end
                        message = message..player_priv
                    end
                    return true, message, count
                else
                    if minetest.registered_privileges[priv] then
                        return true, S("@1 = @2", priv, tostring(privs[priv])), 1
                    else
                        return false, S("Invalid privilege: @1", priv), 0
                    end
                end
            else
                if not minetest.registered_privileges[priv] then
                    return false, S("Invalid privilege: @1", priv), 0
                else
                    if set == "true" then
                        privs[priv] = true
                    else
                        privs[priv] = nil
                    end
                    minetest.set_player_privs(target_name, privs)
                    minetest.chat_send_player(target_name, S(
                        "@1 privilege @2 by @3",
                        priv,
                        set == "true" and "granted" or "revoked",
                        better_commands.format_name(name)
                    ))
                    return true, S(
                        "@1 privilege @2 for @3",
                        set == "true" and "Granted" or "Revoked",
                        priv,
                        better_commands.format_name(name)
                    ), 1
                end
            end
        end
        return false, S("No matching entity found"), 0
    end
})