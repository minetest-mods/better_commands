local item_pattern = "[_%w]*:?[_%w]+"

better_commands.criteria_patterns = {
    "^killed_by%..*$",                                          -- killed_by.<entity name>
    "^teamkill%..*$",                                           -- teamkill.<team name>
    "^killedByTeam%..*$",                                       -- killedByTeam.<team name>
    "^picked_up%.%*$",                                          -- picked_up.*
    "^picked_up%."..item_pattern.."$",                          -- picked_up.<itemstring>
    "^mined%.%*$",                                              -- mined.*
    "^mined%."..item_pattern.."$",                              -- mined.<itemstring>
    "^dug%.%*$",                                                -- dug.*
    "^dug%."..item_pattern.."$",                                -- dug.<itemstring>
    "^placed%.%*$",                                             -- placed.*
    "^placed%."..item_pattern.."$",                             -- placed.<itemstring>
    "^crafted%.%*$",                                            -- crafted.*
    "^crafted%."..item_pattern.."$",                            -- crafted.<itemstring>
    --"^distanceTo%.%-?%d*%.?%d+,%-?%d*%.?%d+,%-?%d*%.?%d+$"    -- distanceTo.<x>,<y>,<z>
}

better_commands.valid_criteria = {
    dummy = true,
    trigger = true,
    deathCount = true,
    playerKillCount = true,
    health = true,
    --xp = better_commands.mcl and true,
    --level = better_commands.mcl and true,
    --food = (better_commands.mcl or minetest.get_modpath("stamina") and true),
    --air = true,
    --armor = (better_commands.mcl or minetest.get_modpath("3d_armor") and true)
}

---Validates a criterion
---@param criterion string
---@return boolean
function better_commands.validate_criterion(criterion)
    if better_commands.valid_criteria[criterion] then
        return true
    end
    for _, pattern in ipairs(better_commands.criteria_patterns) do
        if criterion:match(pattern) then
            return true
        end
    end
    return false
end

local function item_matches(item, criterion_item)
    if criterion_item == "*" then
        return true
    end
    item = better_commands.handle_alias(item)
    if not item then return end
    if criterion_item:sub(1, 6) == "group:" then
        return minetest.get_item_group(item, criterion_item:sub(7, -1)) ~= 0
    else
        return better_commands.handle_alias(criterion_item) == item
    end
end

if better_commands.settings.scoreboard_picked_up then
    minetest.register_on_item_pickup(function(itemstack, player)
        for _, objective in pairs(better_commands.scoreboard.objectives) do
            local score = objective.scores[player:get_player_name()]
            if not score then return end
            if objective.criterion:sub(1, 10) ~= "picked_up." then return end
            local criterion_item = objective.criterion:sub(11, -1)
            if item_matches(itemstack, criterion_item) then
                score.score = score.score + 1
            end
        end
    end)
end

if better_commands.settings.scoreboard_mined then
    minetest.register_on_dignode(function(pos, node, player)
        for _, objective in pairs(better_commands.scoreboard.objectives) do
            local score = objective.scores[player:get_player_name()]
            if not score then return end
            local offset
            if objective.criterion:sub(1, 6) == "mined." then
                offset = 6
            elseif objective.criterion:sub(1, 4) == "dug." then
                offset = 4
            else
                return
            end
            local criterion_item = objective.criterion:sub(offset + 1, -1)
            if item_matches(node.name, criterion_item) then
                score.score = score.score + 1
            end
        end
    end)
end

if better_commands.settings.scoreboard_placed then
    minetest.register_on_placenode(function(pos, node, player)
        for _, objective in pairs(better_commands.scoreboard.objectives) do
            local score = objective.scores[player:get_player_name()]
            if not score then return end
            if objective.criterion:sub(1, 7) ~= "placed." then return end
            local criterion_item = objective.criterion:sub(8, -1)
            if item_matches(node.name, criterion_item) then
                score.score = score.score + 1
            end
        end
    end)
end

if better_commands.settings.scoreboard_crafted then
    minetest.register_on_craft(function(itemstack, player)
        for _, objective in pairs(better_commands.scoreboard.objectives) do
            local score = objective.scores[player:get_player_name()]
            if not score then return end
            if objective.criterion:sub(1, 8) ~= "crafted." then return end
            local criterion_item = objective.criterion:sub(9, -1)
            if item_matches(itemstack, criterion_item) then
                score.score = score.score + 1
            end
        end
    end)
end

-- Tracks "health" objectives, also prevents damage if team PVP seting is on
minetest.register_on_player_hpchange(function(player, hp_change, reason)
    local player_name = player:get_player_name()
    if better_commands.settings.scoreboard_health then
        for _, def in pairs(better_commands.scoreboard.objectives) do
            if def.criterion == "health" then
                if def.scores[player_name] then
                    -- update *after* hp changed
                    minetest.after(0, function() def.scores[player_name].score = player:get_hp() end)
                end
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
            local attacker_name = attacker:get_player_name()
            local player_team = better_commands.teams.players[player_name]
            local attacker_team = better_commands.teams.players[attacker_name]
            if player_team and player_team == attacker_team then
                if better_commands.teams.teams[player_team].pvp == false then
                    return 0, true
                end
            end
        end
    end
    return hp_change
end)

if better_commands.settings.scoreboard_death then
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
end