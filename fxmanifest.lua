fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kt-vehicle-registration'
author 'YourBrand'
version '1.0.0'
description 'Auto-detect Registration & Plates System (ESX/QBCore/QBox)'

shared_scripts {
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
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}