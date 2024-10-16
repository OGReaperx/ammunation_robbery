local lootedShops = {}
local failedAttempts = {}
local cooldowns = {}
local globalCooldowns = {}
local activeLooting = {}
local zoneLockdown = {}  -- Tracks if a zone is in lockdown

local notifyStyle = {
    icon = "fa-solid fa-sack-dollar",
    primaryColor = "#FF425D",
    backgroundIcon = { from = "#FC3955", to = "#861A20" },
    sound = { play = true, type = "notifySound6", volume = 5 }
}


-- Function to start a lockdown for all zones except the one being looted
local function startLockdown(excludeZone)
    for zoneId, _ in pairs(Config.AmmunitionLocations) do
        if zoneId ~= excludeZone then
            zoneLockdown[zoneId] = true
        end
    end
end

-- Function to end lockdown for all zones
local function endLockdown()
    for zoneId, _ in pairs(Config.AmmunitionLocations) do
        zoneLockdown[zoneId] = nil
    end
end

-- Function to check if a zone is in lockdown
local function isZoneInLockdown(locationId)
    return zoneLockdown[locationId] or false
end

RegisterNetEvent('ammunition:policeCall')
AddEventHandler('ammunition:policeCall', function(coords, streetName)
    local source = source  -- Get the player ID who triggered this event

    -- Trigger dispatch notification
    TriggerEvent('cd_dispatch:AddNotification', {
        job_table = {'police', 'sheriff', 'state', 'ambulance'},
        coords = coords,
        title = '10-15 - Ammunition Robbery',
        message = 'A player is robbing an ammunition at ' .. streetName,
        flash = 0,
        unique_id = tostring(source),
        sound = 1,
        blip = {
            sprite = 431,
            scale = 1.2,
            colour = 3,
            flashes = false,
            text = '911 - Ammunition Robbery',
            time = 5,
            radius = 0,
        }
    })
end)

local function countLEOPlayers()
    local totalLEO = 0
    local players = GetPlayers()

    for _, playerId in ipairs(players) do
        local playerData = exports.qbx_core:GetPlayer(tonumber(playerId))
        if playerData and playerData.PlayerData.job then
            local jobType = playerData.PlayerData.job.type
            if jobType == 'leo' then
                totalLEO = totalLEO + 1
            end
        end
    end

    return totalLEO
end

local function resetAttempts(locationId, lootAreaId)
    failedAttempts[locationId .. ":" .. lootAreaId] = nil
    cooldowns[locationId .. ":" .. lootAreaId] = nil
end

local function resetLootedShops(locationId)
    lootedShops[locationId] = nil
    globalCooldowns[locationId] = nil
end

local function checkAllAreasLooted(locationId)
    local ammunitionLocation = Config.AmmunitionLocations[locationId]
    if not ammunitionLocation then
        return false
    end

    for _, lootArea in ipairs(ammunitionLocation.lootAreas) do
        if not lootedShops[locationId] or not lootedShops[locationId][lootArea.id] then
            return false
        end
    end
    return true
end

local function getPlayerXP(citizenid, callback)
    MySQL.scalar('SELECT xp FROM players WHERE citizenid = ?', { citizenid }, function(result)
        callback(result or 0)
    end)
end

local function tryAddXP(source, citizenid, amount)
    getPlayerXP(citizenid, function(currentXP)
        local newXP = currentXP + amount
        MySQL.update('UPDATE players SET xp = ? WHERE citizenid = ?', { newXP, citizenid }, function(success)
            if success then
                TriggerClientEvent('is_ui:Notify', source, 'XP Gained', 'You gained ' .. amount .. ' XP', 5000, notifyStyle)
            end
        end)
    end)
end

local function getLootForXPLevel(xp)
    local lastConfig = Config.XPRewards[1]
    for _, config in ipairs(Config.XPRewards) do
        if xp >= config.xpLevel then
            lastConfig = config
        else
            break
        end
    end
    return lastConfig
end

local function getRareItem(rareChance)
    if math.random(100) <= rareChance then
        local rareItems = Config.RareItems
        if #rareItems > 0 then
            return rareItems[math.random(1, #rareItems)].item
        end
    end
    return nil
end

local function giveItemsToPlayer(source, lootArea, itemCount, rareChance, citizenid)
    local addedItems = {}
    local foundItem = false

    for i = 1, itemCount do
        for _, reward in ipairs(lootArea.rewards) do
            if math.random(100) <= reward.chance then
                local rewardAmount = math.random(reward.min, reward.max)
                exports.ox_inventory:AddItem(source, reward.item, rewardAmount)
                addedItems[reward.item] = true
                foundItem = true
                tryAddXP(source, citizenid, 2)
            end
        end

        local rareItem = getRareItem(rareChance)
        if rareItem then
            exports.ox_inventory:AddItem(source, rareItem, 1)
            tryAddXP(source, citizenid, 2)
            foundItem = true
        end

        Citizen.Wait(75)
    end

    if not foundItem then
        TriggerClientEvent('is_ui:Notify', source, 'Looting', "You didn't find any items.", 5000, notifyStyle)
    end

    activeLooting[source .. ":" .. lootArea.id] = nil
end

local function isHoldingRequiredItem(source, requiredItems)
    local playerPed = GetPlayerPed(source)
    if not playerPed or not source or type(source) ~= "number" then
        print("Error: Invalid source or player ped.")
        return false
    end

    if not requiredItems or #requiredItems == 0 then
        return true
    end

    local hasRequiredItemInInventory = false

    for _, item in ipairs(requiredItems) do
        local itemsFound = exports.ox_inventory:Search(source, 'count', item)
        if itemsFound and itemsFound > 0 then
            hasRequiredItemInInventory = true
            local currentWeapon = GetSelectedPedWeapon(playerPed)
            if currentWeapon == GetHashKey(item) then
                return true
            end
        end
    end

    if hasRequiredItemInInventory then
        TriggerClientEvent('is_ui:Notify', source, 'Looting', 'You must be holding the required item to loot this area.', 5000, notifyStyle)
    else
        TriggerClientEvent('is_ui:Notify', source, 'Hang on', 'You lack the required item to loot this area.', 5000, notifyStyle)
    end
    return false
end

RegisterNetEvent('ammunition:checkLEO')
AddEventHandler('ammunition:checkLEO', function(locationId, lootAreaId)
    local source = source

    if IsPlayerRestricted(source) then
        TriggerClientEvent('is_ui:Notify', source, 'Wait', 'You\'re a law enforcer, wtf are you doing', 5000, notifyStyle)
        return
    end

    if isZoneInLockdown(locationId) then
        TriggerClientEvent('is_ui:Notify', source, 'Lockdown', 'This zone is in lockdown due to another robbery!', 5000, notifyStyle)
        return
    end

    if activeLooting[source .. ":" .. locationId .. ":" .. lootAreaId] then
        TriggerClientEvent('is_ui:Notify', source, 'Already Looted', 'You have already looted this area.', 5000, notifyStyle)
        return
    end

    activeLooting[source .. ":" .. locationId .. ":" .. lootAreaId] = true

    if globalCooldowns[locationId] then
        activeLooting[source .. ":" .. locationId .. ":" .. lootAreaId] = nil
        return
    end

    if cooldowns[locationId .. ":" .. lootAreaId] then
        TriggerClientEvent('is_ui:Notify', source, 'Cooldown', 'You greedy fuck, try again later', 5000, notifyStyle)
        activeLooting[source .. ":" .. locationId .. ":" .. lootAreaId] = nil
        return
    end

    if not isHoldingRequiredItem(source, Config.AmmunitionLocations[locationId].lootAreas[lootAreaId].requiredItem) then
        activeLooting[source .. ":" .. locationId .. ":" .. lootAreaId] = nil
        return
    end

    if countLEOPlayers() < Config.MinLeo then
        TriggerClientEvent('is_ui:Notify', source, 'Not Enough LEO', 'Not enough LEO on duty.', 5000, notifyStyle)
        activeLooting[source .. ":" .. locationId .. ":" .. lootAreaId] = nil
        return
    end

    startLockdown(locationId)
    
    TriggerClientEvent('ammunition:startSkillCheck', source, locationId, lootAreaId)
end)

RegisterNetEvent('ammunition:skillCheckResult')
AddEventHandler('ammunition:skillCheckResult', function(locationId, lootAreaId, success)
    local source = source

    if not success then
        failedAttempts[locationId .. ":" .. lootAreaId] = (failedAttempts[locationId .. ":" .. lootAreaId] or 0) + 1

        if failedAttempts[locationId .. ":" .. lootAreaId] >= Config.MaxFailedAttempts then
            cooldowns[locationId .. ":" .. lootAreaId] = true
            SetTimeout(Config.LootCooldown * 1000, function()
                resetAttempts(locationId, lootAreaId)
            end)
        else
            TriggerClientEvent('is_ui:Notify', source, 'FYI', 'You suck.', 5000, notifyStyle)
        end

        activeLooting[source .. ":" .. locationId .. ":" .. lootAreaId] = nil
        return
    end

    TriggerClientEvent('ammunition:playLootingAnimation', source, locationId, lootAreaId)
end)

RegisterNetEvent('ammunition:finishLooting')
AddEventHandler('ammunition:finishLooting', function(locationId, lootAreaId)
    local source = source
    local player = exports.qbx_core:GetPlayer(source)

    getPlayerXP(player.PlayerData.citizenid, function(xp)
        local lootConfig = getLootForXPLevel(xp)
        local itemCount = math.random(Config.RandomItemCount.min, Config.RandomItemCount.max)
        local rareChance = lootConfig.rareChance / 100

        giveItemsToPlayer(source, Config.AmmunitionLocations[locationId].lootAreas[lootAreaId], itemCount, rareChance, player.PlayerData.citizenid)

        lootedShops[locationId] = lootedShops[locationId] or {}
        lootedShops[locationId][lootAreaId] = true
        
        cooldowns[locationId .. ":" .. lootAreaId] = true

        SetTimeout(Config.AreaCooldown * 1000, function()
            resetAttempts(locationId, lootAreaId)
        end)

        if checkAllAreasLooted(locationId) then
            globalCooldowns = {}

            for zoneId, _ in pairs(Config.AmmunitionLocations) do
                globalCooldowns[zoneId] = true

                SetTimeout(Config.GlobalCooldown * 1000, function()
                    globalCooldowns[zoneId] = nil
                end)
            end

            endLockdown()
        end

        activeLooting[source .. ":" .. locationId .. ":" .. lootAreaId] = nil
    end)
end)
