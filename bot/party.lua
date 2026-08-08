local logger = require('bot/logger')
local state = require('bot/state')

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


--------------------------------------------------
-- CHECK ALL PARTY MEMBERS IN ZONE
--------------------------------------------------

function party.all_members_in_zone(zone_id)

    if party.is_solo() then
        return true
    end

    local party_data = windower.ffxi.get_party()

    if not party_data then
        return false
    end

    for i = 0, 5 do
        local member = party_data['p'..i]

        if member and member.name then
            if member.zone ~= zone_id then
                return false
            end
        end
    end

    return true
end


--------------------------------------------------
-- WAIT FOR ALL PARTY MEMBERS IN ZONE
--------------------------------------------------

function party.wait_for_all_members_in_zone(zone_id)

    if party.is_solo() then
        return true
    end

    if not party.is_leader() then
        return false
    end

    if party.all_members_in_zone(zone_id) then
        logger.debug('All party members are present.')
        return true
    end

    state.phase = 'waiting_for_party'

    logger.info('Waiting for all party members to arrive in Selbina.')

    while state.running do

        if party.all_members_in_zone(zone_id) then
            logger.info('All party members are present in Selbina.')
            return true
        end

        coroutine.sleep(1)
    end

    return false
end


return party