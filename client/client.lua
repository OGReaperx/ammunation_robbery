local isLooting = false

function PoliceCallClient()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)


    if streetName == "" then
        streetName = "an unknown street"
    end

    local vehicle = GetVehiclePedIsIn(playerPed, false)

    local vehicleData = nil
    if vehicle and vehicle ~= 0 then
        vehicleData = {
            name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
            plate = GetVehicleNumberPlateText(vehicle),
            color = GetVehicleColours(vehicle),
            class = GetVehicleClass(vehicle),
            doors = GetVehicleDoorCount(vehicle)
        }
    end

    local dispatchData = {
        message = 'Ammunition Robbery',
        codeName = 'ammunitionRobbery',
        code = '10-15',
        icon = 'fas fa-store',
        priority = 3,
        coords = coords,
        street = streetName,
        heading = GetEntityHeading(playerPed),
        vehicle = vehicleData and vehicleData.name or nil,
        plate = vehicleData and vehicleData.plate or nil,
        color = vehicleData and vehicleData.color or nil,
        class = vehicleData and vehicleData.class or nil,
        doors = vehicleData and vehicleData.doors or nil,
        jobs = { 'police', 'bcso' }
    }

    if Config.Dispatch == 'ps' then
        TriggerServerEvent('ps-dispatch:server:notify', dispatchData)
    elseif Config.Dispatch == 'cd' then
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = {'police', 'bcso', }, -- add more here
            coords = coords,
            title = '10-15 - Ammunition Robbery',
            message = 'Aummunation Robbery in progress at ' .. streetName,
            flash = 0,
            unique_id = tostring(playerPed),
            sound = 1,
            blip = {
                sprite = 431,
                scale = 1.2,
                colour = 3,
                falshes = false,
                text = '911 - Aummunation Robbery',
                time = 5,
                radius = 0,
            }
        })
    end
end



CreateThread(function()
    for _, location in ipairs(Config.AmmunitionLocations) do
        for _, area in ipairs(location.lootAreas) do
            exports.ox_target:addBoxZone({
                coords = area.coords,
                size = vec3(1, 1, 1),
                rotation = 0,
                options = {
                    {
                        name = 'loot_ammo' .. area.id,
                        event = 'ammunition:beginLooting',
                        icon = 'fa-solid fa-box',
                        label = 'Loot Area',
                        locationId = location.id,
                        lootAreaId = area.id
                    }
                },
                distance = 2.0
            })

            Citizen.Wait(50)
        end
    end
end)

RegisterNetEvent('ammunition:beginLooting', function(data)
    TriggerServerEvent('ammunition:checkLEO', data.locationId, data.lootAreaId)
end)

RegisterNetEvent('ammunition:startSkillCheck', function(locationId, lootAreaId)
    local success = lib.skillCheck(Config.SkillCheck.difficulty, Config.SkillCheck.keys)

    if not success then
        TriggerServerEvent('ammunition:skillCheckResult', locationId, lootAreaId, false)
        return
    end

    --lib.notify({title = 'Success', description = 'You are looting the area!', type = 'inform'})
    exports["is_ui"]:Notify("Good Shit", "You are <span>looting the area!</span>", 5000, "success", "fa-solid fa-box")
    TriggerServerEvent('ammunition:skillCheckResult', locationId, lootAreaId, true)
    PoliceCallClient()
end)

RegisterNetEvent('ammunition:playLootingAnimation', function(locationId, lootAreaId)
    if isLooting then return end
    isLooting = true

    local playerPed = PlayerPedId()
    local lootArea = Config.AmmunitionLocations[locationId].lootAreas[lootAreaId]
    local animation = lootArea.animation or { dict = "anim@scripted@player@mission@tun_table_grab@cash@", name = "grab", duration = 15000 }

    RequestAnimDict(animation.dict)
    while not HasAnimDictLoaded(animation.dict) do Wait(10) end

    TaskPlayAnim(playerPed, animation.dict, animation.name, 8.0, -8.0, animation.duration or -1, animation.flag or 1, 0, false, false, false)

    if Config.ProgressBarType == 'is_ui' then
        exports["is_ui"]:ProgressBar({
            title = "Looting...",
            icon = 'fa-solid fa-box',
            duration = animation.duration or 15000,
            useWhileDead = false,
            canCancel = false,
            animation = {
                dict = animation.dict,
                name = animation.name,
            },
        })
    elseif Config.ProgressBarType == 'circle' then
        lib.progressCircle({
            duration = animation.duration or 5000, 
            position = 'top-right', 
            label = 'Looting...', 
            useWhileDead = false, 
            canCancel = false
        })
    else
        lib.progressBar({
            duration = animation.duration or 5000, 
            label = 'Looting...', 
            useWhileDead = false, 
            canCancel = false
        })
    end

    ClearPedTasksImmediately(playerPed)
    isLooting = false
    TriggerServerEvent('ammunition:finishLooting', locationId, lootAreaId)


    PoliceCallClient()
end)
