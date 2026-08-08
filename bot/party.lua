local logger = require('bot/logger')

local party = {}


function party.is_solo()

    local data = windower.ffxi.get_party()

    if not data then
        return true
    end

    return not data.party1_count or data.party1_count <= 1
end


function party.is_leader()

    local player = windower.ffxi.get_player()
    local data = windower.ffxi.get_party()

    if not player or not data then
        return false
    end

    if party.is_solo() then
        return true
    end

    return data.party1_leader == player.id
end


function party.can_initiate_htmb()
    return party.is_solo() or party.is_leader()
end


return party