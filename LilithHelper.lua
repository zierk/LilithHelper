_addon.name = 'LilithHelper' 
_addon.author = 'Zierk' 
_addon.version = '1.0'
_addon.commands = {'lilithhelper', 'lh'}

local res = require('resources') 

local zone_table = { 
    [0] = { zone = "Port San d'Oria", index = 87,  waypoints = { {84.580, -141.111} } }, 
    [1] = { zone = "Port Bastok",     index = 73,  waypoints = { {50.108, -237.790}, {52.120, -248.826} } }, 
    [2] = { zone = "Port Windurst",   index = 142, waypoints = { {195.306, 224.108}, {197.933, 234.513}, {197.700, 265.516} } }, 
}

local state = { 
    player_loaded = false, 
    nation_id = nil, 
    nation_name = "Unknown", 
    destination_zone = "Port Jeuno", 
    target_hp_index = nil, 
    waypoints = {}, 
    movement_active = false, 
    debug = true 
}

local function log_info(msg) 
    local prefix = "\31\200[\31\05LilithHelper\31\200]\31\207 " 
    windower.add_to_chat(1, prefix .. tostring(msg)) 
end 

local function log_error(msg) 
    local prefix = "\31\200[\31\05LilithHelper\31\200] \31\123ERROR:\31\207 " 
    windower.add_to_chat(1, prefix .. tostring(msg)) 
end 

local function log_debug(msg) 
    if state.debug then 
        local prefix = "\31\200[\31\05LilithHelper\31\200] \31\200DEBUG:\31\207 " 
        windower.add_to_chat(1, prefix .. tostring(msg)) 
    end 
end 