local TargetSystem = nil
local lastFineCheck = {} -- [plate] = timestamp (client-side throttle)

local function getVehicleInfo(veh)
    if not veh or not DoesEntityExist(veh) then return nil, nil end
    local plate = GetVehicleNumberPlateText(veh):gsub('%s+', '')
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    return plate, model
end

local function checkVehicle(veh)
    local plate, model = getVehicleInfo(veh)
    if not plate then return end
    TriggerServerEvent('vehreg:server:checkVehicle', plate, model)
end

RegisterNetEvent('vehreg:client:checkResult', function(plate, model, data)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openLookup', plate = plate, model = model, data = data })
end)

RegisterNUICallback('closeLookup', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ================== DETEKCIJA TARGET SISTEMA + REGISTRACIJA GLOBAL VEHICLE TARGET-a ==================

CreateThread(function()
    Wait(1200)
    if GetResourceState('ox_target') == 'started' then
        TargetSystem = 'ox'
        exports.ox_target:addGlobalVehicle({
            {
                name = 'vehreg_check',
                icon = 'fa-solid fa-magnifying-glass',
                label = Config.Locale['target_check_reg'],
                onSelect = function(data) checkVehicle(data.entity) end
            }
        })
    elseif GetResourceState('qb-target') == 'started' then
        TargetSystem = 'qb'
        exports['qb-target']:AddGlobalVehicle({
            options = {
                {
                    type = 'client',
                    event = 'vehreg:client:checkViaTarget',
                    icon = 'fa-solid fa-magnifying-glass',
                    label = Config.Locale['target_check_reg']
                }
            },
            distance = 3.0
        })
    else
        -- FALLBACK: nijedan target resurs, koristi raycast + G
        StartFallbackCheckLoop()
    end
end)

RegisterNetEvent('vehreg:client:checkViaTarget', function(entity)
    checkVehicle(entity)
end)

-- ================== FALLBACK (samo ako nema target resursa) ==================

function StartFallbackCheckLoop()
    local function RotationToDirection(rotation)
        local rad = {
            x = (math.pi / 180) * rotation.x,
            y = (math.pi / 180) * rotation.y,
            z = (math.pi / 180) * rotation.z
        }
        return {
            x = -math.sin(rad.z) * math.abs(math.cos(rad.x)),
            y = math.cos(rad.z) * math.abs(math.cos(rad.x)),
            z = math.sin(rad.x)
        }
    end

    local function getAimedVehicle()
        local camCoord = GetGameplayCamCoord()
        local dir = RotationToDirection(GetGameplayCamRot(0))
        local dest = {
            x = camCoord.x + dir.x * Config.FallbackCheckDistance,
            y = camCoord.y + dir.y * Config.FallbackCheckDistance,
            z = camCoord.z + dir.z * Config.FallbackCheckDistance
        }
        local ray = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, dest.x, dest.y, dest.z, 10, PlayerPedId(), 0)
        local _, hit, _, _, entity = GetShapeTestResult(ray)
        if hit == 1 and DoesEntityExist(entity) and IsEntityAVehicle(entity) then
            return entity
        end
        return nil
    end

    RegisterCommand('_vehreg_fallback_check', function()
        local veh = getAimedVehicle()
        if not veh then
            BridgeC.Notify('Niste usmereni ka vozilu', 'error')
            return
        end
        checkVehicle(veh)
    end, false)

    RegisterKeyMapping('_vehreg_fallback_check', Config.Locale['target_check_reg'], 'keyboard', Config.FallbackCheckKey)
end

-- ================== SISTEM KAZNE ZA ISTEKLU REGISTRACIJU ==================

CreateThread(function()
    while true do
        Wait(Config.FineCheckInterval)

        if Config.FineOnExpired then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if GetPedInVehicleSeat(veh, -1) == ped and DoesEntityExist(veh) then
                    local plate = GetVehicleNumberPlateText(veh):gsub('%s+', '')
                    local now = GetGameTimer()

                    if not lastFineCheck[plate] or (now - lastFineCheck[plate]) > Config.FineCooldown then
                        lastFineCheck[plate] = now
                        TriggerServerEvent('vehreg:server:fineCheck', plate)
                    end
                end
            end
        end
    end
end)