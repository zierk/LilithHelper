local logger = require('bot/logger')

local ipc = {}

local discovery_token = nil
local participants = {}

local START_STAGGER = 0.35
local DISCOVERY_TIME = 0.50


--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function get_player()
    return windower.ffxi.get_player()
end


local function reset_discovery()
    discovery_token = nil
    participants = {}
end


local function add_participant(id, name)
    id = tonumber(id)

    if not id or not name then
        return
    end

    participants[id] = name
end


local function get_sorted_participants()

    local list = {}

    for id, name in pairs(participants) do
        list[#list + 1] = {
            id = id,
            name = name,
        }
    end

    table.sort(list, function(a, b)
        return a.id < b.id
    end)

    return list
end


--------------------------------------------------
-- @ALL START
--------------------------------------------------

function ipc.start_all(local_start)

    local player = get_player()

    if not player then
        logger.error('Unable to begin IPC discovery.')
        return
    end

    reset_discovery()

    discovery_token = tostring(os.time())..'-'..tostring(player.id)..'-'..tostring(math.floor(os.clock() * 1000))

    -- Always include the initiating client ourselves.
    add_participant(player.id, player.name)

    logger.debug('Discovering LilithHelper clients...')

    windower.send_ipc_message('LH_DISCOVER '..discovery_token)

    coroutine.schedule(function()

        coroutine.sleep(DISCOVERY_TIME)

        local list = get_sorted_participants()
        local player = get_player()

        logger.info('Found '..#list..' LilithHelper client(s).')

        for position, member in ipairs(list) do

            local delay = (position - 1) * START_STAGGER

            if member.id == player.id then

                --------------------------------------------------
                -- START INITIATING CLIENT LOCALLY
                --------------------------------------------------

                coroutine.schedule(function()

                    coroutine.sleep(delay)

                    if local_start then
                        local_start()
                    end

                end, 0.1)

            else

                --------------------------------------------------
                -- START OTHER CLIENTS THROUGH IPC
                --------------------------------------------------

                windower.send_ipc_message(
                    'LH_START '..discovery_token..' '..member.id..' '..string.format('%.2f', delay)
                )

            end
        end

        reset_discovery()

    end, 0.1)

end

--------------------------------------------------
-- @ALL STOP
--------------------------------------------------

function ipc.stop_all(local_stop)

    if local_stop then
        local_stop()
    end

    windower.send_ipc_message('LH_STOP')
end


--------------------------------------------------
-- @ALL STATUS
--------------------------------------------------

function ipc.status_all(local_status)

    if local_status then
        local_status()
    end

    windower.send_ipc_message('LH_STATUS')
end


--------------------------------------------------
-- HANDLE INCOMING IPC
--------------------------------------------------

function ipc.handle_message(message)

    --------------------------------------------------
    -- DISCOVERY REQUEST
    --------------------------------------------------

    local token = message:match('^LH_DISCOVER%s+(%S+)$')

    if token then

        local player = get_player()

        if player then
            windower.send_ipc_message('LH_PRESENT '..token..' '..player.id..' '..player.name)
        end

        return
    end


    --------------------------------------------------
    -- DISCOVERY RESPONSE
    --------------------------------------------------

    local present_token, player_id, player_name = message:match('^LH_PRESENT%s+(%S+)%s+(%d+)%s+(.+)$')

    if present_token then

        if present_token == discovery_token then
            add_participant(player_id, player_name)
        end

        return
    end


    --------------------------------------------------
    -- STAGGERED START
    --------------------------------------------------

    local start_token, target_id, delay = message:match('^LH_START%s+(%S+)%s+(%d+)%s+([%d%.]+)$')

    if start_token then

        local player = get_player()

        if not player then
            return
        end

        if tonumber(target_id) ~= player.id then
            return
        end

        return 'start', tonumber(delay) or 0
    end


    --------------------------------------------------
    -- IMMEDIATE STOP
    --------------------------------------------------

    if message == 'LH_STOP' then
        return 'stop'
    end


    --------------------------------------------------
    -- IMMEDIATE STATUS
    --------------------------------------------------

    if message == 'LH_STATUS' then
        return 'status'
    end
end


return ipc