local state = require('bot/state')
local logger = require('bot/logger')
local travel = require('bot/travel')
local entities = require('bot/entities')
local packets = require('packets')

local interaction = {}
local last_menu = nil


--------------------------------------------------
-- INCOMING NPC MENU TRACKING
--------------------------------------------------

windower.register_event('incoming chunk', function(id, original, modified)

    if id ~= 0x032 and id ~= 0x034 then
        return
    end

    local packet = packets.parse('incoming', modified)

    if not packet then
        return
    end

    last_menu = {
        npc = packet['NPC'],
        npc_index = packet['NPC Index'],
        zone = packet['Zone'],
        menu_id = packet['Menu ID'],
    }
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

function interaction.send_dialog_packet(mob, menu_id, option_index, automated, unknown1)

    if not mob or not menu_id then
        logger.error('Cannot send dialog packet: invalid dialog state.')
        return false
    end

    local info = windower.ffxi.get_info()

    if not info or not info.zone then
        logger.error('Unable to determine current zone for dialog packet.')
        return false
    end

    unknown1 = unknown1 or 0

    local packet = packets.new('outgoing', 0x05B, {
        ['Target'] = mob.id,
        ['Option Index'] = option_index,
        ['_unknown1'] = unknown1,
        ['Target Index'] = mob.index,
        ['Automated Message'] = automated,
        ['_unknown2'] = 0,
        ['Zone'] = info.zone,
        ['Menu ID'] = menu_id,
    })

    packets.inject(packet)

    logger.debug('Dialog packet sent: Option='..tostring(option_index)..' | Menu='..tostring(menu_id)..' | Param='..tostring(unknown1))

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

    logger.debug('Waiting for Trisvain.')

    local trisvain = entities.wait_for_mob_by_name('Trisvain', false)

    if not trisvain then
        return false
    end

    local menu_id = interaction.start_dialog(trisvain)

    if not menu_id then
        return false
    end

    if not interaction.send_dialog_packet(trisvain, menu_id, 259, true) then
        return false
    end

    if not interaction.send_dialog_packet(trisvain, menu_id, 5890, false) then
        return false
    end

    logger.debug("Maiden's phantom gem purchase packets sent.")

    return true
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

    coroutine.sleep(1)

    windower.send_command('setkey enter down')
    coroutine.sleep(0.1)
    windower.send_command('setkey enter up')

    logger.info('HTMB entry request sent.')

    return true
end


return interaction