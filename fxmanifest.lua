fx_version 'cerulean'
game 'gta5'

description 'Simple ammunation robbery'
author 'OGReaper'
version '0.1.5'

shared_scripts {
	'@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
	'client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'server/*.lua',
    'server/utils.lua',
}

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_inventory',
    'ox_target'
}

lua54 'yes'