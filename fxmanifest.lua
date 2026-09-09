fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kt-vehicle-registration'
author 'Kriki-T'
version '1.0.0'
description 'Auto-detect Registration & Plates System (ESX/QBCore/QBox + Target)'

shared_scripts {
    'locales/sr.lua',
    'locales/en.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/version_check.lua',
    'server/main.lua'
}

client_scripts {
    'bridge/client.lua',
    'client/main.lua',
    'client/lookup.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}