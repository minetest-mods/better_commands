--local bc = better_commands
local S = core.get_translator(core.get_current_modname())

---Gets a printable name ("name * count") for an itemstack
---@param itemstack core.ItemStack
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
    if err or not itemstack then return false, better_commands.error(err), 0 end
	if itemstack:is_empty() then
		return false, better_commands.error(S("Cannot give an empty item")), 0
	elseif (not itemstack:is_known()) or (itemstack:get_name() == "unknown") then
		return false, better_commands.error(S("Unknown item '@1'", itemstack:get_name())), 0
	-- Forbid giving 'ignore' due to unwanted side effects
	elseif itemstack:get_name() == "ignore" then
		return false, better_commands.error(S("Giving 'ignore' is not allowed")), 0
	end
	local receiverref = core.get_player_by_name(receiver)
	if receiverref == nil then
		return false, better_commands.error(S("No player was found")), 0
	end
	local leftover = receiverref:get_inventory():add_item("main", itemstack)
	if not leftover:is_empty() then
		core.add_item(receiverref:get_pos(), leftover)
	end
	-- The actual item stack string may be different from what the "giver"
	-- entered (e.g. big numbers are always interpreted as 2^16-1).
	local item_name = itemstack_name(itemstack)
	return true, S("Gave [@1] to @2", item_name, better_commands.format_name(receiver)), 1
end

better_commands.register_command("give", {
    params = S("<targets> <item>"),
    description = S("Gives <item> to <targets> (item can include metadata and count/wear)"),
    privs = {server = true},
    func = function(name, param, context)
        local split_param = better_commands.parse_params(param)
        if not (split_param[1] and split_param[2]) then
            return false, nil, 0
        end
		local message
        local targets, err = better_commands.parse_selector(split_param[1], context)
        if err or not targets then return false, better_commands.error(err), 0 end
		local count = 0
        for _, target in ipairs(targets) do
            if target.is_player and target:is_player() then
                local success, message, i = handle_give_command(target:get_player_name(), split_param[2])
                if not success then return success, message, 0 end
				count = count + i
            end
        end
		if count < 1 then
			return false, better_commands.error(S("No player was found")), 0
		elseif count == 1 then
			return true, message, 1
		else
			return true, S("Gave item(s) to @1 players", count), count
		end
    end
})

better_commands.register_command("giveme", {
    params = S("<item>"),
    description = S("Gives <item> to yourself (<item> can include metadata and count/wear)"),
    privs = {server = true},
    func = function(name, param, context)
		return better_commands.commands.give.real_func(name, "@s "..param, context)
    end
})