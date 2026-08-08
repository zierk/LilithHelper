local state = require('bot/state')
local logger = require('bot/logger')
local zones = require('bot/zones')
local keyitems = require('bot/keyitems')
local travel = require('bot/travel')
local movement = require('bot/movement')
local interaction = require('bot/interaction')

local bot = {}


--------------------------------------------------
-- WAIT FOR MOVEMENT
--------------------------------------------------

local function wait_for_movement()

    while state.movement_active do
        if not state.running then
            return false
        end

        coroutine.sleep(0.25)
    end

    return state.running
end


--------------------------------------------------
-- MOVE TO SINGLE LOCATION
--------------------------------------------------

local function move_to(location)

    local started = movement.walk_to_coordinates({location})

    if not started then
        return false
    end

    return wait_for_movement()
end


--------------------------------------------------
-- TRAVEL TO NORTHERN SAN D'ORIA HP #2
--------------------------------------------------

local function get_to_northern_sandy_hp()

    local sandy = zones.northern_sandoria
    local hp_number = 2
    local hp_index = sandy.homepoints[hp_number].index

    local nearby_hp, distance = travel.find_nearby_homepoint(50)

    if nearby_hp and travel.is_in_zone(sandy.zone_id) and nearby_hp.index == hp_index then
        logger.debug('Already at '..sandy.name..' Home Point #2 | Distance: '..string.format('%.2f', distance))
        return nearby_hp
    end

    state.phase = 'travel_northern_sandoria'

    travel.warp_homepoint(sandy.name, hp_number)

    return interaction.wait_for_homepoint(sandy, hp_number)
end


--------------------------------------------------
-- ACQUIRE MAIDEN'S PHANTOM GEM
--------------------------------------------------

local function acquire_key_item()

    local sandy = zones.northern_sandoria

    local hp = get_to_northern_sandy_hp()

    if not hp or not state.running then
        return false
    end

    state.phase = 'move_to_ki_npc'

    logger.info('Moving to Trisvain.')

    if not move_to(sandy.locations.ki_npc) then
        return false
    end

    state.phase = 'buy_key_item'

    logger.info("Acquiring Maiden's phantom gem.")

    if not interaction.buy_maidens_phantom_gem() then
        logger.error("Failed to purchase Maiden's phantom gem.")
        return false
    end

    state.phase = 'wait_for_key_item'

    logger.debug("Waiting for Maiden's phantom gem.")

    while state.running and not keyitems.has_named('maidens_phantom_gem') do
        coroutine.sleep(0.5)
    end

    if not state.running then
        return false
    end

    logger.info("Maiden's phantom gem acquired.")

    state.phase = 'key_item_acquired'

    coroutine.sleep(1)

    return true
end


--------------------------------------------------
-- NORTHERN SAN D'ORIA -> SELBINA
--------------------------------------------------

local function northern_sandy_to_selbina()

    local sandy = zones.northern_sandoria
    local selbina = zones.selbina

    state.phase = 'return_to_homepoint'

    logger.info('Returning to Home Point #2.')

    if not move_to(sandy.locations.hp2) then
        logger.error('Failed to return to Home Point #2.')
        return false
    end

    --------------------------------------------------
    -- VERIFY WE ARE PHYSICALLY BACK AT HP #2
    --------------------------------------------------

    while state.running do
        local player = windower.ffxi.get_mob_by_target('me')

        if not player then
            coroutine.sleep(0.25)
        else
            local target_x = sandy.locations.hp2[1]
            local target_y = sandy.locations.hp2[2]

            local distance = math.sqrt((player.x - target_x)^2 + (player.y - target_y)^2)

            if distance <= 1.5 then
                logger.debug('Arrived back at Home Point #2.')
                break
            end

            coroutine.sleep(0.25)
        end
    end

    if not state.running then
        return false
    end

    --------------------------------------------------
    -- NOW WAIT FOR / VERIFY HOME POINT #2
    --------------------------------------------------

    local hp = interaction.wait_for_homepoint(sandy, 2)

    if not hp or not state.running then
        return false
    end

    --------------------------------------------------
    -- ONLY NOW ATTEMPT SELBINA WARP
    --------------------------------------------------

    state.phase = 'warp_selbina'

    logger.info('Warping to Selbina.')

    local starting_zone = travel.get_zone_id()

    if not interaction.warp_northern_sandy_to_selbina() then
        logger.error('Failed to initiate Selbina warp.')
        return false
    end

    local new_zone = travel.wait_for_zone_change(starting_zone)

    if not new_zone then
        return false
    end

    local selbina_hp = interaction.wait_for_homepoint(selbina, 1)

    if not selbina_hp then
        logger.error('Selbina loaded, but Home Point #1 was not found.')
        return false
    end

    logger.info('Arrived in Selbina.')

    return true
end


--------------------------------------------------
-- MAIN BOT LOOP
--------------------------------------------------

function bot.run()

    local sandy = zones.northern_sandoria
    local selbina = zones.selbina

    while state.running do

        --------------------------------------------------
        -- NO KI
        --------------------------------------------------

        if not keyitems.has_named('maidens_phantom_gem') then

            state.phase = 'acquire_key_item'

            logger.debug("Maiden's phantom gem not found.")

            if not acquire_key_item() then
                return
            end


        --------------------------------------------------
        -- HAVE KI + IN NORTHERN SAN D'ORIA
        --------------------------------------------------

        elseif travel.is_in_zone(sandy.zone_id) then

            logger.debug("Maiden's phantom gem found in "..sandy.name..'.')

            if not northern_sandy_to_selbina() then
                return
            end


        --------------------------------------------------
        -- HAVE KI + IN SELBINA
        --------------------------------------------------

        elseif travel.is_in_zone(selbina.zone_id) then

            state.phase = 'selbina'

            logger.debug("Maiden's phantom gem found.")
            logger.info('Ready to begin Selbina routine.')

            -- Next stage:
            -- Move from Home Point #1 through
            -- the Selbina waypoints to the HTMB.

            return


        --------------------------------------------------
        -- HAVE KI SOMEWHERE ELSE
        --------------------------------------------------

        else

            state.phase = 'travel_selbina'

            logger.info("Maiden's phantom gem already owned. Traveling to Selbina.")

            travel.warp_homepoint(selbina.name, 1)

            local hp = interaction.wait_for_homepoint(selbina, 1)

            if not hp then
                return
            end
        end

        coroutine.sleep(0.25)
    end
end


--------------------------------------------------
-- START
--------------------------------------------------

function bot.start()

    if state.running then
        logger.info('Bot is already running.')
        return
    end

    state.running = true
    state.phase = 'starting'

    logger.info('Bot started.')

    coroutine.schedule(function()
        bot.run()
    end, 0.1)
end


--------------------------------------------------
-- STOP
--------------------------------------------------

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


--------------------------------------------------
-- STATUS
--------------------------------------------------

function bot.status()

    logger.info('Running: '..tostring(state.running)..' | Phase: '..tostring(state.phase)..' | Moving: '..tostring(state.movement_active))
end


--------------------------------------------------
-- DEBUG
--------------------------------------------------

function bot.toggle_debug()

    state.debug = not state.debug

    logger.info('Debug: '..tostring(state.debug))
end


return bot