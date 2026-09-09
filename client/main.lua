local currentVehicle = nil
local nuiOpen = false
local npcPed = nil

local function getVehicleData(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        return nil, nil
    end
    local plate = GetVehicleNumberPlateText(veh):gsub('%s+', '')
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    return plate, model
end

local function openRegistrationUI()
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

    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        plate = plate,
        model = model,
        data = data
    })
end)

-- ================== SPAWN NPC-a ==================

CreateThread(function()
    local model = joaat(Config.NPC.model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end

    npcPed = CreatePed(4, model, Config.NPC.coords.x, Config.NPC.coords.y, Config.NPC.coords.z - 1.0, Config.NPC.coords.w, false, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    FreezeEntityPosition(npcPed, true)
    TaskStartScenarioInPlace(npcPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)

    SetModelAsNoLongerNeeded(model)
end)

-- ================== INTERAKCIJA SA NPC-em (E taster) ==================

CreateThread(function()
    while true do
        Wait(0)
        local sleep = 500
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)

        if npcPed and DoesEntityExist(npcPed) then
            local npcCoords = GetEntityCoords(npcPed)
            local dist = #(pedCoords - npcCoords)

            if dist < Config.NPC.interactDistance then
                sleep = 0
                DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z + 1.0, '[E] Registracija vozila')

                if IsControlJustReleased(0, 38) then -- E taster
                    openRegistrationUI()
                end
            end
        end

        Wait(sleep)
    end
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

-- ================== FAILSAFE KOMANDA (samo za zaglavljeni UI) ==================

RegisterCommand('fixui', function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'forceClose' })
    nuiOpen = false
    BridgeC.Notify('UI je prinudno zatvoren', 'primary')
end, false)

-- ================== NUI CALLBACKS ==================

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    nuiOpen = false
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

-- ================== SERVER -> CLIENT EVENTI ==================

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

-- ================== PERIODICNA PROVERA VOZILA (kazne, tiho) ==================

CreateThread(function()
    while true do
        Wait(Config.CheckIntervalMs)
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped and DoesEntityExist(veh) then
                local plate = getVehicleData(veh)
                -- tiha provera, ne otvara UI
            end
        end
    end
end)

-- ================== CLEANUP ==================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if npcPed and DoesEntityExist(npcPed) then
        DeleteEntity(npcPed)
    end
end)