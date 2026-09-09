Bridge = {}
Framework = nil

CreateThread(function()
    Wait(500)
    if Config.Framework == 'auto' then
        if GetResourceState('qbx_core') == 'started' then
            Framework = 'qbox'
        elseif GetResourceState('qb-core') == 'started' then
            Framework = 'qbcore'
        elseif GetResourceState('es_extended') == 'started' then
            Framework = 'esx'
        else
            print('^1[kt-vehicle-registration] Nijedan podrzan framework nije pronadjen!^0')
        end
    else
        Framework = Config.Framework
    end

    if Framework == 'qbcore' then
        Bridge.Core = exports['qb-core']:GetCoreObject()
    elseif Framework == 'esx' then
        Bridge.Core = exports['es_extended']:getSharedObject()
    end

    print(('^2[kt-vehicle-registration] Framework detektovan: %s^0'):format(Framework))
end)

function Bridge.GetIdentifier(src)
    if Framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.citizenid
    elseif Framework == 'qbcore' then
        local player = Bridge.Core.Functions.GetPlayer(src)
        return player and player.PlayerData.citizenid
    elseif Framework == 'esx' then
        local player = Bridge.Core.GetPlayerFromId(src)
        return player and player.identifier
    end
end

function Bridge.RemoveMoney(src, amount)
    if Framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(src)
        if player.PlayerData.money.cash >= amount then
            player.Functions.RemoveMoney('cash', amount, 'kt-vehicle-registration')
            return true
        end
    elseif Framework == 'qbcore' then
        local player = Bridge.Core.Functions.GetPlayer(src)
        if player.PlayerData.money.cash >= amount then
            player.Functions.RemoveMoney('cash', amount, 'kt-vehicle-registration')
            return true
        end
    elseif Framework == 'esx' then
        local player = Bridge.Core.GetPlayerFromId(src)
        if player.getMoney() >= amount then
            player.removeMoney(amount)
            return true
        end
    end
    return false
end

function Bridge.Notify(src, msg, type)
    if Framework == 'qbox' or Framework == 'qbcore' then
        TriggerClientEvent('QBCore:Notify', src, msg, type or 'primary')
    elseif Framework == 'esx' then
        TriggerClientEvent('esx:showNotification', src, msg)
    end
end