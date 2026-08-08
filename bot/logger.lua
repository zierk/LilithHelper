local state = require('bot/state')

local logger = {}


local function write(label, msg)
    local prefix = '\31\200[\31\05'.._addon.name..'\31\200]\31\207 '

    if label == 'DEBUG' then
        prefix = prefix..'\31\200DEBUG:\31\207 '

    elseif label == 'WARNING' then
        prefix = prefix..'\31\57WARNING:\31\207 '

    elseif label == 'ERROR' then
        prefix = prefix..'\31\123ERROR:\31\207 '
    end

    windower.add_to_chat(1, prefix..tostring(msg))
end


function logger.info(msg)
    write(nil, msg)
end


function logger.debug(msg)
    if not state.debug then
        return
    end

    write('DEBUG', msg)
end


function logger.warn(msg)
    write('WARNING', msg)
end


function logger.error(msg)
    write('ERROR', msg)
end


return logger