local keyitems = {}

keyitems.ids = {
    maidens_phantom_gem = 3188,
}


function keyitems.has(id)
    local player_key_items = windower.ffxi.get_key_items()

    if not player_key_items then
        return false
    end

    for _, key_item_id in ipairs(player_key_items) do
        if key_item_id == id then
            return true
        end
    end

    return false
end


function keyitems.has_named(name)
    local id = keyitems.ids[name]

    if not id then
        return false
    end

    return keyitems.has(id)
end


function keyitems.get_merits()

    local player = windower.ffxi.get_player()

    if not player then
        return nil
    end

    return player.merits
end


function keyitems.has_enough_merits(amount)

    local merits = keyitems.get_merits()

    if not merits then
        return false
    end

    return merits >= amount
end


return keyitems