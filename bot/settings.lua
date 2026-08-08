local config = require('config')

local defaults = {
    difficulty = 'VE',
}

local data = config.load(defaults)

local settings = {}


function settings.get_difficulty()
    return data.difficulty
end


function settings.set_difficulty(value)

    value = value and value:upper() or nil

    local valid = {
        VE = true,
        E = true,
        N = true,
        D = true,
        VD = true,
    }

    if not valid[value] then
        return false
    end

    data.difficulty = value
    data:save()

    return true
end


return settings