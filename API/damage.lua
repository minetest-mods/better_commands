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
			luaentity:deal_damage(damage, reason or {type = "generic"})
            minetest.log("deal_damage")
			return
        elseif luaentity.hurt then -- Animalia
            luaentity:hurt(damage)
            minetest.log("hurt")
            luaentity:indicate_damage()
            return
        elseif luaentity.health then -- Mobs Redo/Mobs MC/NSSM
			-- local puncher = mcl_reason and mcl_reason.direct or target
			-- target:punch(puncher, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = damage}}, vector.direction(puncher:get_pos(), target:get_pos()), damage)
			if luaentity.health > 0 then
                minetest.log("luaentity.health")
				luaentity.health = luaentity.health - damage
			end
			return
		end
	end

	local hp = target:get_hp()
	local armorgroups = target:get_armor_groups()

	if hp > 0 and armorgroups and (damage_immortal or not armorgroups.immortal) then
        minetest.log("set_hp")
		target:set_hp(hp - damage, reason)
	end
end

minetest.register_on_dieplayer(function(player, reason)
    local player_name = player:get_player_name()
    for _, def in pairs(better_commands.scoreboard.objectives) do
        if def.criterion == "deathCount" then
            if def.scores[player_name] then
                def.scores[player_name].score = def.scores[player_name].score + 1
            end
        end
    end
    local killer
    if reason._mcl_reason then
        killer = reason._mcl_reason.source
    else
        killer = reason.object
    end
    if killer and killer:is_player() then
        local player_name = player:get_player_name()
        local killer_name = killer:get_player_name()
        local player_team = better_commands.teams.players[player_name]
        local killer_team = better_commands.teams.players[killer_name]
        for _, def in pairs(better_commands.scoreboard.objectives) do
            if def.criterion == "playerKillCount" or (player_team and def.criterion == "teamkill."..player_team) then
                if def.scores[killer_name] then
                    def.scores[killer_name].score = def.scores[killer_name].score + 1
                end
            elseif killer_team and def.criterion == "killedByTeam."..killer_team then
                if def.scores[player_name] then
                    def.scores[player_name].score = def.scores[player_name].score + 1
                end
            elseif def.criterion == "killed_by.player" then
                if def.scores[player_name] then
                    def.scores[player_name].score = def.scores[player_name].score + 1
                end
            end
        end
    elseif killer then
        local killer_type = killer:get_luaentity().name
        for _, def in pairs(better_commands.scoreboard.objectives) do
            local killed_by = def.criterion:match("^killed_by%.(.*)$")
            if killed_by and (killer_type == killed_by or
            (better_commands.entity_aliases[killer_type] and better_commands.entity_aliases[killer_type][killed_by])) then
                if def.scores[player_name] then
                    def.scores[player_name].score = def.scores[player_name].score + 1
                end
            end
        end
    end
end)

-- Make sure players always die when /killed, also track hp
minetest.register_on_player_hpchange(function(player, hp_change, reason)
    if reason.better_commands == "kill" then
        return -player:get_properties().hp_max, true
    end
    local player_name = player:get_player_name()
    for _, def in pairs(better_commands.scoreboard.objectives) do
        if def.criterion == "health" then
            if def.scores[player_name] then
                minetest.after(0, function() def.scores[player_name].score = player:get_hp() end)
            end
        end
    end
    if hp_change < 0 then
        local attacker
        if reason._mcl_reason then
            attacker = reason._mcl_reason.source
        else
            attacker = reason.object
        end
        if attacker and attacker:is_player() then
            local player_name = player:get_player_name()
            local attacker_name = attacker:get_player_name()
            local player_team = better_commands.teams.players[player_name]
            local attacker_team = better_commands.teams.players[attacker_name]
            if player_team == attacker_team then
                if better_commands.teams.teams[player_team].pvp == false then
                    return 0, true
                end
            end
        end
    end
    return hp_change
end, true)