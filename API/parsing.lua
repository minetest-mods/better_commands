--local bc = better_commands
local S = minetest.get_translator(minetest.get_current_modname())

---Parses parameters out of a string
---@param str string
---@return splitParam[] split_param
function better_commands.parse_params(str)
    local i = 1
    local tmp
    local found = {}
    -- selectors, @?[data]
    repeat
        tmp = {str:find("(@[psaer])%s*(%[.-%])", i)}
        if tmp[1] then
            i = tmp[2] + 1
            tmp.type = "selector"
            tmp.extra_data = true
            table.insert(found, table.copy(tmp))
        end
    until not tmp[1]

    -- items/entities with extra data
    i = 1
    repeat
        -- modname:id[data] count wear (everything but id and data optional)
        tmp = {str:find("%s([_%w]*:?[_%w]+)%s*(%[.-%])%s*(%d*)%s*(%d*)", i)}
        if tmp[1] then
            tmp[1] = tmp[1] + 1 -- ignore the space
            local overlap
            for _, thing in pairs(found) do
                if tmp[1] >= thing[1] and tmp[1] <= thing[2]
                or tmp[2] >= thing[1] and tmp[2] <= thing[2]
                or tmp[1] <= thing[1] and tmp[2] >= thing[2] then
                    overlap = true
                    break
                end
            end
            i = tmp[2] + 1
            if not overlap then
                if better_commands.handle_alias(tmp[3]) then
                    tmp.type = "item"
                    tmp.extra_data = true
                    table.insert(found, table.copy(tmp))
                elseif better_commands.entity_from_alias(tmp[3]) then
                    tmp.type = "entity"
                    tmp.extra_data = true
                    table.insert(found, table.copy(tmp))
                end
            end
        end
    until not tmp[1]

    -- items/entities without extra data
    i = 1
    repeat
        -- modname:id count wear (everything but id optional)
        tmp = {str:find("(%s[_%w]*:?[_%w]+)%s*(%d*)%s*(%d*)", i)}
        if tmp[1] then
            tmp[1] = tmp[1] + 1 -- ignore the space
            local overlap
            for _, thing in pairs(found) do
                if tmp[1] >= thing[1] and tmp[1] <= thing[2]
                or tmp[2] >= thing[1] and tmp[2] <= thing[2]
                or tmp[1] <= thing[1] and tmp[2] >= thing[2] then
                    overlap = true
                    break
                end
            end
            i = tmp[2] + 1
            if not overlap then
                if better_commands.handle_alias(tmp[3]) then
                    tmp.type = "item"
                    table.insert(found, table.copy(tmp))
                elseif better_commands.entity_from_alias(tmp[3]) then
                    tmp.type = "entity"
                    table.insert(found, table.copy(tmp))
                end
            end
        end
    until not tmp[1]

    -- everything else
    i = 1
    repeat
        tmp = {str:find("(%S+)", i)}
        if tmp[1] then
            i = tmp[2] + 1
            local overlap
            for _, thing in pairs(found) do
                if tmp[1] >= thing[1] and tmp[1] <= thing[2]
                or tmp[2] >= thing[1] and tmp[2] <= thing[2]
                or tmp[1] <= thing[1] and tmp[2] >= thing[2] then
                    overlap = true
                    break
                end
            end
            if not overlap then
                if tmp[3]:find("^@[psaer]$") then
                    tmp.type = "selector"
                elseif better_commands.players[tmp[3]] then
                    tmp.type = "selector"
                elseif better_commands.handle_alias(tmp[3]) then
                    tmp.type = "item"
                elseif tonumber(tmp[3]) then
                    tmp.type = "number"
                elseif tmp[3]:lower() == "true" or tmp[3]:lower() == "false" then
                    tmp.type = "boolean"
                elseif tmp[3]:find("^~%-?%d*%.?%d*$") then
                    tmp.type = "relative"
                elseif tmp[3]:find("^%^%-?%d*%.?%d*$") then
                    tmp.type = "look_relative"
                else
                    tmp.type = "string"
                end
                table.insert(found, table.copy(tmp))
            end
        end
    until not tmp[1]

    -- sort
    table.sort(found, function(a,b)
        return a[1] < b[1]
    end)
    return found
end
---Returns true if num is in the range string, false if not, nil on failure
---@param num number
---@param range string
---@return boolean?
function better_commands.parse_range(num, range)
    if not (num and range) then return end
    if tonumber(range) then return num == range end
    -- "min..max" where both numbers are optional
    local _, _, min, max = range:find("(%d*%.?%d*)%s*%.%.%s*(%d*%.?%d*)")
    if not min then return end
    min = tonumber(min)
    max = tonumber(max)
    if min and num < min then return false end
    if max and num > max then return false end
    return true
end

-- key = handle duplicates automatically?
better_commands.supported_keys = {
    distance = true,
    name = false,
    type = false,
    r = true,
    rm = true,
    sort = true,
    limit = false,
    c = false,
    x = true,
    y = true,
    z = true,
    gamemode = false,
    m = false,
}

if better_commands.mcl then
    local mcl_only = {
        level = true,
        l = true,
        lm = true,
    }
    for key, value in pairs(mcl_only) do
        better_commands.supported_keys[key] = value
    end
end

---Parses a selector and returns a list of entities
---@param selector_data splitParam
---@param context contextTable
---@param require_one? boolean
---@return (minetest.ObjectRef|vector.Vector)[]? results
---@return string? err
---@nodiscard
function better_commands.parse_selector(selector_data, context, require_one)
    local caller = context.executor
    local pos = table.copy(context.pos)
    local result = {}
    if selector_data[3]:sub(1,1) ~= "@" then
        local player = minetest.get_player_by_name(selector_data[3])
        if not player then
            return nil, S("No player was found")
        else
            return {player}
        end
    end

    ---@type table<integer, {any: string}>
    local arg_table = {}

    if selector_data[4] then
        -- basically matching "(thing)=(thing)[,%]]"
        for key, value in selector_data[4]:gmatch("([%w_]+)%s*=%s*([^,%]]+)%s*[,%]]") do
            table.insert(arg_table, {key:trim(), value:trim()})
        end
    end

    local objects = {}
    local selector = selector_data[3]
    if selector == "@s" then
        return {caller}
    end
    if selector == "@e" or selector == "@a" or selector == "@p" or selector == "@r" then
        for _, player in pairs(minetest.get_connected_players()) do
            if player:get_pos() then
                table.insert(objects, player)
            end
        end
    end
    if selector == "@e" then
        for _, luaentity in pairs(minetest.luaentities) do
            if luaentity.object:get_pos() then
                table.insert(objects, luaentity.object)
            end
        end
    end
    -- Make type selector work for @r
    if selector == "@r" or selector == "@p" then
        for _, arg in ipairs(arg_table) do
            if arg[1] == "type" and arg[2]:lower() ~= "player" then
                for _, luaentity in pairs(minetest.luaentities) do
                    if luaentity.object:get_pos() then
                        table.insert(objects, luaentity.object)
                    end
                end
            end
        end
    end

    local sort
    if selector == "@p" then
        sort = "nearest"
    elseif selector == "@r" then
        sort = "random"
    else
        sort = "arbitrary"
    end
    local limit
    if selector == "@p" or selector == "@r" then limit = 1 end

    if arg_table then
        -- Look for pos first
        local checked = {}
        for _, arg in ipairs(arg_table) do
            local key, value = unpack(arg)
            if better_commands.supported_keys[key] == nil then
                return nil, S("Unknown option '@1'", key)
            elseif key == "x" or key == "y" or key == "z" then
                if checked[key] then
                    return nil, S("Duplicate option '@1'", key)
                end
                if value:sub(1,1) == "!" then
                    value = value:sub(2,-1)
                    if value == "" then value = 0 end
                end
                checked[key] = true
                pos[key] = tonumber(value)
                if not pos[key] then
                    return nil, S("Expected number for option '@1'", key)
                end
                checked[key] = true
            elseif key == "sort" then
                sort = value
            elseif key == "limit" or key == "c" then
                if checked.limit then
                    return nil, S("Only 1 of keys c and limit can exist")
                end
                checked.limit = true
                value = tonumber(value)
                if not value then
                    return nil, S("@1 must be a non-zero integer", key)
                end
                limit = math.floor(value)
                if limit == 0 then
                    return nil, S("@1 must be a non-zero integer", key)
                end
            end
        end

        for _, obj in pairs(objects) do
            checked = {}
            if obj.is_player then -- checks if it is a valid entity
                local matches = true
                for _, arg in pairs(arg_table) do
                    local key, value = unpack(arg)
                    if better_commands.supported_keys[key] == true then
                        if checked[key] then
                            return nil, S("Duplicate option '@1'", key)
                        end
                        checked[key] = true
                    end
                    if key == "distance" then
                        local distance = vector.distance(obj:get_pos(), pos)
                        if not better_commands.parse_range(distance, value) then
                            matches = false
                        end
                    elseif key == "type" then
                        value = value:lower()
                        local type_table = {}
                        if obj:is_player() then
                            type_table.player = true
                        else
                            local obj_type = obj:get_luaentity().name
                            local aliases = better_commands.entity_aliases[obj_type]
                            type_table = aliases and table.copy(aliases) or {}
                            type_table[obj_type] = true
                        end

                        if value:sub(1,1) == "!" then
                            if type_table[value:sub(2, -1)] then
                                matches = false
                            end
                        else
                            if checked.type then
                                return nil, S("Duplicate option '@1'", key)
                            end
                            checked.type = true
                            if not type_table[value] then
                                matches = false
                            end
                        end
                    elseif key == "name" then
                        local obj_name = better_commands.get_entity_name(obj, true, true)
                        if value:sub(1,1) == "!" then
                            if obj_name == value:sub(2, -1) then
                                matches = false
                            end
                        else
                            if checked.name then
                                return nil, S("Duplicate option '@1'", key)
                            end
                            checked.name = true
                            if obj_name ~= value then
                                matches = false
                            end
                        end
                    elseif key == "r" then
                        value = tonumber(value)
                        if not value then return nil, S("Expected number for option '@1'", key) end
                        matches = vector.distance(obj:get_pos(), pos) <= value
                    elseif key == "rm" then
                        value = tonumber(value)
                        if not value then return nil, S("Expected number for option '@1'", key) end
                        matches = vector.distance(obj:get_pos(), pos) >= value
                    elseif key == "level" then
                        if not (obj.is_player and obj:is_player()) then
                            matches = false
                        else
                            mcl_experience.update(obj)
                            local level = mcl_experience.get_level(obj)
                            if not better_commands.parse_range(level, value) then
                                matches = false
                            end
                        end
                    elseif key == "l" then
                        value = tonumber(value)
                        if not value then return nil, S("Expected number for option '@1'", key) end
                        if not (obj.is_player and obj:is_player()) then
                            matches = false
                        else
                            mcl_experience.update(obj)
                            local level = mcl_experience.get_level(obj)
                            matches = level <= value
                        end
                    elseif key == "lm" then
                        value = tonumber(value)
                        if not value then return nil, S("Expected number for option '@1'", key) end
                        if not (obj.is_player and obj:is_player()) then
                            matches = false
                        else
                            mcl_experience.update(obj)
                            local level = mcl_experience.get_level(obj)
                            matches = level >= value
                        end
                    elseif key == "gamemode" or key == "m" then
                        if checked.gamemode then
                            return nil, S("Only 1 of keys m and gamemode can exist")
                        end
                        checked.gamemode = true
                        if not (obj.is_player and obj:is_player()) then
                            matches = false
                        else
                            local gamemode = better_commands.gamemode_aliases[value] or value
                            if better_commands.mcl then
                                if table.indexof(mcl_gamemode.gamemodes, gamemode) == -1 then
                                    return nil, S("Unknown game mode: @1", gamemode)
                                end
                            elseif gamemode ~= "creative" and gamemode ~= "survival" then
                                return nil, S("Unknown game mode: @1", gamemode)
                            end
                            matches = better_commands.get_gamemode(obj) == gamemode
                        end
                    end
                    if not matches then
                        break
                    end
                end
                if matches then
                    table.insert(result, obj)
                end
            end
        end
    else
        result = objects
    end
    -- Sort
    if sort == "random" then
        table.shuffle(result)
    elseif sort == "nearest" or (sort == "furthest" and limit < 0) then
        table.sort(result, function(a,b) return vector.distance(a:get_pos(), pos) < vector.distance(b:get_pos(), pos) end)
    elseif sort == "furthest" or (sort == "nearest" and limit < 0) then
        table.sort(result, function(a,b) return vector.distance(a:get_pos(), pos) > vector.distance(b:get_pos(), pos) end)
    end
    -- Limit
    if limit then
        local new_result = {}
        local i = 1
        while i <= limit do
            if not result[i] then break end
            table.insert(new_result, result[i])
            i = i + 1
        end
        result = new_result
    end
    if require_one then
        if #result == 0 then
            return nil, S("No entity was found")
        elseif #result > 1 then
            return nil, S("Multiple matching entities found")
        end
    end

    return result
end

---Parses a position
---@param data splitParam[]
---@param start integer
---@param context contextTable
---@return vector.Vector? result
---@return string? err
---@nodiscard
function better_commands.parse_pos(data, start, context)
    local axes = {"x","y","z"}
    local result = table.copy(context.pos)
    local look
    for i = 0, 2 do
        if not data[start + i] then
            return nil, S("Missing coordinate")
        end
        local coordinate, _type = data[start + i][3], data[start + i].type
        if _type == "number" or tonumber(coordinate) then
            if look then
                return nil, S("Cannot mix local and global coordinates")
            end
            result[axes[i+1]] = tonumber(coordinate)
            look = false
        elseif _type == "relative" then
            if look then
                return nil, S("Cannot mix local and global coordinates")
            end
            result[axes[i+1]] = result[axes[i+1]] + (tonumber(coordinate:sub(2,-1)) or 0)
            look = false
        elseif _type == "look_relative" then
            if look == false then
                return nil, S("Cannot mix local and global coordinates")
            end
            result[axes[i+1]] = tonumber(coordinate:sub(2,-1)) or 0
            look = true
        else
            return nil, S("Invalid coordinate '@1'", coordinate)
        end
    end
    if look then
        -- There's almost definitely a better way to do this...
        -- All I know is when moving in the Y direction,
        -- X/Z are backwards, and when moving in the Z direction,
        -- Y is backwards... so I fixed it (probably badly)
        local result_x = vector.rotate(vector.new(result.x,0,0), context.rot)
        local result_y = vector.rotate(vector.new(0,result.y,0), context.rot)
        result_y.z = -result_y.z
        result_y.x = -result_y.x
        local result_z = vector.rotate(vector.new(0,0,result.z), context.rot)
        result_z.y = -result_z.y
        result = vector.add(vector.add(vector.add(context.pos, result_x), result_y), result_z)
    end
    return result
end

---Parses item data, returning an itemstack or err message
---@param item_data splitParam
---@return minetest.ItemStack? result
---@return string? err
---@nodiscard
function better_commands.parse_item(item_data, ignore_count)
    if not better_commands.handle_alias(item_data[3]) then
        return nil, S("Invalid item '@1'", item_data[3])
    end
    if item_data.type == "item" and not item_data.extra_data then
        local stack = ItemStack(item_data[3])
        if not ignore_count then
            stack:set_count(tonumber(item_data[4]) or 1)
        end
        stack:set_wear(tonumber(item_data[5]) or 0)
        return stack
    elseif item_data.type == "item" then
        local arg_table = {}
        if item_data[4] then
            -- basically matching (thing)=(thing) followed by , or ]
            for key, value in item_data[4]:gmatch("([%w_]+)%s*=%s*([^,%]]+)%s*[,%]]") do
                arg_table[key:trim()] = value:trim()
            end
        end
        local stack = ItemStack(item_data[3])
        if arg_table then
            local meta = stack:get_meta()
            for key, value in pairs(arg_table) do
                if key == "wear" then
                    stack:set_wear(tonumber(value) or 0)
                else
                    meta:set_string(key, value)
                end
            end
        end
        if not ignore_count then
            stack:set_count(tonumber(item_data[5]) or 1)
        end
        stack:set_wear(tonumber(item_data[6]) or stack:get_wear())
        return stack
    end
    return nil, S("Invalid item: '@1'", item_data[3])
end

---Parses node data, returns node and metadata table
---@param item_data splitParam
---@return minetest.Node? node
---@return table? metadata
---@return string? err
---@nodiscard
function better_commands.parse_node(item_data)
    if not item_data or item_data.type ~= "item" then
        return nil, nil, S("Invalid item")
    end
    local itemstring = better_commands.handle_alias(item_data[3])
    if not itemstring then
        return nil, nil, S("Unknown node '@1'", item_data[3])
    end
    if not minetest.registered_nodes[itemstring] then
        return nil, nil, S("'@1' is not a node", itemstring)
    end
    if item_data.type == "item" and not item_data.extra_data then
        return {name = itemstring}
    elseif item_data.type == "item" then
        local meta_table = {}
        local node_table = {name = itemstring}
        if item_data[4] then
            -- basically matching "(thing)=(thing)[,%]]"
            for key, value in item_data[4]:gmatch("([%w_]+)%s*=%s*([^,%]]+)%s*[,%]]") do
                local trimmed_key, trimmed_value = key:trim(), value:trim()
                if trimmed_key == "param1" or trimmed_key == "param2" then
                    node_table[trimmed_key] = trimmed_value
                else
                    meta_table[trimmed_key] = trimmed_value
                end
            end
        end
        return node_table, meta_table
    end
    return nil, nil, S("Invalid item '@1'", item_data[3])
end

---Parses a time string and returns a time (between 0 and 1)
---@param time string The time string to parse
---@param absolute? boolean Whether to add the result to the current time or not
---@return number? result
---@return string? err
---@nodiscard
function better_commands.parse_time_string(time, absolute)
    local result
    if better_commands.times[time] then return better_commands.times[time] end
    local amount, unit = time:match("^(%d*%.?%d+)(.?)$")
    if not amount or not tonumber(amount) then
        local hours, minutes = time:match("^([0-2]?%d):([0-5]%d)$")
        if not hours then
            return nil, S("Invalid amount")
        end
        amount = (tonumber(hours) + tonumber(minutes)/60) * 1000
        unit = "t"
    else
        if unit == "" then unit = "t" end
        amount = tonumber(amount)
    end
    -- The pattern shouldn't let through any negative numbers... but just in case
    if amount < 0 then return nil, S("Amount must not be negative") end
    if unit == "s" then
        local second_multiplier = tonumber(minetest.settings:get("time_speed")) or 72
        amount = amount * second_multiplier / 3.6 -- (3.6s = 1 millihour)
    elseif unit == "d" then
        amount = amount * 24000
    elseif unit ~= "t" then
        return nil, S("Invalid unit '@1'", unit)
    end

    if not absolute then
        result = (minetest.get_timeofday() + (amount/24000)) % 1
    elseif better_commands.settings.acovg_time then
        result = ((amount + 6000)/24000) % 1
    else
        result = (amount/24000) % 1
    end

    return result
end

---Takes command parameters (with the split version) and expands all selectors
---@param str string
---@param split_param splitParam[]
---@param index integer
---@param context contextTable
---@return string? result
---@return string? err
---@nodiscard
function better_commands.expand_selectors(str, split_param, index, context)
    local message = ""
    for i=index,#split_param do
        local data = split_param[i]
        local next_part = ""
        if data.type ~= "selector" then
            if split_param[i+1] then
---@diagnostic disable-next-line: param-type-mismatch
                next_part = str:sub(split_param[i][1], split_param[i+1][1]-1)
            else
---@diagnostic disable-next-line: param-type-mismatch
                next_part = str:sub(split_param[i][1], -1)
            end
        else
            local targets, err = better_commands.parse_selector(data, context)
            if err or not targets then
                return nil, err
            end
            for j, obj in ipairs(targets) do
                if j > 1 then next_part = next_part.." " end
                if not obj.is_player then -- this should only happen with @s
                    next_part = next_part..S("Command Block")
                    break
                end
                next_part = next_part..better_commands.get_entity_name(obj)
                if #targets == 1 then
                    break
                elseif j < #targets then
                    next_part = next_part..","
                end
            end
            if split_param[i+1] then
                if split_param[i][2]+1 < split_param[i+1][1] then
                    next_part = next_part..str:sub(split_param[i][2]+1, split_param[i+1][1]-1)
                end
            elseif split_param[i][2] < #str then
                next_part = next_part..str:sub(split_param[i][2]+1, -1)
            end
        end
        message = message..next_part
    end
    return message
end

---Handles item aliases
---@param itemstring string
---@return string|false itemstring corrected itemstring if valid, otherwise false
function better_commands.handle_alias(itemstring)
    local stack = ItemStack(itemstring)
    if (stack:is_known() and stack:get_name() ~= "unknown" and stack:get_name() ~= "") then
        return stack:get_name()
    end
    return false
end

---I wish #table would work for non-arrays...
---@param table table
---@return integer?
function better_commands.count_table(table)
    if type(table) ~= "table" then return end
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end