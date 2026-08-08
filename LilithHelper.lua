_addon.name = 'LilithHelper'
_addon.author = 'Zierk'
_addon.version = '2.0'
_addon.commands = {'lilithhelper', 'lh'}

local bot = require('bot/bot')

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