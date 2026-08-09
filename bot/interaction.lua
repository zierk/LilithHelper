local state = require('bot/state')
local logger = require('bot/logger')
local travel = require('bot/travel')
local entities = require('bot/entities')
local packets = require('packets')
local bit = require('bit')

require('pack')

local interaction = {}
local last_menu = nil


--------------------------------------------------
-- KI PURCHASE STATE
--------------------------------------------------

local ki_purchase = {
    active = false,
    menu_options = 0,
    merit_points = 0,
}

local MAIDEN_OPTION = 23
local MAIDEN_COST = 10
local TRISVAIN_MENU_ID = 892
local NORTHERN_SANDORIA = 231


--------------------------------------------------
-- BIT CHECK
--------------------------------------------------

local function has_bit(mask, offset)
    return math.floor(mask / 2^offset) % 2 == 1
end


--------------------------------------------------
-- INITIATE TRISVAIN
--------------------------------------------------

local function initiate_trisvain()

    local player = windower.ffxi.get_mob_by_target('me')
    local trisvain = windower.ffxi.get_mob_by_name('Trisvain')

    if not player or player.status > 0 then
        return false
    end

    if not trisvain then
        return false
    end

    if math.sqrt(trisvain.distance) >= 6 then
        return false
    end

    if not trisvain.valid_target or not trisvain.is_npc or bit.band(trisvain.spawn_type, 0xDF) ~= 2 then
        return false
    end

    windower.packets.inject_outgoing(0x01A, 'I2H2d2':pack(0xE1A, trisvain.id, trisvain.index, 0, 0, 0))

    return true
end


--------------------------------------------------
-- INCOMING NPC MENU TRACKING
--------------------------------------------------

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)

    if id ~= 0x032 and id ~= 0x034 then
        return
    end

    local packet = packets.parse('incoming', modified)

    if packet then
        last_menu = {
            npc = packet['NPC'],
            npc_index = packet['NPC Index'],
            zone = packet['Zone'],
            menu_id = packet['Menu ID'],
        }
    end

    --------------------------------------------------
    -- TRISVAIN KI PURCHASE MENU
    --------------------------------------------------

    if ki_purchase.active and id == 0x034 then

        local zone_id, menu_id = modified:unpack('H2', 43)

        if zone_id ~= NORTHERN_SANDORIA or menu_id ~= TRISVAIN_MENU_ID then
            return
        end

        ki_purchase.menu_options, ki_purchase.merit_points = modified:unpack('I2', 13)

        logger.debug('Trisvain merit points: '..tostring(ki_purchase.merit_points))

        if ki_purchase.merit_points < MAIDEN_COST then
            logger.info('Fewer than 10 merit points remaining. Farming complete.')
            ki_purchase.active = false
            return
        end

        if not has_bit(ki_purchase.menu_options, MAIDEN_OPTION) then
            logger.error("Maiden's phantom gem is not currently available.")
            ki_purchase.active = false
            return
        end

        windower.send_command('wait 2;setkey escape;wait .5;setkey escape up;')
    end
end)


--------------------------------------------------
-- TRISVAIN KI PURCHASE PACKET
--------------------------------------------------

windower.register_event('outgoing chunk', function(id, data, modified, injected, blocked)

    if not ki_purchase.active or id ~= 0x05B then
        return
    end

    local zone_id, menu_id = data:unpack('H2', 17)

    if zone_id ~= NORTHERN_SANDORIA or menu_id ~= TRISVAIN_MENU_ID then
        return
    end

    if data:byte(15) ~= 0 then
        return
    end

    if data:unpack('I', 9) == 0x40000000 then

        if ki_purchase.merit_points < MAIDEN_COST then
            return
        end

        if not has_bit(ki_purchase.menu_options, MAIDEN_OPTION) then
            return
        end

        initiate_trisvain()

        return data:sub(1,8)..string.char(0x02, MAIDEN_OPTION, 0, 0)..data:sub(13)
    end
end)


--------------------------------------------------
-- START NPC DIALOG
--------------------------------------------------

function interaction.start_dialog(mob)

    if not mob then
        logger.error('Cannot start dialog: invalid mob.')
        return nil
    end

    last_menu = nil

    logger.debug('Starting dialog with '..tostring(mob.name)..' | Index: '..tostring(mob.index))

    local packet = packets.new('outgoing', 0x01A, {
        ['Target'] = mob.id,
        ['Target Index'] = mob.index,
        ['Category'] = 0,
        ['Param'] = 0,
    })

    packets.inject(packet)

    local timeout = os.clock() + 5

    while state.running and os.clock() < timeout do

        if last_menu and last_menu.menu_id and (last_menu.npc == mob.id or last_menu.npc_index == mob.index) then
            logger.debug('Dialog opened: '..tostring(mob.name)..' | Menu ID: '..tostring(last_menu.menu_id))
            return last_menu.menu_id
        end

        coroutine.sleep(0.1)
    end

    logger.error('Timed out waiting for dialog from '..tostring(mob.name)..'.')

    return nil
end


--------------------------------------------------
-- SEND NPC DIALOG OPTION
--------------------------------------------------

function interaction.send_dialog_packet(mob, menu_id, option_index, automated, unknown_1, unknown_2)

    if not mob then
        return false
    end

    automated = automated or false
    unknown_1 = unknown_1 or 0
    unknown_2 = unknown_2 or 0

    packets.inject(packets.new('outgoing', 0x05B, {
        ['Target'] = mob.id,
        ['Target Index'] = mob.index,
        ['Option Index'] = option_index,
        ['_unknown1'] = unknown_1,
        ['_unknown2'] = unknown_2,
        ['Automated Message'] = automated,
        ['Zone'] = windower.ffxi.get_info().zone,
        ['Menu ID'] = menu_id,
    }))

    return true
end


--------------------------------------------------
-- WAIT FOR SPECIFIC HOME POINT
--------------------------------------------------

function interaction.wait_for_homepoint(zone_data, hp_number)

    local hp_data = zone_data.homepoints[hp_number]

    if not hp_data then
        logger.error('No Home Point #'..tostring(hp_number)..' configured for '..tostring(zone_data.name)..'.')
        return nil
    end

    logger.debug('Waiting for '..zone_data.name..' Home Point #'..hp_number..'...')

    while state.running and not travel.is_in_zone(zone_data.zone_id) do
        coroutine.sleep(0.5)
    end

    if not state.running then
        return nil
    end

    logger.debug('Zone confirmed: '..zone_data.name..'.')

    local hp = entities.wait_for_mob_by_name('Home Point #'..hp_number, false)

    if not hp then
        return nil
    end

    if hp.index ~= hp_data.index then
        logger.error('Unexpected Home Point index. Expected '..tostring(hp_data.index)..', found '..tostring(hp.index)..'.')
        return nil
    end

    logger.debug('Home Point confirmed: '..hp.name..' | Index: '..hp.index)

    return hp
end


--------------------------------------------------
-- BUY MAIDEN'S PHANTOM GEM
--------------------------------------------------

function interaction.buy_maidens_phantom_gem()

    logger.debug('Preparing Maiden phantom gem purchase.')

    ki_purchase.active = true
    ki_purchase.menu_options = 0
    ki_purchase.merit_points = 0

    if not initiate_trisvain() then
        ki_purchase.active = false
        logger.error('Unable to interact with Trisvain.')
        return false
    end

    return true
end


--------------------------------------------------
-- FINISH KI PURCHASE
--------------------------------------------------

function interaction.finish_key_item_purchase()
    ki_purchase.active = false
end


--------------------------------------------------
-- HOME POINT #2 -> SELBINA
--------------------------------------------------

function interaction.warp_northern_sandy_to_selbina()

    local hp = entities.wait_for_mob_by_name('Home Point #2', false)

    if not hp then
        return false
    end

    local menu_id = interaction.start_dialog(hp)

    if not menu_id then
        return false
    end

    if not interaction.send_dialog_packet(hp, menu_id, 8, true) then
        return false
    end

    if not interaction.send_dialog_packet(hp, menu_id, 2, true, 43) then
        return false
    end

    if not interaction.send_dialog_packet(hp, menu_id, 2, false, 43) then
        return false
    end

    logger.debug('Selbina Home Point warp packets sent.')

    return true
end


--------------------------------------------------
-- ENTER HTMB
--------------------------------------------------

function interaction.enter_htmb(difficulty)

    local conflux = entities.wait_for_mob_by_name('Veridical Conflux', false)

    if not conflux then
        logger.error('Unable to find Veridical Conflux.')
        return false
    end

    local menu_id = interaction.start_dialog(conflux)

    if not menu_id then
        logger.error('Unable to open Veridical Conflux menu.')
        return false
    end

    if difficulty == 'VE' then
        interaction.send_dialog_packet(conflux, menu_id, 16388, true, 1)
        interaction.send_dialog_packet(conflux, menu_id, 16388, false, 1)

    elseif difficulty == 'E' then
        interaction.send_dialog_packet(conflux, menu_id, 4, true, 1)
        interaction.send_dialog_packet(conflux, menu_id, 4, false, 1)

    elseif difficulty == 'N' then
        interaction.send_dialog_packet(conflux, menu_id, 49156, true)
        interaction.send_dialog_packet(conflux, menu_id, 49156, false)

    elseif difficulty == 'D' then
        interaction.send_dialog_packet(conflux, menu_id, 32772, true)
        interaction.send_dialog_packet(conflux, menu_id, 32772, false)

    elseif difficulty == 'VD' then
        interaction.send_dialog_packet(conflux, menu_id, 16388, true)
        interaction.send_dialog_packet(conflux, menu_id, 16388, false)

    else
        logger.error('Invalid HTMB difficulty: '..tostring(difficulty))
        return false
    end

    logger.info('HTMB entry request sent.')

    return true
end


return interaction