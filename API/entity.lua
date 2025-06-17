--local bc = better_commands
local S = core.get_translator(core.get_current_modname())

---Gets the name of an entity
---@param obj core.ObjectRef|vector.Vector
---@param no_id? boolean
---@return string
function better_commands.get_entity_name(obj, no_id, no_format)
    if not obj.is_player then
        return S("Command Block")
    end
    ---@cast obj -vector.Vector
    if obj:is_player() then
        local player_name = obj:get_player_name()
        if no_format then return player_name end
        return better_commands.format_name(obj:get_player_name())
    else
        local luaentity = obj.get_luaentity and obj:get_luaentity()
        if luaentity then
            if no_id then
                return luaentity._nametag or luaentity.nametag or ""
            else
                local name = luaentity._nametag or luaentity.nametag
                if (not name) or name == "" then
                    name = luaentity.name
                    if name == "__builtin:item" then
                        local stack = ItemStack(luaentity.itemstring)
                        return stack:get_short_description()
                    elseif name == "__builtin:falling_node" then
                        local stack = ItemStack(luaentity.node.name)
                        if not stack:is_known() then return S("Unknown Falling Node") end
                        return S("Falling @1", stack:get_short_description())
                    end
                    return luaentity.description or better_commands.entity_names[name] or name
                else
                    return name
                end
            end
        else
            return S("???")
        end
    end
end

---Gets an entity's current rotation
---@param obj core.ObjectRef|vector.Vector
---@return vector.Vector
function better_commands.get_entity_rotation(obj)
---@diagnostic disable-next-line: param-type-mismatch
    if obj.is_player and obj:is_player() then
        return {x = obj:get_look_vertical(), y = obj:get_look_horizontal(), z = 0}
    elseif obj.get_rotation then
        return obj:get_rotation()
    else
        return vector.zero()
    end
end

---Sets an entity's rotation
---@param obj core.ObjectRef|any
---@param rotation vector.Vector
function better_commands.set_entity_rotation(obj, rotation)
    if not obj.is_player then return end
    if obj:is_player() then
        obj:set_look_vertical(rotation.x)
        obj:set_look_horizontal(rotation.y)
    elseif obj.set_rotation then
        -- I have absolutely no idea why the x-axis needs to be flipped.
        obj:set_rotation({x=-rotation.x, y=rotation.y, z=rotation.z})
    end
end

---Takes an object and a position, returns the rotation at which the object points at the position
---@param obj core.ObjectRef|vector.Vector
---@param pos vector.Vector
---@return vector.Vector
function better_commands.point_at_pos(obj, pos)
---@diagnostic disable-next-line: param-type-mismatch
    local obj_pos = obj.get_pos and obj:get_pos() or obj
---@diagnostic disable-next-line: param-type-mismatch
    if obj:is_player() then
        obj_pos.y = obj_pos.y + obj:get_properties().eye_height
    end
---@diagnostic disable-next-line: param-type-mismatch
    local result = vector.dir_to_rotation(vector.direction(obj_pos, pos))
    result.x = -result.x -- no clue why this is necessary
    return result
end

---Completes a context table
---@param name string The name of the player to use as context.executor if not supplied
---@param context? table The context table to complete (optional)
---@return contextTable?
function better_commands.complete_context(name, context)
    if not context then context = {} end
    context.executor = context.executor or core.get_player_by_name(name)
    if not context.executor then core.log("error", "Missing executor") return end
    context.pos = context.pos or context.executor:get_pos()
    context.rot = context.rot or better_commands.get_entity_rotation(context.executor)
    --context.anchor = context.anchor or "feet"
    context.origin = context.origin or name
    return context
end

function better_commands.entity_from_alias(alias, list)
    if core.registered_entities[alias] then return alias end
    local entities = better_commands.unique_entities[alias]
    if not entities then return end
    if list then return entities end
    return entities[math.random(1, #entities)]
end

---Handles Vector2 (yaw/pitch) rotation in split_param
---@param base_rot vector.Vector
---@param split_param splitParam
---@param i integer
---@param no_relative boolean?
---@return vector.Vector?
---@return string?
function better_commands.handle_vector2_rot(base_rot, split_param, i, no_relative)
    base_rot = table.copy(base_rot)
    if split_param[i] then
        if not split_param[i+1] then
            return nil, S("Missing second rotation coordinate")
        end
        if split_param[i].type == "number" then
            base_rot.y = math.rad(tonumber(split_param[i][3]) or 0)
        elseif split_param[i].type == "relative" and not no_relative then
            base_rot.y = base_rot.y+math.rad(tonumber(split_param[i][3]:sub(2,-1)) or 0)
        else
            return nil, S("Invalid rotation coordinate @1", split_param[i][3])
        end
        if split_param[i+1].type == "number" then
            base_rot.x = math.rad(tonumber(split_param[i+1][3]) or 0)
        elseif split_param[i+1].type == "relative" and not no_relative then
            base_rot.x = base_rot.x+math.rad(tonumber(split_param[i+1][3]:sub(2,-1)) or 0)
        else
            return nil, S("Invalid rotation coordinate @1", split_param[i+1][3])
        end
        return base_rot
    end
    return base_rot
end

---Handles rotation in various commands
---@param context contextTable
---@param victim core.ObjectRef|vector.Vector
---@param split_param splitParam[]
---@param i integer
---@return vector.Vector? result
---@return string? err
---@nodiscard
function better_commands.get_tp_rot(context, victim, split_param, i)
    local victim_rot = table.copy(context.rot)
    if split_param[i] then
        local yaw_pitch
        local facing
        if split_param[i].type == "number" or split_param[i].type == "relative" then
            yaw_pitch = true
        elseif split_param[i].type == "relative" then
            yaw_pitch = true
        elseif split_param[i][3] == "facing" then
            facing = true
        else
            return nil, S("Invalid rotation")
        end
        if yaw_pitch then
            return better_commands.handle_vector2_rot(victim_rot, split_param, i)
        elseif facing and split_param[i+1] then
            if split_param[i+1].type == "selector" then
                local targets, err = better_commands.parse_selector(split_param[i+1], context, true)
                if err or not targets then return nil, err end
---@diagnostic disable-next-line: param-type-mismatch
                local target_pos = targets[1].is_player and targets[1]:get_pos() or targets[1]
---@diagnostic disable-next-line: param-type-mismatch
                victim_rot = better_commands.point_at_pos(victim, target_pos)
            elseif split_param[i+1][3] == "entity" and split_param[i+2].type == "selector" then
                local targets, err = better_commands.parse_selector(split_param[i+2], context, true)
                if err or not targets then return nil, err end
---@diagnostic disable-next-line: param-type-mismatch
                local target_pos = targets[1].is_player and targets[1]:get_pos() or targets[1]
---@diagnostic disable-next-line: param-type-mismatch
                victim_rot = better_commands.point_at_pos(victim, target_pos)
            else
                local target_pos, err = better_commands.parse_pos(split_param, i+1, context)
                if err or not target_pos then return nil, err end
                victim_rot = better_commands.point_at_pos(victim, target_pos)
            end
        end
        if yaw_pitch or facing then
            return victim_rot
        end
    end
    return victim_rot
end

---Gets a player's gamemode
---@param player core.Player
---@return string?
function better_commands.get_gamemode(player)
    if player.is_player and player:is_player() then
        local gamemode
        if better_commands.mcl then
            gamemode = mcl_gamemode.get_gamemode(player)
        else
            gamemode = core.is_creative_enabled(player:get_player_name()) and "creative" or "survival"
        end
        return gamemode
    end
end

better_commands.gamemode_aliases = {
    [0] = "survival",
    [1] = "creative",
    ["0"] = "survival", -- not sure whether these are necessary
    ["1"] = "creative",
    s = "survival",
    c = "creative",
}