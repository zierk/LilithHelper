local state = require('bot/state')

local logger = {}

local function write(label, label_color, msg)
    local prefix = '\31\200[\31\05'.._addon.name..'\31\200]'

    if label then
        prefix = prefix..' \31'..label_color..label..':\31\207 '
    else
        prefix = prefix..'\31\207 '
    end

    windower.add_to_chat(1, prefix..tostring(msg))
end


function logger.info(msg)
    write(nil, nil, msg)
end


function logger.debug(msg)
    if not state.debug then
        return
    end

    write('DEBUG', 200, msg)
end


function logger.warn(msg)
    write('WARNING', 057, msg)
end


function logger.error(msg)
    write('ERROR', 123, msg)
end


return logger