--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

---Gets a printable name ("name * count") for an itemstack
---@param itemstack minetest.ItemStack
---@return string
local function itemstack_name(itemstack)
	return string.format("%s [%s]", itemstack:get_count(), itemstack:get_short_description())
end

---Handles the /give and /giveme commands
---@param receiver string The name of the receiver
---@param stack_data splitParam
---@return boolean
---@return string? err
---@return number count
---@nodiscard
-- Modified from builtin/game/chat.lua
local function handle_give_command(receiver, stack_data)
	local itemstack, err = better_commands.parse_item(stack_data)
    if err or not itemstack then return false, minetest.colorize("red", err), 0 end
	if itemstack:is_empty() then
		return false, minetest.colorize("red", S("Cannot give an empty item")), 0
	elseif (not itemstack:is_known()) or (itemstack:get_name() == "unknown") then
		return false, minetest.colorize("red", S("Unknown item '@1'", itemstack:get_name())), 0
	-- Forbid giving 'ignore' due to unwanted side effects
	elseif itemstack:get_name() == "ignore" then
		return false, minetest.colorize("red", S("Giving 'ignore' is not allowed")), 0
	end
	local receiverref = minetest.get_player_by_name(receiver)
	if receiverref == nil then
		return false, minetest.colorize("red", S("No player was found")), 0
	end
	local leftover = receiverref:get_inventory():add_item("main", itemstack)
	if not leftover:is_empty() then
		minetest.add_item(receiverref:get_pos(), leftover)
	end
	-- The actual item stack string may be different from what the "giver"
	-- entered (e.g. big numbers are always interpreted as 2^16-1).
	local item_name = itemstack_name(itemstack)
	return true, S("Gave [@1] to @2", item_name, better_commands.format_name(receiver)), 1
end

better_commands.register_command("give", {
    params = S("<target> <item> [count] [wear]"),
    description = S("Gives [count] of <item> to <target>"),
    privs = {server = true},
    func = function(name, param, context)
        context = better_commands.complete_context(name, context)
        if not context then return false, minetest.colorize("red", S("Missing context")), 0 end
        if not context.executor then return false, minetest.colorize("red", S("Missing executor")), 0 end
        local split_param = better_commands.parse_params(param)
        if not (split_param[1] and split_param[2]) then
            return false, nil, 0
        end
		local message
        local targets, err = better_commands.parse_selector(split_param[1], context)
        if err or not targets then return false, minetest.colorize("red", err), 0 end
		local count = 0
        for _, target in ipairs(targets) do
            if target.is_player and target:is_player() then
                local success, message, i = handle_give_command(target:get_player_name(), split_param[2])
                if not success then return success, message, 0 end
				count = count + i
            end
        end
		if count < 1 then
			return false, minetest.colorize("red", S("No player was found")), 0
		elseif count == 1 then
			return true, message, 1
		else
			return true, S("Gave item(s) to @1 players", count), count
		end
    end
})

better_commands.register_command("giveme", {
    params = S("<item> [count] [wear]"),
    description = S("Gives [count] of <item> to yourself"),
    privs = {server = true},
    func = function(name, param, context)
		return better_commands.commands.give.real_func(name, "@s "..param, context)
    end
})