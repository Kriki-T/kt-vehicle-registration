local function generatePlate()
    local plate = ''
    for i = 1, #Config.PlateFormat do
        local c = Config.PlateFormat:sub(i,i)
        if c == 'A' then
            plate = plate .. string.char(math.random(65,90))
        elseif c == '0' then
            plate = plate .. tostring(math.random(0,9))
        else
            plate = plate .. c
        end
    end
    return plate
end

local function uniquePlate()
    local plate
    repeat
        plate = generatePlate()
        local exists = MySQL.scalar.await('SELECT 1 FROM vehicle_registrations WHERE plate = ?', {plate})
    until not exists
    return plate
end

local function isValidCustomPlate(plate)
    if not plate then return false end
    plate = plate:gsub('%s+', ''):upper()
    if #plate < Config.PersonalizedPlateMinLength or #plate > Config.PersonalizedPlateMaxLength then
        return false, plate
    end
    if not plate:match('^[A-Z0-9]+$') then
        return false, plate
    end
    return true, plate
end

-- ================== OSNOVNI PODACI ==================

RegisterNetEvent('vehreg:server:getData', function(plate)
    local src = source
    local data = MySQL.single.await('SELECT * FROM vehicle_registrations WHERE plate = ?', {plate})
    TriggerClientEvent('vehreg:client:receiveData', src, data)
end)

-- ================== REGISTRACIJA ==================

RegisterNetEvent('vehreg:server:register', function(oldPlate, model)
    local src = source
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then return end

    local existing = MySQL.single.await('SELECT * FROM vehicle_registrations WHERE plate = ?', {oldPlate})
    if existing and existing.status ~= 'none' then
        Bridge.Notify(src, 'Vozilo je vec registrovano', 'error')
        return
    end

    if not Bridge.RemoveMoney(src, Config.RegisterPrice) then
        Bridge.Notify(src, Config.Locale['not_enough_money'], 'error')
        return
    end

    local newPlate = uniquePlate()
    local expires = os.date('%Y-%m-%d %H:%M:%S', os.time() + (Config.RegistrationDays * 86400))

    MySQL.insert.await('INSERT INTO vehicle_registrations (plate, owner_identifier, vehicle_model, registered_at, expires_at, status) VALUES (?,?,?,NOW(),?,?)',
        {newPlate, identifier, model, expires, 'active'})

    TriggerClientEvent('vehreg:client:setPlate', src, newPlate)
    Bridge.Notify(src, Config.Locale['success_register'], 'success')
end)

-- ================== OBNOVA ==================

RegisterNetEvent('vehreg:server:renew', function(plate)
    local src = source
    local identifier = Bridge.GetIdentifier(src)
    local existing = MySQL.single.await('SELECT * FROM vehicle_registrations WHERE plate = ?', {plate})

    if not existing then
        Bridge.Notify(src, 'Vozilo nije pronadjeno', 'error')
        return
    end

    if not Bridge.RemoveMoney(src, Config.RenewPrice) then
        Bridge.Notify(src, Config.Locale['not_enough_money'], 'error')
        return
    end

    local base = os.time()
    local expiresTs = 0
    if existing.expires_at then
        expiresTs = os.time({
            year = tonumber(existing.expires_at:sub(1,4)),
            month = tonumber(existing.expires_at:sub(6,7)),
            day = tonumber(existing.expires_at:sub(9,10)),
            hour = 0, min = 0, sec = 0
        })
    end
    local startFrom = math.max(base, expiresTs)
    local newExpires = os.date('%Y-%m-%d %H:%M:%S', startFrom + (Config.RegistrationDays * 86400))

    MySQL.update.await('UPDATE vehicle_registrations SET expires_at = ?, status = ? WHERE plate = ?', {newExpires, 'active', plate})
    Bridge.Notify(src, Config.Locale['success_renew'], 'success')
end)

-- ================== PERSONALIZOVANE TABLICE ==================

RegisterNetEvent('vehreg:server:checkPlateAvailability', function(customPlate)
    local src = source
    local valid, plate = isValidCustomPlate(customPlate)

    if not valid then
        TriggerClientEvent('vehreg:client:plateAvailability', src, { available = false, reason = 'invalid' })
        return
    end

    local exists = MySQL.scalar.await('SELECT 1 FROM vehicle_registrations WHERE plate = ?', {plate})
    TriggerClientEvent('vehreg:client:plateAvailability', src, {
        available = not exists,
        plate = plate,
        reason = exists and 'taken' or nil
    })
end)

RegisterNetEvent('vehreg:server:buyPersonalized', function(oldPlate, customPlate, model)
    local src = source
    local identifier = Bridge.GetIdentifier(src)
    if not identifier then return end

    local valid, plate = isValidCustomPlate(customPlate)
    if not valid then
        Bridge.Notify(src, 'Neispravan format tablice', 'error')
        return
    end

    local exists = MySQL.scalar.await('SELECT 1 FROM vehicle_registrations WHERE plate = ?', {plate})
    if exists then
        Bridge.Notify(src, 'Tablica je vec zauzeta', 'error')
        TriggerClientEvent('vehreg:client:plateAvailability', src, { available = false, reason = 'taken' })
        return
    end

    if not Bridge.RemoveMoney(src, Config.PersonalizedPlatePrice) then
        Bridge.Notify(src, Config.Locale['not_enough_money'], 'error')
        return
    end

    local expires = os.date('%Y-%m-%d %H:%M:%S', os.time() + (Config.RegistrationDays * 86400))

    MySQL.query.await('DELETE FROM vehicle_registrations WHERE plate = ?', {oldPlate})

    MySQL.insert.await('INSERT INTO vehicle_registrations (plate, owner_identifier, vehicle_model, registered_at, expires_at, personalized, status) VALUES (?,?,?,NOW(),?,1,?)',
        {plate, identifier, model, expires, 'active'})

    TriggerClientEvent('vehreg:client:setPlate', src, plate)
    TriggerClientEvent('vehreg:client:personalizedSuccess', src, plate)
    Bridge.Notify(src, 'Personalizovana tablica je uspesno kupljena!', 'success')
end)

-- ================== EXPORT ZA POLICIJU / MEHANICARE ==================

exports('CheckPlate', function(plate)
    return MySQL.single.await('SELECT * FROM vehicle_registrations WHERE plate = ?', {plate})
end)