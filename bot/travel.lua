local logger = require('bot/logger')

local travel = {}


function travel.get_zone_id()
    local info = windower.ffxi.get_info()

    if not info then
        return nil
    end

    return info.zone
end


function travel.is_in_zone(zone_id)
    return travel.get_zone_id() == zone_id
end


function travel.find_nearby_homepoint(max_distance)
    max_distance = max_distance or 50.0

    local mobs = windower.ffxi.get_mob_array()

    if not mobs then
        return nil, nil
    end

    local closest_hp = nil
    local min_distance = max_distance

    for _, mob in pairs(mobs) do
        if mob.name and string.find(mob.name, 'Home Point') then

            local actual_distance = math.sqrt(mob.distance)

            if actual_distance < min_distance then
                min_distance = actual_distance
                closest_hp = mob
            end
        end
    end

    return closest_hp, min_distance
end


function travel.is_near_homepoint(index, max_distance)
    local hp, distance = travel.find_nearby_homepoint(max_distance)

    if not hp then
        return false, nil, nil
    end

    return hp.index == index, hp, distance
end


function travel.warp_homepoint(zone_name, hp_number)

    logger.info(
        'Warping to '..zone_name..
        ' Home Point #'..hp_number..'.'
    )

    windower.send_command(
        'sw hp "'..zone_name..'" '..hp_number
    )
end


return travel