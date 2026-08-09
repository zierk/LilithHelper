local state = {
    running = false,
    debug = false,

    phase = 'idle',

    destination = nil,

    movement_active = false,
    waypoint_index = 1,
}

return state