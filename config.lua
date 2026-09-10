Config = {}

Config.Framework = 'auto'
Config.Language = 'sr' -- 'sr' ili 'en'
Config.Locale = Locales[Config.Language]

-- ================== NPC / TARGET ==================
Config.NPC = {
    model = 'a_m_m_business_01',
    coords = vector4(733.4284, -1089.0437, 22.1690, 85.2881),
    interactDistance = 2.5
}

Config.UseBlip = true
Config.BlipSprite = 475
Config.BlipColor = 3
Config.BlipScale = 0.8
Config.BlipLabel = 'Registracija Vozila'

-- Fallback (koristi se SAMO ako ox_target i qb-target NISU instalirani)
Config.FallbackOpenKey = 38  -- E
Config.FallbackCheckKey = 'G'
Config.FallbackCheckDistance = 8.0

-- ================== REGISTRACIJA ==================
Config.RegistrationDays = 30
Config.RegisterPrice = 500
Config.RenewPrice = 250

Config.PlateFormat = 'AA000AA'
Config.PersonalizedPlatePrice = 15000
Config.PersonalizedPlateMinLength = 4
Config.PersonalizedPlateMaxLength = 8

-- ================== KAZNE ZA ISTEKLU REGISTRACIJU ==================
Config.FineOnExpired = true
Config.FineAmount = 750
Config.FineCheckInterval = 300000  -- 5 minuta
Config.FineCooldown = 900000       -- 15 minuta po tablici

-- ================== VERSION CHECK ==================
Config.Version = '1.0.0'
Config.GithubRepo = 'Kriki-T/kt-vehicle-registration'
Config.CheckUpdates = true