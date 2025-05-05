--local bc = better_commands
local S = core.get_translator(core.get_current_modname())

better_commands.register_command("playsound", {
    params = S("<sound> <targets|pos> [<volume>] [<pitch>] [<maxDistance>]"),
    description = S("Plays a sound"),
    privs = {server = true},
    func = function(name, param, context)
        local split_param = better_commands.parse_params(param)
        if not (split_param[1] and split_param[2]) then
            return false, nil, 0
        end
        local targets, err, next
        if split_param[2].type == "selector" then
            targets, err = better_commands.parse_selector(split_param[2], context)
            if err or not targets then return false, better_commands.error(err), 0 end
            next = 3
        else
            local pos, err = better_commands.parse_pos(split_param, 2, context)
            if err or not pos then return false, better_commands.error(err), 0
            end
            targets = {pos}
            next = 5
        end
        local volume, pitch, distance = 1, 1, 32
        if split_param[next] then
---@diagnostic disable-next-line: cast-local-type
            volume = split_param[next][3]
            if volume and not tonumber(volume) then
                return false, better_commands.error(S("Must be a number, not @1", volume)), 0
            end
            volume = tonumber(volume)
            if split_param[next+1] then
---@diagnostic disable-next-line: cast-local-type
                pitch = split_param[next+1][3]
                if pitch and not tonumber(pitch) then
                    return false, better_commands.error(S("Must be a number, not @1", pitch)), 0
                end
                pitch = tonumber(pitch)
                if split_param[next+2] then
---@diagnostic disable-next-line: cast-local-type
                    distance = split_param[next+2][3]
                    if distance and not tonumber(distance) then
                        return false, better_commands.error(S("Must be a number, not @1", distance)), 0
                    end
                    distance = tonumber(distance)
                end
            end
        end
        for _, target in ipairs(targets) do
            local key = target.is_player and "object" or "pos"
            core.sound_play(
                split_param[1][3], {
                    gain = volume,
                    pitch = pitch,
                    [key] = target,
                    max_hear_distance = distance
                }
            )
        end
        return true, S("Sound played"), 1
    end
})