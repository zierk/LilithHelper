local zones = {}


zones.northern_sandoria = {
    name = "Northern San d'Oria",
    zone_id = 231,

    homepoints = {
        [2] = {
            index = 113,
        },
    },

    locations = {
        homepoint = {26.998, 84.518},
        ki_npc = {9.917, 96.034},
    },
}


zones.selbina = {
    name = 'Selbina',
    zone_id = 248,

    homepoints = {
        [1] = {
            index = 45,
        },
    },

    routes = {
        hp_to_htmb = {
            {24.845, 34.893},
            {19.851, 53.134},
            {11.471, 68.246},
        },

        htmb_to_hp = {
            {26.903, 67.235},
            {20.309, 48.941},
            {26.050, 32.300},
            {36.225, 33.563},
        },
    },
}


return zones