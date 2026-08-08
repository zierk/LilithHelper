local state = require('bot/state')
local logger = require('bot/logger')

local movement = {}


function movement.walk_to_coordinates(waypoint_list)

    if not waypoint_list or #waypoint_list == 0 then
        logger.error('No waypoints provided.')
        return false
    end

    if state.movement_active then
        logger.warn('Movement is already active.')
        return false
    end

    state.movement_active = true

    coroutine.schedule(function()

        for i = 1, #waypoint_list do

            if not state.movement_active or not state.running then
                break
            end

            local target_x = waypoint_list[i][1]
            local target_y = waypoint_list[i][2]

            logger.debug(
                string.format(
                    'Moving to waypoint %d/%d...',
                    i,
                    #waypoint_list
                )
            )

            while state.movement_active and state.running do

                local player_mob =
                    windower.ffxi.get_mob_by_target('me')

                if not player_mob then
                    logger.error('Unable to get player position.')
                    break
                end

                if not player_mob.hpp or player_mob.hpp <= 0 then
                    logger.error('Player is dead. Stopping movement.')
                    state.running = false
                    break
                end

                local angle = math.atan2(
                    target_y - player_mob.y,
                    target_x - player_mob.x
                )

                windower.ffxi.run(-angle)

                local distance = math.sqrt(
                    (player_mob.x - target_x)^2 +
                    (player_mob.y - target_y)^2
                )

                if distance < 1.0 then
                    break
                end

                coroutine.sleep(0.1)
            end
        end


        windower.ffxi.run(false)

        state.movement_active = false

        if state.running then
            logger.info('Final destination reached successfully.')
        else
            logger.debug('Movement cancelled.')
        end

    end, 0.1)

    return true
end


function movement.stop()

    state.movement_active = false

    windower.ffxi.run(false)

    logger.debug('Movement stopped.')
end


return movement