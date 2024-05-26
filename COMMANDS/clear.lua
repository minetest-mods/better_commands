local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("clear", {
    description = S("Clears player inventories"),
    privs = { server = true },
    params = S("[targets] [items] [maxCount]"),
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, minetest.colorize("red", S("Missing context")), 0 end
        local split_param = better_commands.parse_params(param)
        local selector = split_param[1]
        local targets, err
        if not selector then
            targets = {context.executor}
        else
            targets, err = better_commands.parse_selector(selector, context)
            if err or not targets then return false, minetest.colorize("red", err), 0 end
        end
        local filter, group
        if split_param[2] then
            if split_param[2][5] then
                split_param[3] = split_param[2][5]
            end
            split_param[2][5] = nil
            split_param[2][6] = nil

            if split_param[2][3] == "*" then
                filter = "*"
            elseif split_param[2][3]:sub(1,6) == "group:" then
                group = true
                filter = split_param[2][3]:sub(7, -1)
            else
                filter, err = better_commands.parse_item(split_param[2], true)
                if err or not filter then return false, minetest.colorize("red", err), 0 end
            end
        end
        local remove_max = tonumber(split_param[3] and split_param[3][3])
        if split_param[3] and not remove_max then
            return false, minetest.colorize("red", S("maxCount must be a number")), 0
        end
        if remove_max then
            remove_max = math.floor(remove_max)
        else
            remove_max = -1
        end
        local all = not filter or filter == "*"
        local last
        local count = 0
        local match_total = 0
        for _, target in ipairs(targets) do
            if target.is_player and target:is_player() then
                count = count + 1
                local match_count = 0
                local inv = target:get_inventory()
                for _, list in ipairs(better_commands.settings.clear_lists) do
                    local inv_list = inv:get_list(list)
                    if inv_list then
                        if all and remove_max == -1 then
                            inv:set_list(list, {})
                        elseif remove_max == 0 then
                            for _, stack in ipairs(inv_list) do
                                if all then
                                    match_count = match_count + stack:get_count()
                                elseif group then
                                    if minetest.get_item_group(stack:get_name(), filter) then
                                        match_count = match_count + stack:get_count()
                                    end
                                elseif split_param[2].extra_data then
                                    if stack:peek_item(1):equals(filter) then
                                        match_count = match_count + stack:get_count()
                                    end
    ---@diagnostic disable-next-line: param-type-mismatch
                                elseif stack:get_name() == filter:get_name() then
                                    match_count = match_count + stack:get_count()
                                end
                            end
                        else
                            for i, stack in ipairs(inv_list) do
                                local matches = false
                                if all then
                                    matches = true
                                elseif group then
                                    if minetest.get_item_group(stack:get_name(), filter) then
                                        matches = true
                                    end
                                elseif split_param[2].extra_data then
                                    if stack:peek_item(1):equals(filter) then
                                        matches = true
                                    end
    ---@diagnostic disable-next-line: param-type-mismatch
                                elseif stack:get_name() == filter:get_name() then
                                    matches = true
                                end
                                if matches then
                                    local count = stack:get_count()
                                    local to_remove = count
                                    if remove_max > 0 then
                                        to_remove = math.min(remove_max - match_count, count)
                                    end
                                    if to_remove == count then
                                        inv:set_stack(list, i, ItemStack(""))
                                        match_count = match_count + to_remove
                                    elseif to_remove > 0 then
                                        local result_count = count - to_remove
                                        if result_count > 0 then
                                            stack:set_count(result_count)
                                            inv:set_stack(list, i, stack)
                                        else
                                            inv:set_stack(list, i, ItemStack(""))
                                        end
                                        match_count = match_count + to_remove
                                    end
                                    if match_count >= remove_max and remove_max > 0 then
                                        break
                                    end
                                end
                            end
                            if match_count >= remove_max and remove_max > 0 then
                                break
                            end
                        end
                    end
                end
                if match_count > 0 or (all and remove_max == -1) then
                    match_total = match_total + match_count
                    last = better_commands.get_entity_name(target)
                end
            end
        end
        if count < 1 then
            return false, minetest.colorize("red", S("No player was found"))
        elseif count == 1 then
            if match_total < 1 then
                return false, minetest.colorize("red", S("No items were found on player @1", last))
            elseif remove_max == 0 then
                return true, S("Found @1 matching items(s) on player @2", match_total, last), match_total
            elseif all and remove_max == -1 then
                return true, S("Removed all items from player @1", match_total, last), 1
            else
                return true, S("Removed @1 item(s) from player @2", match_total, last), 1
            end
        else
            if match_total < 1 then
                return false, minetest.colorize("red", S("No items were found on @1 players", count))
            elseif remove_max == 0 then
                return true, S("Found @1 matching items(s) on @2 players", match_total, count), match_total
            elseif all and remove_max == -1 then
                return true, S("Removed all items from @1 players", count), 1
            else
                return true, S("Removed @1 items from @2 players", match_total, count), count
            end
        end
    end
})
