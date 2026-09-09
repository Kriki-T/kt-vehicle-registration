BridgeC = {}
Framework = nil

CreateThread(function()
    Wait(500)
    if GetResourceState('qbx_core') == 'started' then
        Framework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then
        Framework = 'qbcore'
        BridgeC.Core = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
        BridgeC.Core = exports['es_extended']:getSharedObject()
    end
end)

function BridgeC.Notify(msg, type)
    if Framework == 'qbox' or Framework == 'qbcore' then
        TriggerEvent('QBCore:Notify', msg, type or 'primary')
    elseif Framework == 'esx' then
        BridgeC.Core.ShowNotification(msg)
    end
end