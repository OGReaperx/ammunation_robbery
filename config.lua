Config = {}

-- Ammuniation Locations
Config.AmmunitionLocations = {
    {
        id = 1,
        coords = vec3(19.55, -1109.99, 29.8),
        lootAreas = {
            { 
                id = 1, 
                coords = vec3(16.65, -1108.3, 30.3),
                rewards = { 
                    { item = "ammo-9", min = 1, max = 20, chance = 75 },  
                    { item = "WEAPON_PISTOL", min = 1, max = 1, chance = 45 }
                },
                requiredItem = {
                    "WEAPON_PISTOL", 
                    "WEAPON_BAT",
                },
            },
            { 
                id = 2, 
                coords = vec3(13.85, -1107.7, 30.4),
                rewards = { 
                    { item = "WEAPON_KNIFE", min = 1, max = 1, chance = 60 },  
                    { item = "WEAPON_BAT", min = 1, max = 1, chance = 85 }
                },
                requiredItem = nil,
            },
        },
    },
    {
        id = 2,
        coords = vec3(-662.051, -937.067, 21.829),
        lootAreas = {
            { 
                id = 1, 
                coords = vec3(-660.0, -937.55, 22.4),
                rewards = { 
                    { item = "ammo-9", min = 1, max = 20, chance = 75 },  
                    { item = "WEAPON_PISTOL", min = 1, max = 1, chance = 45 }
                },
                requiredItem = {
                    "WEAPON_PISTOL", 
                    "WEAPON_BAT",
                },
            },
            { 
                id = 2, 
                coords = vec3(-665.25, -929.35, 21.35), 
                rewards = { 
                    { item = "WEAPON_KNIFE", min = 1, max = 1, chance = 60 },  
                    { item = "WEAPON_BAT", min = 1, max = 1, chance = 85 }
                },
                requiredItem = nil, 
            },
        },
    },
}


-- ox_lib progress
Config.ProgressBarType = 'is_ui' -- 'is_ui' or 'circle'

-- Skill check
Config.SkillCheck = {
    difficulty = {'easy', 'medium', {areaSize = 35, speedMultiplier = 1}, 'easy'},  
    keys = {'w', 'a', 's', 'd'}
}

-- XP based loot chances and level requirements
Config.XPRewards = {
    { xpLevel = 1, rareChance = 5, },
    { xpLevel = 5, rareChance = 10, },
    { xpLevel = 10, rareChance = 15, },
    { xpLevel = 20, rareChance = 20, },
    { xpLevel = 35, rareChance = 25, },
}

-- Rare items
Config.RareItems = {
    { item = "WEAPON_RIFLE", chance = 5 },
    { item = "ammo-rifle", chance = 2 }
}

-- Random item amounts
Config.RandomItemCount = {
    min = 1,
    max = 2
}

-- Cooldowns
Config.LootCooldown = 600
Config.GlobalCooldown = 1800
Config.AreaCooldown = 900

-- Restricted jobs
Config.RestrictedJobs = {
    'police',
    'sheriff',
    'state',
    'ambulance'
}

-- Min LEO check
Config.MinLeo = 0

Config.MaxFailedAttempts = 4

Config.EnableDispatch = true
