--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("setblock", {
    params = "<pos> <block> [keep|replace]",
    description = S("Places <block> at <pos>. If keep, only replace air"),
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, S("Missing context"), 0 end
        if not context.executor then return false, S("Missing executor"), 0 end
        local split_param = better_commands.parse_params(param)
        if not split_param[1] and split_param[2] and split_param[3] and split_param[4] then
            return false, nil, 0
        end
        local keep
        if split_param[5] then
            keep = split_param[5][3]:lower()
            if keep ~= "keep" and keep ~= "replace" then
                return false, S("Last argument ust be either 'replace' (default), 'keep', or missing, not @1", keep), 0
            end
        end
        local pos, err = better_commands.parse_pos(split_param, 1, context)
        if err or not pos then return false, err, 0 end
        local node, meta, err = better_commands.parse_node(split_param[4])
        if err or not node then return false, err, 0 end

        if keep == "keep" and minetest.get_node(pos).name ~= "air" then
            return false, S("Position is not empty"), 0
        end

        minetest.set_node(pos, node)

        if meta and meta ~= {} then
            local node_meta = minetest.get_meta(pos)
            for key, value in pairs(meta) do
                node_meta:set_string(key, value)
            end
        end
        return true, S("Node set"), 1
    end
})

better_commands.register_command_alias("setnode", "setblock")