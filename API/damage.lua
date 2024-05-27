--local bc = better_commands

---Deals damage; copied from Mineclonia's mcl_util.deal_damage
---@param target minetest.ObjectRef
---@param damage integer
---@param reason table?
---@param damage_immortal? boolean
function better_commands.deal_damage(target, damage, reason, damage_immortal)
	local luaentity = target:get_luaentity()

	if luaentity then
		if luaentity.deal_damage then -- Mobs Redo/Mobs MC
			--minetest.log("deal_damage")
			luaentity:deal_damage(damage, reason or {type = "generic"})
			return
        elseif luaentity.hurt then -- Animalia
			--minetest.log("hurt/indicate_damage")
            luaentity:hurt(damage)
            luaentity:indicate_damage()
            return
        elseif luaentity.health then -- Mobs Redo/Mobs MC/NSSM
			-- local puncher = mcl_reason and mcl_reason.direct or target
			-- target:punch(puncher, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = damage}}, vector.direction(puncher:get_pos(), target:get_pos()), damage)
			if luaentity.health > 0 then
				--minetest.log("luaentity.health")
				luaentity.health = luaentity.health - damage
				luaentity:check_for_death(reason)
				--minetest.log(luaentity.health)
			end
			return
		end
	end

	local hp = target:get_hp()
	local armorgroups = target:get_armor_groups()

	if hp > 0 and armorgroups and (damage_immortal or not armorgroups.immortal) then
		--minetest.log("set_hp")
		target:set_hp(hp - damage, reason)
	end
	--minetest.log("nothing")
end

-- Make sure players always die when /killed
minetest.register_on_player_hpchange(function(player, hp_change, reason)
    if reason.better_commands == "kill" then
        return math.min(hp_change, -1000000000), true
    end
    return hp_change
end, true)