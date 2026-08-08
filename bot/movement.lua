local state = require('bot/state')
local logger = require('bot/logger')

local movement = {}


-- Returns the player's current X and Y coordinates.
function movement.get_position()
    local player = windower.ffxi.get_mob_by_target('me')

    if not player then
        return nil, nil
    end

    return player.x, player.y
end


-- Returns the distance between the player and a coordinate.
function movement.distance_to(destination)
    local x, y = movement.get_position()

    if not x or not y then
        return nil
    end

    local dx = destination[1] - x
    local dy = destination[2] - y

    return math.sqrt(dx * dx + dy * dy)
end


-- Begin moving toward a coordinate.
function movement.move_to(destination)

    if not destination then
        logger.error('Invalid movement destination.')
        return false
    end

    local x = destination[1]
    local y = destination[2]

    if not x or not y then
        logger.error('Movement destination is missing coordinates.')
        return false
    end

    state.movement_active = true

    logger.debug(
        'Moving to ('..
        string.format('%.3f', x)..', '..
        string.format('%.3f', y)..').'
    )

    windower.ffxi.run(x, y)

    return true
end


-- Stop player movement.
function movement.stop()

    windower.ffxi.run(false)

    state.movement_active = false

    logger.debug('Movement stopped.')
end


-- Check whether the player is within a specified distance of a destination.
function movement.has_arrived(destination, tolerance)

    tolerance = tolerance or 1.5

    local distance = movement.distance_to(destination)

    if not distance then
        return false
    end

    return distance <= tolerance
end


return movement