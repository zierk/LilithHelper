_addon.name = 'LilithHelper'
_addon.author = 'Zierk'
_addon.version = '2.0'
_addon.commands = {'lilithhelper', 'lh'}


local bot = require('bot/bot')
local state = require('bot/state')
local logger = require('bot/logger')
local keyitems = require('bot/keyitems')
local zones = require('bot/zones')
local bot = require('bot/bot')


--------------------------------------------------
-- ZONE CHANGE
--------------------------------------------------

windower.register_event('zone change', function(new_id, old_id)

    if not state.running then
        return
    end

    if state.phase ~= 'fighting_boss' then
        return
    end

    coroutine.schedule(function()

        coroutine.sleep(2)

        if keyitems.has_named('maidens_phantom_gem') then
            logger.error("Left HTMB but Maiden's phantom gem is still present.")
            bot.stop()
            return
        end

        --------------------------------------------------
        -- NORMAL HTMB RETURN
        --------------------------------------------------

        if new_id == zones.selbina.zone_id then
            state.phase = 'post_htmb'
            logger.info('Returned to Selbina from HTMB. Resuming bot.')
            bot.run()
            return
        end

        --------------------------------------------------
        -- DEATH / HOME POINT RETURN
        --------------------------------------------------

        state.phase = 'acquire_key_item'

        logger.info('Returned from HTMB outside Selbina. Assuming Home Point return.')
        logger.info("Resuming acquisition of Maiden's phantom gem.")

        bot.run()

    end, 0.1)
end)


--------------------------------------------------
-- COMMANDS
--------------------------------------------------

windower.register_event('addon command', function(command, ...)

    command = command and command:lower() or ''

    if command == 'start' then
        bot.start()

    elseif command == 'stop' then
        bot.stop()

    elseif command == 'status' then
        bot.status()

    elseif command == 'debug' then
        bot.toggle_debug()

    end

end)