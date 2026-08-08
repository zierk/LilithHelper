local state = require('bot/state')
local logger = require('bot/logger')
local zones = require('bot/zones')
local keyitems = require('bot/keyitems')
local travel = require('bot/travel')
local movement = require('bot/movement')
local entities = require('bot/entities')
local interaction = require('bot/interaction')

local bot = {}


function bot.start()

    if state.running then
        logger.info('Bot is already running.')
        return
    end

    state.running = true
    state.phase = 'check_key_item'

    logger.info('Bot started.')

    bot.run()
end


function bot.run()

    if not state.running then
        return
    end

    --
    -- Check Maiden's phantom gem
    --

    if keyitems.has_named('maidens_phantom_gem') then

        logger.debug("Maiden's phantom gem found.")

        state.phase = 'travel_selbina'

        -- Selbina logic later.

        return
    end


    logger.debug("Maiden's phantom gem not found.")

    --
    -- Travel to Northern San d'Oria
    --

    state.phase = 'travel_northern_sandoria'

    local sandy = zones.northern_sandoria
    local hp_number = 2
    local hp_index = sandy.homepoints[hp_number].index

    local nearby_hp, distance =
        travel.find_nearby_homepoint(50)

    if nearby_hp
        and travel.is_in_zone(sandy.zone_id)
        and nearby_hp.index == hp_index then

        logger.debug(
            'Already at '..sandy.name..
            ' Home Point #'..hp_number..
            ' | Distance: '..string.format('%.2f', distance)
        )

    else

        travel.warp_homepoint(
            sandy.name,
            hp_number
        )

        local hp = interaction.wait_for_homepoint(
            sandy,
            hp_number
        )

        if not hp then
            return
        end

    end


    if not state.running then
        return
    end


    --
    -- Move to KI NPC
    --

    state.phase = 'move_to_ki_npc'

    movement.move_to(
        sandy.locations.ki_npc
    )

end


function bot.stop()

    if not state.running then
        logger.info('Bot is not running.')
        return
    end

    state.running = false
    state.phase = 'idle'

    if state.movement_active then
        movement.stop()
    end

    logger.info('Bot stopped.')
end


function bot.status()

    logger.info(
        'Running: '..tostring(state.running)..
        ' | Phase: '..tostring(state.phase)
    )
end


function bot.toggle_debug()

    state.debug = not state.debug

    logger.info(
        'Debug: '..tostring(state.debug)
    )
end


return bot