local S = minetest.get_translator(minetest.get_current_modname())

better_commands.register_command("clear", {
    description = S("Clears player inventories"),
    privs = { server = true },
    params = S("[targets] [items] [maxCount]"),
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, S("Missing context"), 0 end
        local split_param = better_commands.parse_params(param)
        local selector = split_param[1]
        local targets, err
        if not selector then
            targets = {context.executor}
        else
            targets, err = better_commands.parse_selector(selector, context)
            if err or not targets then return false, err, 0 end
        end
        local filter
        if split_param[2] and split_param[2][3] == "*" then
            filter = "*"
        elseif split_param[2] then
            if split_param[2][5] then
                split_param[3] = split_param[2][5]
            end
            split_param[2][5] = nil
            split_param[2][6] = nil
            filter, err = better_commands.parse_item(split_param[2], true)
            if err or not filter then return false, err, 0 end
            minetest.log(dump(filter:get_name()))
        end
        local remove_max = tonumber(split_param[3] and split_param[3][3])
        if split_param[3] and not remove_max then
            return false, S("maxCount must be a number"), 0
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
        minetest.log(dump(split_param))
        for _, target in ipairs(targets) do
            if target.is_player and target:is_player() then
                local found = false
                local match_count = 0
                local inv = target:get_inventory()
                for _, list in ipairs(better_commands.settings.clear_lists) do
                    if inv:get_list(list) then
                        if all and remove_max == -1 then
                            inv:set_list(list, {})
                            found = true
                        elseif remove_max == 0 then
                            for _, stack in ipairs(inv:get_list(list)) do
                                if all then
                                    found = true
                                    match_count = match_count + stack:get_count()
                                elseif split_param[2].extra_data then
                                    if stack:peek_item(1):equals(filter) then
                                        found = true
                                        match_count = match_count + stack:get_count()
                                    end
    ---@diagnostic disable-next-line: param-type-mismatch
                                elseif stack:get_name() == filter:get_name() then
                                    found = true
                                    match_count = match_count + stack:get_count()
                                end
                            end
                        else
                            for i, stack in ipairs(inv:get_list(list)) do
                                local matches = false
                                if all then
                                    matches = true
                                elseif split_param[2].extra_data then
                                    if stack:peek_item(1):equals(filter) then
                                        matches = true
                                    end
    ---@diagnostic disable-next-line: param-type-mismatch
                                elseif stack:get_name() == filter:get_name() then
                                    matches = true
                                end
                                if matches then
                                    found = true
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
                        match_total = match_total + match_count
                    end
                end
                if found then
                    count = count + 1
                    last = better_commands.get_entity_name(target)
                end
            end
        end
        if count < 1 then
            return false, S("No matching players/items")
        elseif count == 1 then
            if remove_max == 0 then
                return true, S("@1 has @2 matching items", last, match_total), match_total
            elseif all and remove_max == -1 then
                return true, S("Removed all items from @1", last), 1
            else
                return true, S("Removed @1 items from @2", match_total, last), 1
            end
        else
            if remove_max == 0 then
                return true, S("@1 matching items found in @2 players' inventories", match_total, count), match_total
            elseif all and remove_max == -1 then
                return true, S("Removed all items from @1 players", count), 1
            else
                return true, S("Removed @1 items from @2 players", match_total, count), count
            end
        end
    end
})
