_addon.name = 'LilithHelper'
_addon.author = 'Zierk'
_addon.version = '2.0'
_addon.commands = {'lilithhelper', 'lh'}

local bot = require('bot/bot')
local ipc = require('bot/ipc')
local state = require('bot/state')
local logger = require('bot/logger')
local keyitems = require('bot/keyitems')
local zones = require('bot/zones')
local settings = require('bot/settings')


--------------------------------------------------
-- ZONE CHANGE
--------------------------------------------------

windower.register_event('zone change', function(new_id, old_id)

    if not state.running then
        return
    end

    --------------------------------------------------
    -- ENTERING LILITH BATTLEFIELD
    --------------------------------------------------

    if new_id == zones.lilith_battlefield.zone_id then

        state.phase = 'fighting_boss'

        logger.info('Entered Lilith battlefield. Bot waiting for fight to finish.')

        return
    end

    --------------------------------------------------
    -- IGNORE ALL OTHER ZONE CHANGES UNLESS
    -- WE ARE ACTUALLY LEAVING THE BATTLEFIELD
    --------------------------------------------------

    if old_id ~= zones.lilith_battlefield.zone_id then
        return
    end

    --------------------------------------------------
    -- LEAVING LILITH BATTLEFIELD
    --------------------------------------------------

    coroutine.schedule(function()

        -- Allow zoning and KI state to fully update.
        coroutine.sleep(2)

        if not state.running then
            return
        end

        --------------------------------------------------
        -- NORMAL RETURN TO SELBINA
        --------------------------------------------------

        if new_id == zones.selbina.zone_id then

            if keyitems.has_named('maidens_phantom_gem') then
                logger.error("Returned from HTMB but Maiden's phantom gem is still present.")
                bot.stop()
                return
            end

            state.phase = 'post_htmb'

            logger.info('Returned to Selbina from HTMB. Resuming bot.')

            bot.run()
            return
        end

        --------------------------------------------------
        -- DEATH / HOME POINT RETURN
        --------------------------------------------------

        if keyitems.has_named('maidens_phantom_gem') then
            logger.error("Left HTMB but Maiden's phantom gem is still present.")
            bot.stop()
            return
        end

        state.phase = 'acquire_key_item'

        logger.info('Returned from HTMB outside Selbina. Assuming Home Point return.')
        logger.info("Resuming acquisition of Maiden's phantom gem.")

        bot.run()

    end, 0.1)
end)


--------------------------------------------------
-- IPC
--------------------------------------------------

windower.register_event('ipc message', function(message)

    local action, delay = ipc.handle_message(message)

    if action == 'start' then

        coroutine.schedule(function()

            coroutine.sleep(delay)

            bot.start()

        end, 0.1)

    elseif action == 'stop' then

        bot.stop()

    elseif action == 'status' then

        bot.status()

    end
end)


--------------------------------------------------
-- COMMANDS
--------------------------------------------------

windower.register_event('addon command', function(command, ...)

    command = command and command:lower() or ''

    local args = {...}

    --------------------------------------------------
    -- MULTIBOX COMMANDS
    --------------------------------------------------

    if command == '@all' then

        local subcommand = args[1] and args[1]:lower() or ''

        if subcommand == 'start' then
            ipc.start_all(bot.start)

        elseif subcommand == 'stop' then
            ipc.stop_all(bot.stop)

        elseif subcommand == 'status' then
            ipc.status_all(bot.status)

        else
            logger.info('Usage: //lh @all <start|stop|status>')
        end

        return
    end

    --------------------------------------------------
    -- LOCAL COMMANDS
    --------------------------------------------------

    if command == 'start' then

        bot.start()

    elseif command == 'stop' then

        bot.stop()

    elseif command == 'status' then

        bot.status()

    elseif command == 'debug' then

        bot.toggle_debug()

    elseif command == 'difficulty' then

        local difficulty = args[1]

        if not difficulty then
            logger.info('Current difficulty: '..settings.get_difficulty())
            logger.info('Usage: //lh difficulty <VE|E|N|D|VD>')
            return
        end

        if not settings.set_difficulty(difficulty) then
            logger.error('Invalid difficulty. Use VE, E, N, D, or VD.')
            return
        end

        logger.info('HTMB difficulty set to '..settings.get_difficulty()..'.')

    else

        logger.info('Commands: start | stop | status | @all <start|stop|status> | debug | difficulty <VE|E|N|D|VD>')

    end
end)


--- DELETE ME AFTER DEV
local packets = require('packets')

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)

    if id ~= 0x034 then
        return
    end

    local packet = packets.parse('incoming', modified)

    if not packet then
        return
    end

    windower.add_to_chat(207,
        'IN 0x034 | NPC='..tostring(packet['NPC'])..
        ' | Index='..tostring(packet['NPC Index'])..
        ' | Zone='..tostring(packet['Zone'])..
        ' | Menu='..tostring(packet['Menu ID'])
    )
end)


windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)

    if id ~= 0x05B then
        return
    end

    local packet = packets.parse('outgoing', original)

    if not packet then
        return
    end

    windower.add_to_chat(207,
        'OUT 0x05B | Target='..tostring(packet['Target'])..
        ' | Index='..tostring(packet['Target Index'])..
        ' | Option='..tostring(packet['Option Index'])..
        ' | Unknown1='..tostring(packet['_unknown1'])..
        ' | Unknown2='..tostring(packet['_unknown2'])..
        ' | Auto='..tostring(packet['Automated Message'])..
        ' | Zone='..tostring(packet['Zone'])..
        ' | Menu='..tostring(packet['Menu ID'])
    )
end)