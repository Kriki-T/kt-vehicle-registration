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
    RegisterNetEvent('vehreg:client:receiveData')
    AddEventHandler('vehreg:client:receiveData', function(data)
        nuiOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            plate = plate,
            model = model,
            data = data
        })
    end)
end

RegisterCommand(Config.Command, function()
    openRegistrationUI()
end, false)

RegisterKeyMapping(Config.Command, 'Otvori registraciju vozila', 'keyboard', 'F6')

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    nuiOpen = false
    cb('ok')
end)

RegisterNUICallback('register', function(data, cb)
    local plate = getVehicleData(currentVehicle)
    TriggerServerEvent('vehreg:server:register', data.plate, data.model)
    cb('ok')
end)

RegisterNUICallback('renew', function(data, cb)
    TriggerServerEvent('vehreg:server:renew', data.plate)
    cb('ok')
end)

RegisterNetEvent('vehreg:client:setPlate', function(newPlate)
    if DoesEntityExist(currentVehicle) then
        SetVehicleNumberPlateText(currentVehicle, newPlate)
    end
end)

-- Periodicna provera trenutnog vozila (kazna za isteklu registraciju)
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