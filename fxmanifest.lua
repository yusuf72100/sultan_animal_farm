
fx_version "adamant"

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

games {"rdr3"}


ConvarFramework = "vorp" --IMPORTANT: Put either "redem" or "vorp" depending on your framework


client_scripts {
    'client/client.lua',
    'config.lua',
    'images/*.png'
}


shared_scripts {
    'config.lua',
	'locale.lua',
	'locales/fr.lua',
    'locales/en.lua',
}


if ConvarFramework == "vorp" then
	server_scripts {
		'@mysql-async/lib/MySQL.lua',
	}
end

server_scripts {

    'config.lua',
    'server/server.lua',
}
