local S = minetest.get_translator("better_commands")

better_commands.register_command("enchant", {
    description = S("Enchant an item"),
    params = S("<selector> <enchantment> [<level>]"),
    privs = { give = true },
    func = function(name, param, context)
        local split_param, err = better_commands.parse_params(param)
        if err then return false, better_commands.error(err), 0 end
        local enchantment = split_param[2] and split_param[2][3]
        if not enchantment then return false, better_commands.error(S("Missing enchantment")), 0 end
        local level_str = split_param[3] and split_param[3][3]
        local level = tonumber(level_str or "1")
        local targets, err = better_commands.parse_selector(split_param[1], context)
        if err or not targets then return false, better_commands.error(err), 0 end
        local count = 0
        local last
        for _, target in ipairs(targets) do
            if target.is_player and target:is_player() then
                local itemstack = target:get_wielded_item()
                local can_enchant, errorstring, extra_info = mcl_enchanting.can_enchant(itemstack, enchantment, level)
                if not can_enchant then
                    if errorstring == "enchantment invalid" then
                        return false, better_commands.error(S("Invalid enchantment '@1'", enchantment)), 0
                    elseif errorstring == "item missing" then
                        return false, better_commands.error(S("@1 is not holding any item", better_commands.get_entity_name(target))), 0
                    elseif errorstring == "item not supported" then
                        return false,
                            better_commands.error(S("@1 cannot support that enchantment", itemstack:get_short_description())), 0
                    elseif errorstring == "level invalid" then
                        return false, better_commands.error(S("Invalid integer '@1'", level_str)), 0
                    elseif errorstring == "level too high" then
                        return false,
                            better_commands.error(
                                S("@1 is higher than the maximum level of @2 supported by that enchantment", level_str,
                                    extra_info)), 0
                    elseif errorstring == "level too small" then
                        return false,
                            better_commands.error(
                                S("@1 is lower than the minimum level of @2 supported by that enchantment", level_str,
                                    extra_info)), 0
                    elseif errorstring == "incompatible" then
                        return false,
                            better_commands.error(
                                S("@1 can't be combined with @2.",
                                    mcl_enchanting.get_enchantment_description(enchantment, level), extra_info)), 0
                    end
                else
                    count = count + 1
                    last = better_commands.get_entity_name(target)
                    target:set_wielded_item(mcl_enchanting.enchant(itemstack, enchantment, level))
                end
            end
        end
        if count < 1 then
            return false, better_commands.error(S("No player was found")), 0
        elseif count == 1 then
            return true, S("Applied enchantment @1 to @2's item", mcl_enchanting.get_enchantment_description(enchantment, level), last), 1
        else
            return true, S("Enchanted items of @1 players.", count), count
        end
    end
})

better_commands.register_command("forceenchant", {
    description = S("Forcefully enchant an item"),
    params = S("<selector> <enchantment> [<level>]"),
    privs = { give = true },
    func = function(name, param, context)
        local split_param, err = better_commands.parse_params(param)
        if err then return false, better_commands.error(err), 0 end
        local selector = split_param[1]
        local enchantment = split_param[2] and split_param[2][3]
        local level_str = split_param[3] and split_param[3][3]
        local level = tonumber(level_str or "1")
        local targets, err = better_commands.parse_selector(selector, context)
        if err or not targets then return false, better_commands.error(err), 0 end
        local count = 0
        local last
        for _, target in ipairs(targets) do
            if target.is_player and target:is_player() then
                local itemstack = target:get_wielded_item()
                local _, errorstring = mcl_enchanting.can_enchant(itemstack, enchantment, level)
                if errorstring == "enchantment invalid" then
                    return false, better_commands.error(S("Invalid enchantment '@1'", enchantment)), 0
                elseif errorstring == "item missing" then
                    return false, better_commands.error(S("@1 is not holding any item", better_commands.get_entity_name(target))), 0
                elseif errorstring == "item not supported" and not mcl_enchanting.is_enchantable(itemstack:get_name()) then
                    return false, better_commands.error(S("@1 cannot support that enchantment")), 0
                elseif errorstring == "level invalid" then
                    return false, better_commands.error(S("Invalid integer '@1'", level_str)), 0
                else
                    target:set_wielded_item(mcl_enchanting.enchant(itemstack, enchantment, level))
                    count = count + 1
                    last = better_commands.get_entity_name(target)
                end
            end
        end
        if count < 1 then
            return false, better_commands.error(S("No player was found")), 0
        elseif count == 1 then
            return true, S("Applied enchantment @1 to @2's item", mcl_enchanting.get_enchantment_description(enchantment, level), last), 1
        else
            return true, S("Enchanted items of @1 players.", count), count
        end
    end
})
