--local bc = better_commands
local S = core.get_translator(core.get_current_modname())

better_commands.register_command("setblock", {
    params = S("<pos> <block> [keep|replace]"),
    description = S("Places <block> at <pos>. If keep, only replace air"),
    func = function(name, param, context)
        local split_param = better_commands.parse_params(param)
        if not split_param[1] and split_param[2] and split_param[3] and split_param[4] then
            return false, nil, 0
        end
        local keep
        if split_param[5] then
            keep = split_param[5][3]:lower()
            if keep ~= "keep" and keep ~= "replace" then
                return false, better_commands.error(S("Last argument ust be either 'replace' (default)), 'keep', or missing, not @1", keep)), 0
            end
        end
        local pos, err = better_commands.parse_pos(split_param, 1, context)
        if err or not pos then return false, better_commands.error(err), 0 end
        local node, meta, err = better_commands.parse_node(split_param[4])
        if err or not node then return false, better_commands.error(err), 0 end

        if keep == "keep" and core.get_node(pos).name ~= "air" then
            return false, better_commands.error(S("Position is not empty")), 0
        end

        core.set_node(pos, node)

        if meta and meta ~= {} then
            local node_meta = core.get_meta(pos)
            for key, value in pairs(meta) do
                node_meta:set_string(key, value)
            end
        end
        return true, S("Node set"), 1
    end
})

better_commands.register_command_alias("setnode", "setblock")

--[[ bad (add group/* support)
better_commands.register_command("testforblock", {
    params = "<pos> <node>",
    description = "Tests whether a certain node is in a specific location.",
    privs = {server = true},
    func = function (name, param, context)
        local split_param = better_commands.parse_params(param)
        local pos, err = better_commands.parse_pos(split_param, 1, context)
        if err or not pos then return false, better_commands.error(err), 0 end
        local node_param = split_param[4]
        local node, node_meta, err = better_commands.parse_node(split_param[4])
        if err or not node then return false, better_commands.error(err), 0 end
        local found_node = core.get_node(pos)
        if found_node.name == node.name then
            local matches = true
            if node_meta then
                local meta = core.get_meta(pos)
                for key, value in pairs(node_meta) do
                    if meta:get_string(key) ~= value then
                end
            else
                return true, S("Node matches"), 1
            end
        end
        return false, better_commands.error("Node does not match"), 0
    end
})]]