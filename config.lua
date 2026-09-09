Config = {}

-- 'auto' detektuje qbx_core / qb-core / es_extended automatski
Config.Framework = 'auto'

Config.Command = 'registracija'        -- /registracija
Config.OpenKey = 38                     -- E taster (ako ne koristis target)
Config.UseTarget = true                -- true ako koristis ox_target/qb-target

Config.RegistrationDays = 30            -- koliko dana vazi registracija
Config.RegisterPrice = 500
Config.RenewPrice = 250
Config.FineAmount = 750                 -- kazna za isteklu/neregistrovanu registraciju

Config.PlateFormat = 'AA000AA'          -- A = slovo, 0 = broj
Config.PersonalizedPlatePrice = 15000   -- Tebex/premium opcija

Config.RandomPoliceCheckChance = 8      -- % sansa da policija "primeti" isteklu reg. (po min proveri)
Config.CheckIntervalMs = 60000          -- interval provere trenutnog vozila

Config.Locale = {
    ['title']            = 'Registracija Vozila',
    ['plate']            = 'Tablice',
    ['model']            = 'Model',
    ['status_active']    = 'Aktivna',
    ['status_expired']   = 'Istekla',
    ['status_none']      = 'Nije registrovano',
    ['days_left']        = 'Preostalo dana',
    ['register_btn']     = 'Registruj vozilo',
    ['renew_btn']        = 'Obnovi registraciju',
    ['not_enough_money'] = 'Nemate dovoljno novca',
    ['success_register'] = 'Vozilo je uspesno registrovano',
    ['success_renew']    = 'Registracija je obnovljena',
    ['no_vehicle']       = 'Niste u vozilu',
    ['fine_message']     = 'Kaznjeni ste zbog neregistrovanog vozila',
}