-- Based on Malik's and Blue's animal shelters and vorp animal shelter --
local data = {}
local VorpCore = {}
local VorpInv

if Config.Framework == "redem" then
	TriggerEvent("redemrp_inventory:getData",function(call)
		data = call
	end)
elseif Config.Framework == "vorp" then
	TriggerEvent("getCore",function(core)
		VorpCore = core
	end)
	VorpInv = exports.vorp_inventory:vorp_inventoryApi()
end

RegisterServerEvent('sultan_animal_farm:sellpet')
AddEventHandler('sultan_animal_farm:sellpet', function(name, difficulty, baseprice, xp)

	local _src = source
	local Character = VorpCore.getUser(_src).getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier
	local amountmoney = baseprice + ((baseprice * difficulty) / 10) + (xp / 10)
	amountmoney = round(amountmoney, 2)

	exports.ghmattimysql:execute("DELETE FROM animal_farm WHERE identifier = @identifier AND charidentifier = @charidentifier AND name = @name", {["identifier"] = u_identifier, ['charidentifier'] = u_charid, ['name'] = name})
	Character.addCurrency(0, amountmoney)
	TriggerClientEvent('sultan_animal_farm:removeanimal', _src, name)
	TriggerClientEvent("vorp:NotifyLeft",_src, "~e~" .. _U('Shepherd') , _U('YouSold') .. "~o~" .. name .. _U('For') .. amountmoney .. "$", "toast_awards_set_c", "awards_set_c_001", 4000)
end)

RegisterServerEvent('sultan_animal_farm:deadAnimal')
AddEventHandler('sultan_animal_farm:deadAnimal', function(name)

	local _src = source
	local Character = VorpCore.getUser(_src).getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier

	exports.ghmattimysql:execute("DELETE FROM animal_farm WHERE identifier = @identifier AND charidentifier = @charidentifier AND name = @name", {["identifier"] = u_identifier, ['charidentifier'] = u_charid, ['name'] = name})
	TriggerClientEvent('sultan_animal_farm:removeanimal', _src, name)
	TriggerClientEvent("vorp:NotifyLeft",_src, "~e~" .. _U('Shepherd') , "~o~" .. name .. _U('IsDead'), "toast_awards_set_c", "awards_set_c_001", 4000)
end)


RegisterServerEvent('sultan_animal_farm:growUpAnimal')
AddEventHandler('sultan_animal_farm:growUpAnimal', function(name)

	local _src = source
	local Character = VorpCore.getUser(_src).getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier	
	local currentXP = 0	
	local newXp = 0

	local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid, ['name'] = name}
	exports.ghmattimysql:execute( "SELECT * FROM animal_farm WHERE identifier = @identifier  AND charidentifier = @charidentifier AND name = @name", Parameters, function(result)
		if result[1] then
			currentXP = result[1].xp
			newXp = currentXP + Config.XpPerFeed
		end

		if newXp < Config.FullGrownXp then
			local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid,  ['name'] = name, ['addedXp'] = Config.XpPerFeed }
			exports.ghmattimysql:execute("UPDATE animal_farm SET xp = xp + @addedXp WHERE identifier = @identifier AND charidentifier = @charidentifier AND name = @name", Parameters, function(result) end)		
			TriggerClientEvent("vorp:NotifyLeft",_src, "~e~" .. _U('Shepherd') , name .. _U('GrowedUp') .. "~COLOR_ORANGE~"..newXp.." ~o~/ " .. Config.FullGrownXp .. " xp", "toast_awards_set_c", "awards_set_c_001", 4000)
		else		
			local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid, ['name'] = name, ['fullXp'] = Config.FullGrownXp }	
			exports.ghmattimysql:execute("UPDATE animal_farm SET xp = @fullXp  WHERE identifier = @identifier AND charidentifier = @charidentifier AND name = @name", Parameters, function(result) end)		
			TriggerClientEvent("vorp:NotifyLeft",_src, "~e~" .. _U('Shepherd') , name .. "~COLOR_ORANGE~" .. _U('FullGrowReached'), "toast_awards_set_c", "awards_set_c_001", 4000)
		end	
	end)	
end)

RegisterServerEvent('sultan_animal_farm:setCouple')
AddEventHandler('sultan_animal_farm:setCouple', function(name, couple)

	local _src = source
	local Character = VorpCore.getUser(_src).getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier	

	local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid, ['name'] = name}
	exports.ghmattimysql:execute( "SELECT * FROM animal_farm WHERE identifier = @identifier  AND charidentifier = @charidentifier AND name = @name", Parameters, function(result)
		if #result then
			local CParameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid, ['name'] = name, ['couple'] = couple}
			exports.ghmattimysql:execute("UPDATE animal_farm SET couple = @couple WHERE identifier = @identifier AND charidentifier = @charidentifier AND name = @name", CParameters, function(cresult) end)
		end
	end)	
end)

RegisterServerEvent('sultan_animal_farm:getChild')
AddEventHandler('sultan_animal_farm:getChild', function (name, animaltype, animal, mothername, mother_difficulty, dad_difficulty, sex)
    local _src = source
	local Character = VorpCore.getUser(_src).getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier
	local skin = math.floor(math.random(0, 2))
	local canTrack = CanTrack(_src)
	local difficulty = 0

	if mother_difficulty > dad_difficulty then
		difficulty = math.random(dad_difficulty, mother_difficulty)
	else
		difficulty = math.random(mother_difficulty, dad_difficulty)
	end

	exports.ghmattimysql:execute("SELECT * FROM animal_farm WHERE identifier = @identifier AND charidentifier = @charidentifier", {['identifier'] = u_identifier, ['charidentifier'] = u_charid}, function(result)
		if #result < 10 then 

			exports.ghmattimysql:execute("SELECT * FROM animal_farm WHERE identifier = @identifier AND charidentifier = @charidentifier AND name = @name", {['identifier'] = u_identifier, ['charidentifier'] = u_charid, ['name'] = name}, function(already)
				-- CHECK IF ANIMAL NAME IS AVAILABLE
				if #already > 0 then
					TriggerClientEvent( 'UI:DrawNotification', _src, _U('NameNotAvailable') )
				else
					local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid,  ['name'] = name, ['sex'] = sex, ['animaltype'] = animaltype, ['animal'] = animal, ['skin'] = skin, ['xp'] = 0, ['difficulty'] = difficulty , ['mother'] = mothername}
					exports.ghmattimysql:execute("INSERT INTO animal_farm ( `identifier`,`charidentifier`, `name`, `sex`, `animaltype`,`animal`,`skin`, `xp` , `difficulty`, `mother`) VALUES ( @identifier,@charidentifier, @name, @sex, @animaltype, @animal, @skin, @xp, @difficulty, @mother )", Parameters, function(r2)
						TriggerClientEvent('sultan_animal_farm:updateAnimals', _src)
						Wait(2000)
						TriggerClientEvent('sultan_animal_farm:spawnanimal', _src,  animal, skin, false, 0, canTrack, name, mothername)
						TriggerClientEvent("vorp:NotifyLeft",_src, "~e~" .. _U('Shepherd') , "~COLOR_ORANGE~" .. name .. "~COLOR_WHITE~" .. _U('NewChild'), "toast_awards_set_c", "awards_set_c_001", 4000)
					end)
				end
			end)
		else
			TriggerClientEvent( 'UI:DrawNotification', _src, _U('TooManyPets') )
		end
	end)			
end)

RegisterServerEvent('sultan_animal_farm:buyanimal')
AddEventHandler('sultan_animal_farm:buyanimal', function (args, name, animaltype, sex)
    local _src = source
	local Character = VorpCore.getUser(_src).getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier
	local _price = args['Price']
	local _model = args['Model']
	local skin = math.floor(math.random(0, 2))
	local canTrack = CanTrack(_src)
	local difficulty = math.random(Config.AnimalMaxDifficulty)
	local u_money = Character.money

	if u_money <= _price then
		TriggerClientEvent( 'UI:DrawNotification', _src, _U('NoMoney') )
		return
	end
	exports.ghmattimysql:execute("SELECT * FROM animal_farm WHERE identifier = @identifier AND charidentifier = @charidentifier", {['identifier'] = u_identifier, ['charidentifier'] = u_charid}, function(result)
		if #result < 10 then 

			exports.ghmattimysql:execute("SELECT * FROM animal_farm WHERE identifier = @identifier AND charidentifier = @charidentifier AND name = @name", {['identifier'] = u_identifier, ['charidentifier'] = u_charid, ['name'] = name}, function(already)
				-- CHECK IF ANIMAL NAME IS AVAILABLE
				if #already > 0 then
					TriggerClientEvent( 'UI:DrawNotification', _src, _U('NameNotAvailable') )
				else
					local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid,  ['name'] = name, ['sex'] = sex, ['animaltype'] = animaltype, ['animal'] = _model, ['skin'] = skin, ['xp'] = 0, ['difficulty'] = difficulty }
					exports.ghmattimysql:execute("INSERT INTO animal_farm ( `identifier`,`charidentifier`, `name`, `sex`, `animaltype`,`animal`,`skin`, `xp` , `difficulty`) VALUES ( @identifier,@charidentifier, @name, @sex, @animaltype, @animal, @skin, @xp, @difficulty )", Parameters, function(r2)
						Character.removeCurrency(0, _price)
						TriggerClientEvent( 'UI:DrawNotification', _src, _U('NewPet') )
					end)
				end
			end)
		else
			TriggerClientEvent( 'UI:DrawNotification', _src, _U('TooManyPets') )
		end
	end)			
end)

RegisterServerEvent('sultan_animal_farm:setActifValue')
AddEventHandler('sultan_animal_farm:setActifValue', function (name, value)
    local _src = source
	local Character = VorpCore.getUser(_src).getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier

	if name ~= 'all' then
		local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid,  ['value'] = value, ['name'] = name}
		exports.ghmattimysql:execute("UPDATE animal_farm SET actif = @value WHERE identifier = @identifier AND charidentifier = @charidentifier AND name = @name", Parameters, function(result) end)
	else
		local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid,  ['value'] = value}
		exports.ghmattimysql:execute("UPDATE animal_farm SET actif = @value WHERE identifier = @identifier AND charidentifier = @charidentifier", Parameters, function(result) end)
	end
end)


RegisterServerEvent('sultan_animal_farm:loadanimal')
AddEventHandler('sultan_animal_farm:loadanimal', function()
    local _src   = source
	local Character = VorpCore.getUser(_src).getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier
	local canTrack = CanTrack(_src)

	local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid }
	exports.ghmattimysql:execute( "SELECT * FROM animal_farm WHERE identifier = @identifier  AND charidentifier = @charidentifier", Parameters, function(result)
		if result[1] then
			local animal = result[1].animal
			local skin = result[1].skin
			local xp = result[1].xp or 0
			TriggerClientEvent("sultan_animal_farm:spawnanimal", _src, animal, skin, false, xp,canTrack)
		else
			TriggerClientEvent( 'UI:DrawNotification', _src, _U('NoPet') )
		end
	end)	
end)

RegisterServerEvent('sultan_animal_farm:getanimals')
AddEventHandler('sultan_animal_farm:getanimals', function(openmenu)
    local _src   = source
	local buffer = {}
	local Character = VorpCore.getUser(_src).getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier
	local canTrack = CanTrack(_src)
	
	local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid }
	exports.ghmattimysql:execute( "SELECT * FROM animal_farm WHERE identifier = @identifier  AND charidentifier = @charidentifier", Parameters, function(result)
		if(#result ~= 0)then
			buffer = result
			if openmenu == true then 
            	TriggerClientEvent( 'sultan_animal_farm:drawMyAnimalsMenu', _src, buffer )
			end
		else
			TriggerClientEvent( 'UI:DrawNotification', _src, _U('NoPet') )
		end
	end)	
end)

RegisterServerEvent('sultan_animal_farm:updateAnimalsServer')
AddEventHandler('sultan_animal_farm:updateAnimalsServer', function()
    local _src   = source
	local buffer = {}
	local Character = VorpCore.getUser(_src).getUsedCharacter
	local u_identifier = Character.identifier
	local u_charid = Character.charIdentifier
	
	local Parameters = { ['identifier'] = u_identifier, ['charidentifier'] = u_charid }
	exports.ghmattimysql:execute( "SELECT * FROM animal_farm WHERE identifier = @identifier  AND charidentifier = @charidentifier", Parameters, function(result)
		if(#result > 0)then
			buffer = result
            TriggerClientEvent( 'sultan_animal_farm:UpdateAnimalsClient', _src, buffer )
		end
	end)	
end)

function CanTrack(source)
	local cb = false
	if Config.TrackCommand then
		if Config.AnimalTrackingJobOnly then
			local job = getJob(source)
			for k, v in pairs(Config.AnimalTrackingJobs) do
				if job == v then
				cb = true
				end
			end
		else 
			cb = true
		end
	end
	return(cb)
end

function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function getJob(source)
	local cb = false

	local Character = VorpCore.getUser(source).getUsedCharacter
	cb = Character.job
	 
 return cb
end

RegisterNetEvent("makefuckershutup")
AddEventHandler("makefuckershutup", function(netid)
	for _,player in pairs(GetPlayers()) do
		Wait(500)
		print(player)
		TriggerClientEvent("makelocalfuckershutup", player, netid)
	end
end)

