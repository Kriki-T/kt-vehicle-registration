local currentVehicle = nil
local npcPed = nil
local TargetSystem = nil

local function getVehicleData(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        return nil, nil
    end
    local plate = GetVehicleNumberPlateText(veh):gsub('%s+', '')
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    return plate, model
end

function OpenRegistrationUI()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        BridgeC.Notify(Config.Locale['no_vehicle'], 'error')
        return
    end

    currentVehicle = GetVehiclePedIsIn(ped, false)
    local plate = getVehicleData(currentVehicle)
    if not plate then return end

    TriggerServerEvent('vehreg:server:getData', plate)
end

RegisterNetEvent('vehreg:client:receiveData', function(data)
    if not currentVehicle or not DoesEntityExist(currentVehicle) then return end

    local plate, model = getVehicleData(currentVehicle)
    if not plate then return end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', plate = plate, model = model, data = data })
end)

-- ================== DETEKCIJA TARGET SISTEMA ==================

CreateThread(function()
    Wait(1000)
    if GetResourceState('ox_target') == 'started' then
        TargetSystem = 'ox'
    elseif GetResourceState('qb-target') == 'started' then
        TargetSystem = 'qb'
    end

    SpawnNPC()
end)

-- ================== SPAWN NPC + TARGET/BLIP ==================

function SpawnNPC()
    local model = joaat(Config.NPC.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    npcPed = CreatePed(4, model, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.coords.w, false, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    FreezeEntityPosition(npcPed, true)
    TaskStartScenarioInPlace(npcPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    SetModelAsNoLongerNeeded(model)

    if TargetSystem == 'ox' then
        exports.ox_target:addLocalEntity(npcPed, {
            {
                name = 'vehreg_open',
                icon = 'fa-solid fa-id-card',
                label = Config.Locale['target_open_reg'],
                distance = Config.NPC.interactDistance,
                onSelect = function() OpenRegistrationUI() end
            }
        })
    elseif TargetSystem == 'qb' then
        exports['qb-target']:AddTargetEntity(npcPed, {
            options = {
                {
                    type = 'client',
                    event = 'vehreg:client:openViaTarget',
                    icon = 'fa-solid fa-id-card',
                    label = Config.Locale['target_open_reg']
                }
            },
            distance = Config.NPC.interactDistance
        })
    else
        -- FALLBACK: nijedan target resurs nije pronadjen, koristi proximity + E
        CreateThread(function()
            while true do
                local sleep = 500
                local ped = PlayerPedId()
                local dist = #(GetEntityCoords(ped) - GetEntityCoords(npcPed))

                if dist < Config.NPC.interactDistance then
                    sleep = 0
                    local npcCoords = GetEntityCoords(npcPed)
                    DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, '[E] ' .. Config.Locale['target_open_reg'])
                    if IsControlJustReleased(0, Config.FallbackOpenKey) then
                        OpenRegistrationUI()
                    end
                end
                Wait(sleep)
            end
        end)
    end

    if Config.UseBlip then
        local blip = AddBlipForCoord(Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z)
        SetBlipSprite(blip, Config.BlipSprite)
        SetBlipColour(blip, Config.BlipColor)
        SetBlipScale(blip, Config.BlipScale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.BlipLabel)
        EndTextCommandSetBlipName(blip)
    end
end

RegisterNetEvent('vehreg:client:openViaTarget', function()
    OpenRegistrationUI()
end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- ================== NUI CALLBACKS ==================

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('register', function(data, cb)
    TriggerServerEvent('vehreg:server:register', data.plate, data.model)
    cb('ok')
end)

RegisterNUICallback('renew', function(data, cb)
    TriggerServerEvent('vehreg:server:renew', data.plate)
    cb('ok')
end)

RegisterNUICallback('checkPlateAvailability', function(data, cb)
    TriggerServerEvent('vehreg:server:checkPlateAvailability', data.plate)
    cb('ok')
end)

RegisterNUICallback('buyPersonalized', function(data, cb)
    TriggerServerEvent('vehreg:server:buyPersonalized', data.oldPlate, data.plate, data.model)
    cb('ok')
end)

-- ================== SERVER -> CLIENT ==================

RegisterNetEvent('vehreg:client:setPlate', function(newPlate)
    if DoesEntityExist(currentVehicle) then
        SetVehicleNumberPlateText(currentVehicle, newPlate)
    end
end)

RegisterNetEvent('vehreg:client:plateAvailability', function(result)
    SendNUIMessage({ action = 'plateAvailability', result = result })
end)

RegisterNetEvent('vehreg:client:personalizedSuccess', function(newPlate)
    SendNUIMessage({ action = 'personalizedSuccess', plate = newPlate })
end)

RegisterNetEvent('vehreg:client:toast', function(message, type)
    SendNUIMessage({ action = 'toast', message = message, toastType = type })
end)

-- ================== CLEANUP ==================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if npcPed and DoesEntityExist(npcPed) then
        DeleteEntity(npcPed)
    end
end)