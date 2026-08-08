local logger = require('bot/logger')
local travel = require('bot/travel')
local entities = require('bot/entities')

local interaction = {}


function interaction.wait_for_homepoint(zone_data, hp_number)

    local hp_data = zone_data.homepoints[hp_number]

    if not hp_data then
        logger.error(
            'No Home Point #'..tostring(hp_number)..
            ' configured for '..tostring(zone_data.name)..'.'
        )

        return nil
    end

    logger.debug(
        'Waiting for '..zone_data.name..
        ' Home Point #'..hp_number..'...'
    )

    -- First wait until zoning has completed.
    while not travel.is_in_zone(zone_data.zone_id) do
        coroutine.sleep(1)
    end

    logger.debug(
        'Zone confirmed: '..zone_data.name..'.'
    )

    -- Then wait for the specific Home Point entity to load.
    local hp = entities.wait_for_mob_by_name(
        'Home Point #'..hp_number,
        false
    )

    if not hp then
        return nil
    end

    -- Make sure it is the expected HP index.
    if hp.index ~= hp_data.index then
        logger.error(
            'Unexpected Home Point index. Expected '..
            tostring(hp_data.index)..
            ', found '..tostring(hp.index)..'.'
        )

        return nil
    end

    logger.debug(
        'Home Point confirmed: '..hp.name..
        ' | Index: '..hp.index
    )

    return hp
end


return interaction