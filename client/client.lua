local isLooting = false

-- Function to call police dispatch from the client side
function PoliceCallClient()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)

    if streetName == "" then
        streetName = "an unknown street"
    end

    -- Send the street name and player coordinates to the server
    TriggerServerEvent('ammunition:policeCall', coords, streetName)
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

    lib.notify({title = 'Success', description = 'You are looting the area!', type = 'inform'})
    TriggerServerEvent('ammunition:skillCheckResult', locationId, lootAreaId, true)
end)

RegisterNetEvent('ammunition:playLootingAnimation', function(locationId, lootAreaId)
    if isLooting then return end
    isLooting = true

    local playerPed = PlayerPedId()
    local lootArea = Config.AmmunitionLocations[locationId].lootAreas[lootAreaId]
    local animation = lootArea.animation or { dict = "anim@scripted@player@mission@tun_table_grab@cash@", name = "grab", duration = 5000 }

    RequestAnimDict(animation.dict)
    while not HasAnimDictLoaded(animation.dict) do Wait(10) end

    TaskPlayAnim(playerPed, animation.dict, animation.name, 8.0, -8.0, animation.duration or -1, animation.flag or 1, 0, false, false, false)

    if Config.ProgressBarType == 'circle' then
        lib.progressCircle({
            duration = animation.duration or 5000, 
            position = 'top-right', label = 'Looting...', 
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

    -- Call the police after looting is finished
    PoliceCallClient()
end)
