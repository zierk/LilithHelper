local state = require('bot/state')
local logger = require('bot/logger')

local entities = {}


-- Determines whether an entity is attackable.
local function is_attackable(mob)

    if not mob then
        return false
    end

    -- TODO:
    -- Refine attackable detection once needed.

    return true
end


-- Finds the nearest loaded entity matching one or more names.
function entities.get_nearest_mob_by_name(names, attackable_only)

    if type(names) == 'string' then
        names = S{names}
    end

    local mobs = windower.ffxi.get_mob_array()

    if not mobs then
        return nil
    end

    local nearest_mob = nil
    local nearest_distance = math.huge

    for _, mob in pairs(mobs) do

        if mob.name and names:contains(mob.name) then

            local valid = true

            if attackable_only and not is_attackable(mob) then
                valid = false
            end

            if valid then

                local distance = math.sqrt(mob.distance)

                if distance < nearest_distance then
                    nearest_mob = mob
                    nearest_distance = distance
                end
            end
        end
    end

    return nearest_mob
end


-- Waits until an entity matching the requested name loads.
function entities.wait_for_mob_by_name(names, attackable_only)

    local mob = entities.get_nearest_mob_by_name(
        names,
        attackable_only
    )

    if not mob then
        logger.debug('Waiting for target to load...')
    end

    while not mob do

        if not state.running then
            return nil
        end

        coroutine.sleep(3)

        mob = entities.get_nearest_mob_by_name(
            names,
            attackable_only
        )
    end

    logger.debug(
        'Target loaded: '..tostring(mob.name)..
        ' | Index: '..tostring(mob.index)
    )

    return mob
end


return entities