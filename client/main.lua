local currentVehicle = nil
local nuiOpen = false

local function getVehicleData(veh)
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
    local plate, model = getVehicleData(currentVehicle)

    TriggerServerEvent('vehreg:server:getData', plate)
end

RegisterNetEvent('vehreg:client:receiveData', function(data)
    local plate, model = getVehicleData(currentVehicle)
    nuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        plate = plate,
        model = model,
        data = data
    })
end)

-- ================== KOMANDA / KEYBIND ==================

RegisterCommand(Config.Command, function()
    openRegistrationUI()
end, false)

RegisterKeyMapping(Config.Command, 'Otvori registraciju vozila', 'keyboard', 'F6')

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

-- ================== PERIODICNA PROVERA VOZILA (kazne) ==================

CreateThread(function()
    while true do
        Wait(Config.CheckIntervalMs)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped, false), -1) == ped then
            local veh = GetVehiclePedIsIn(ped, false)
            local plate = GetVehicleNumberPlateText(veh):gsub('%s+', '')
            TriggerServerEvent('vehreg:server:getData', plate)
        end
    end
end)