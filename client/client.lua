-- Based on Malik's and Blue's animal shelters and vorp animal shelter, hunting/raising/tracking system added by HAL

local keys = Config.Keys

local pressTime = 0
local pressLeft = 0

local recentlySpawned = 0

local currentPetPeds = {};

local CurrentZoneActive = 0
local petXP = 0
local pets = Config.Pets
local fetchedObj = nil
local MyAnimalsTable = {}

local RTHPrompt = {}
local GrazePrompt = {}
local StayPrompt = {}
local FollowPrompt = {}
local PlayerJob = nil
local currentBlips = {}

function DeleteBlips()
	for i = 1, #currentBlips do
		RemoveBlip(currentBlips[i])
		currentBlips = {}
	end  
end

function AddBlips()
	local i = 1
	currentBlips = {}
	
	for _, info in pairs(Config.Shops) do
		local binfo = info.Blip
		local blip = N_0x554d9d53f696d002(1664425300, binfo.x, binfo.y, binfo.z)
		SetBlipSprite(blip, binfo.sprite, 1)
		SetBlipScale(blip, 0.2)
		Citizen.InvokeNative(0x9CB1A1623062F402, blip, info.Name)
		Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey('BLIP_MODIFIER_MP_COLOR_6'))

		currentBlips[i] = blip
		i = i + 1 
	end 
end

Citizen.CreateThread(function()
	if Config.NeedJob == true and Config.Job == PlayerJob then
		for _, info in pairs(Config.Shops) do
			if Config.NeedJob == true and PlayerJob == Config.Job or Config.NeedJob == false then
				local binfo = info.Blip
				local blip = N_0x554d9d53f696d002(1664425300, binfo.x, binfo.y, binfo.z)
				SetBlipSprite(blip, binfo.sprite, 1)
				SetBlipScale(blip, 0.2)
				Citizen.InvokeNative(0x9CB1A1623062F402, blip, info.Name)
				Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey('BLIP_MODIFIER_MP_COLOR_6'))
			end
		end  
	end
end)


local function SetPetAttributes(entity)
    -- | SET_ATTRIBUTE_POINTS | --
    Citizen.InvokeNative( 0x09A59688C26D88DF, entity, 0, 1100 )
    Citizen.InvokeNative( 0x09A59688C26D88DF, entity, 1, 1100 )
    Citizen.InvokeNative( 0x09A59688C26D88DF, entity, 2, 1100 )
    -- | ADD_ATTRIBUTE_POINTS | --
    Citizen.InvokeNative( 0x75415EE0CB583760, entity, 0, 1100 )
    Citizen.InvokeNative( 0x75415EE0CB583760, entity, 1, 1100 )
    Citizen.InvokeNative( 0x75415EE0CB583760, entity, 2, 1100 )
    -- | SET_ATTRIBUTE_BASE_RANK | --
    Citizen.InvokeNative( 0x5DA12E025D47D4E5, entity, 0, 10 )
    Citizen.InvokeNative( 0x5DA12E025D47D4E5, entity, 1, 10 )
    Citizen.InvokeNative( 0x5DA12E025D47D4E5, entity, 2, 10 )
    -- | SET_ATTRIBUTE_BONUS_RANK | --
    Citizen.InvokeNative( 0x920F9488BD115EFB, entity, 0, 10 )
    Citizen.InvokeNative( 0x920F9488BD115EFB, entity, 1, 10 )
    Citizen.InvokeNative( 0x920F9488BD115EFB, entity, 2, 10 )
    -- | SET_ATTRIBUTE_OVERPOWER_AMOUNT | --
    Citizen.InvokeNative( 0xF6A7C08DF2E28B28, entity, 0, 5000.0, false )
    Citizen.InvokeNative( 0xF6A7C08DF2E28B28, entity, 1, 5000.0, false )
    Citizen.InvokeNative( 0xF6A7C08DF2E28B28, entity, 2, 5000.0, false )
end

local function IsNearZone ( location, distance, ring )

	local player = PlayerPedId()
	local playerloc = GetEntityCoords(player, 0)

	for i = 1, #location do
		if #(playerloc - location[i]) < distance then
			if ring == true then
				Citizen.InvokeNative(0x2A32FAA57B937173, 0x6903B113, location[i].x, location[i].y, location[i].z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0, 2.0, 1.0, 100, 1, 1, 190, false, true, 2, false, false, false, false)
			end
			return true, i
		end
	end

end

local function DisplayHelp(_message, x, y, w, h, enableShadow, col1, col2, col3, a, centre)

	local str = CreateVarString(10, "LITERAL_STRING", _message, Citizen.ResultAsLong())

	SetTextScale(w, h)
	SetTextColor(col1, col2, col3, a)

	SetTextCentre(centre)

	if enableShadow then
		SetTextDropshadow(1, 0, 0, 0, 255)
	end

	Citizen.InvokeNative(0xADA9255D, 10);

	DisplayText(str, x, y)

end

local function ShowNotification(_message)
	local timer = 400
	while timer > 0 do
		DisplayHelp(_message, 0.50, 0.90, 0.6, 0.6, true, 161, 3, 0, 255, true)
		timer = timer - 1
		Citizen.Wait(0)
	end
end

local function checkAvailability(pet) 
	local availability = pet.Availability

	local available = false

	if availability ~= nil then 
		for index, peti in pairs(availability) do
			if peti == CurrentZoneActive then
				available = true
				return available
			end
		end
	else
		available = true
	end

	return available

end

-------------------------------------------------------- MENUS ----------------------------------------------------------------------
Citizen.CreateThread(function()
	local indice = nil
	WarMenu.CreateMenu('main', '')
	WarMenu.CreateSubMenu('buy_animal', 'main',  _U('Buying'))
	WarMenu.CreateSubMenu('select_type', 'buy_animal',  _U('SelectSex'))
	WarMenu.CreateSubMenu('my_animals', 'main', _U('MyAnimals'))
	WarMenu.CreateSubMenu('my_animal', 'my_animals', '')
	
	repeat
		-- MAIN MENU
		if WarMenu.IsMenuOpened('main') then
			if WarMenu.Button(_U('BuyAnimal')) then
				WarMenu.SetTitle('buy_animal', _U('FarmShop'))
				WarMenu.OpenMenu('buy_animal')
			end
			
			if WarMenu.Button(_U('MyAnimals')) then
				WarMenu.SetTitle('my_animals', _U('MyAnimals'))
				TriggerServerEvent('sultan_animal_farm:getanimals', true)
			end

		-- MY ANIMALS MENU
		elseif WarMenu.IsMenuOpened('my_animals') then
			local shop = Config.Shops[CurrentZoneActive]
			for i = 1, #MyAnimalsTable do
				if WarMenu.Button(MyAnimalsTable[i]['name'], '', MyAnimalsTable[i]['animaltype'].. " : " ..MyAnimalsTable[i]['sex']) then
					indice = i
					WarMenu.SetTitle('my_animal', MyAnimalsTable[indice].name)
					WarMenu.OpenMenu('my_animal')
				end
			end

		-- BUY ANIMALS MENU
		elseif WarMenu.IsMenuOpened('buy_animal') then
			for i = 1, #pets do
				local acheck = checkAvailability(pets[i])
				if acheck == true then
					if WarMenu.Button(pets[i]['Text'], ' ', pets[i]['Desc']) then
						indice = i
						WarMenu.OpenMenu('select_type')
					end
				end
			end

		-- SELECT SEX OF ANIMAL MENU
		elseif WarMenu.IsMenuOpened('select_type') then
			for i = 1, #pets[indice].Sex do
				-- MALE
				if pets[indice].Sex[i] == "Male" then
					if WarMenu.Button(_U('Male')) then
						TriggerEvent('sultan_animal_farm:EnterAnimalName', indice, "male")
						WarMenu.CloseMenu()
					end
				-- FEMALE
				elseif pets[indice].Sex[i] == "Female" then
					if WarMenu.Button(_U('Female')) then
						TriggerEvent('sultan_animal_farm:EnterAnimalName', indice, "female")
						WarMenu.CloseMenu()
					end
				end
			end

		-- SELECTED ANIMAL MENU
		elseif WarMenu.IsMenuOpened('my_animal') then
			
			if MyAnimalsTable[indice].actif == 0 then
				if WarMenu.Button(_U('Spawning')) then
					TriggerEvent('sultan_animal_farm:spawnanimal', MyAnimalsTable[indice].animal, MyAnimalsTable[indice].skin, true, 0, canTrack, MyAnimalsTable[indice].name)
					WarMenu.OpenMenu('main')
				end
			elseif MyAnimalsTable[indice].actif == 1 then
				if WarMenu.Button(_U('Despawn')) then
					TriggerEvent('sultan_animal_farm:removeanimal', MyAnimalsTable[indice].name)
					WarMenu.OpenMenu('main')
				end
			end
			
			if MyAnimalsTable[indice].xp > (Config.FullGrownXp / 2) then
				if WarMenu.Button(_U('Selling')) then
					TriggerEvent('sultan_animal_farm:ConfirmSelling', indice)
				end
			end
		end
		WarMenu.Display()
		Citizen.Wait(0)
	until false
end)

RegisterNetEvent("sultan_animal_farm:SendPlayerJob")
AddEventHandler("sultan_animal_farm:SendPlayerJob", function(Job)
	PlayerJob = Job
end)

Citizen.CreateThread(function()
	-- OPEN SHOW 
	while true do
		waitTime = 500
		for index, shop in pairs(Config.Shops) do
			-- JOB CHECK
			if Config.NeedJob == true and PlayerJob == Config.Job or Config.NeedJob == false then
				local IsZone, IdZone = IsNearZone( shop.Coords, shop.ActiveDistance, shop.Ring )
				if IsZone then
					waitTime = 1
					DisplayHelp(_U('Shoptext'), 0.50, 0.95, 0.6, 0.6, true, 255, 255, 255, 255, true)
					if IsControlJustPressed(0, keys[Config.TriggerKeys.OpenShop]) then
						WarMenu.SetTitle('main', shop.Name)
						WarMenu.OpenMenu('main')
						CurrentZoneActive = index
					end
				end
			end
		end
		Citizen.Wait(waitTime)
	end
end)


Citizen.CreateThread(function()
	while true do
		local scene = PedHasUseScenarioTask(currentPetPed)
		local ped = PlayerPedId()
		local flee = IsPedFleeing(currentPetPed)
		Citizen.Wait(100)	
		if scene or flee then 
			print(scene)
			print(flee)
			followOwner(currentPetPed,ped,false)
		end
	end
end)

-- | ANIMALS GROWING, SCALING AND COUPLING THREAD | --

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(60000)
		for i = 1, #currentPetPeds do
			if Config.RaiseAnimal then
				if currentPetPeds[i] and not IsEntityDead( currentPetPeds[i] ) then --Checking to see if your pet is active, not retriving and not hungry
					TriggerServerEvent('sultan_animal_farm:updateAnimalsServer')

					-- SCALING ANIMAL
					if Entity(currentPetPeds[i]).state.xp >= Config.FullGrownXp then
						SetPedScale(currentPetPeds[i], 1.0) --Use this for the XP system with pets
					elseif Entity(currentPetPeds[i]).state.xp >= (Config.FullGrownXp/2) then
						SetPedScale(currentPetPeds[i], 0.8)
					else
						SetPedScale(currentPetPeds[i], 0.6)
					end

					-- GRAZING 
					if Entity(currentPetPeds[i]).state.grazing == true then

						local luck = math.random(Entity(currentPetPeds[i]).state.difficulty)
						if luck == Entity(currentPetPeds[i]).state.difficulty then

							if Entity(currentPetPeds[i]).state.timer > 0 then
								print("Got it! " .. Entity(currentPetPeds[i]).state.name .. " timer : " .. Entity(currentPetPeds[i]).state.timer)
								Entity(currentPetPeds[i]).state.timer = Entity(currentPetPeds[i]).state.timer - 1
							end

							if Entity(currentPetPeds[i]).state.timer <= 0 then
								print(Entity(currentPetPeds[i]).state.name .. " is growing up!")
								Entity(currentPetPeds[i]).state.timer = Entity(currentPetPeds[i]).state.difficulty
								TriggerServerEvent('sultan_animal_farm:growUpAnimal', Entity(currentPetPeds[i]).state.name, Entity(currentPetPeds[i]).state.xp)
							end

						else
							print("Missed! " .. Entity(currentPetPeds[i]).state.name .. " timer : " .. Entity(currentPetPeds[i]).state.timer)
						end	
					end

					-- COUPLING
					if Entity(currentPetPeds[i]).state.xp >= (Config.FullGrownXp - (Config.FullGrownXp / 3)) and Entity(currentPetPeds[i]).state.couple == 'nobody' then
						-- NOT SEARCHING COUPLE
						if Entity(currentPetPeds[i]).state.searchCouple == false then
							
							local luck = math.random(Entity(currentPetPeds[i]).state.difficulty * Config.AnimalCouplingDifficulty)
							if luck == Entity(currentPetPeds[i]).state.difficulty * Config.AnimalCouplingDifficulty then
								Entity(currentPetPeds[i]).state.searchCouple = true
								--print("Got it " .. Entity(currentPetPeds[i]).state.name .. " is looking for a couple!")
							end
						-- SEARCHING COUPLE
						elseif Entity(currentPetPeds[i]).state.searchCouple == true and Entity(currentPetPeds[i]).state.sex == 'male' then
							for j = 1, #currentPetPeds do
								if Entity(currentPetPeds[j]).state.searchCouple == true and Entity(currentPetPeds[j]).state.sex ~= Entity(currentPetPeds[i]).state.sex and findAnimalCoupleWith(Entity(currentPetPeds[i]).state.animaltype) == Entity(currentPetPeds[j]).state.animaltype then
									
									local luck = math.random(Entity(currentPetPeds[i]).state.difficulty * Entity(currentPetPeds[j]).state.difficulty)
									if luck == Entity(currentPetPeds[i]).state.difficulty * Entity(currentPetPeds[j]).state.difficulty then
										Entity(currentPetPeds[i]).state.searchCouple = false
										Entity(currentPetPeds[j]).state.searchCouple = false
										Entity(currentPetPeds[i]).state.couple = Entity(currentPetPeds[j]).state.name
										Entity(currentPetPeds[j]).state.couple = Entity(currentPetPeds[i]).state.name

										TriggerServerEvent('sultan_animal_farm:setCouple', Entity(currentPetPeds[i]).state.name, Entity(currentPetPeds[j]).state.name)
										TriggerServerEvent('sultan_animal_farm:setCouple', Entity(currentPetPeds[j]).state.name, Entity(currentPetPeds[i]).state.name)
										print(Entity(currentPetPeds[i]).state.name .. " and " .. Entity(currentPetPeds[j]).state.name .. " are in couple!")

									else
										Entity(currentPetPeds[i]).state.couple = 'restricted'
										TriggerServerEvent('sultan_animal_farm:setCouple', Entity(currentPetPeds[i]).state.name, 'restricted')
										print(Entity(currentPetPeds[i]).state.name .. " will have never a child :(")
									end
								end
							end
						end

					-- REPRODUCTION
					elseif Entity(currentPetPeds[i]).state.couple ~= 'nobody' and Entity(currentPetPeds[i]).state.couple ~= 'restricted' and Entity(currentPetPeds[i]).state.sex == 'male' then
						for k = 1, #currentPetPeds do
							if Entity(currentPetPeds[k]).state.name == Entity(currentPetPeds[i]).state.couple then
								
								local luck = math.random((Entity(currentPetPeds[i]).state.difficulty + Entity(currentPetPeds[k]).state.difficulty))
								if luck == (Entity(currentPetPeds[i]).state.difficulty + Entity(currentPetPeds[k]).state.difficulty) then
									print("Coupling inbound!!!")
									reproduction(currentPetPeds[i], currentPetPeds[k])
									
									Entity(currentPetPeds[i]).state.couple = 'restricted'
									if math.random(2) == 1 then
										EnterChildName(Entity(currentPetPeds[i]).state.animaltype, Entity(currentPetPeds[i]).state.animal, Entity(currentPetPeds[k]).state.name, Entity(currentPetPeds[i]).state.name, Entity(currentPetPeds[k]).state.difficulty, Entity(currentPetPeds[i]).state.difficulty, 'male')
									else
										EnterChildName(Entity(currentPetPeds[k]).state.animaltype, Entity(currentPetPeds[k]).state.animal, Entity(currentPetPeds[k]).state.name, Entity(currentPetPeds[i]).state.name, Entity(currentPetPeds[k]).state.difficulty, Entity(currentPetPeds[i]).state.difficulty, 'female')
									end
								end
							end
						end
					end
				end		
			end
		end
	end
end)

-- REPRODUCTION ANIMATION
function reproduction(male, female)
	local male_coords = GetEntityCoords(male)
	local female_coords = GetEntityCoords(female)

	
	Entity(male).state.grazing = false
	Entity(male).state.stay = false
	ClearPedTasks(tonumber(male))
	ClearPedSecondaryTask(tonumber(male))
	followOwner(tonumber(male), tonumber(female),false)

	Entity(female).state.grazing = false
	Entity(female).state.stay = false
	ClearPedTasks(tonumber(female))
	ClearPedSecondaryTask(tonumber(female))
	followOwner(tonumber(female), tonumber(male),false)

	Citizen.Wait(500)
	TaskGoToCoordAnyMeans(male, female_coords, 5.0, 0, 0, 786603, 0xbf800000)

	Citizen.Wait(500)
	TaskTurnPedToFaceEntity(male, female, 20000)
	TaskTurnPedToFaceEntity(female, male, 20000)
	
end

function updatePrompts(entity, player_coords, restricted_towns)

	-- FOLLOW PROMPT TEXT
	if Entity(entity).state.mother ~= 'nobody' and currentPetPeds[findPed(Entity(entity).state.mother)] and Entity(entity).state.xp < (Config.FullGrownXp/2) then
		local str = CreateVarString(10, 'LITERAL_STRING', _U('FollowMother'))
		PromptSetText(FollowPrompt[entity], str)
	else
		local str = CreateVarString(10, 'LITERAL_STRING', _U('FollowMe'))
		PromptSetText(FollowPrompt[entity], str)
	end

	-- GRAZING PROMPT
	if not isInRestrictedTown(restricted_towns, player_coords) then
		if Entity(entity).state.grazing == false then
			PromptSetEnabled(GrazePrompt[entity], true)
			
		elseif Entity(entity).state.grazing == true then
			PromptSetEnabled(GrazePrompt[entity], false)
		end
	else 
		Entity(entity).state.grazing = false
		PromptSetEnabled(GrazePrompt[entity], false)
	end

	-- STAY PROMPT
	if Entity(entity).state.stay == false then
		PromptSetEnabled(StayPrompt[entity], true)
		
	elseif Entity(entity).state.stay == true then
		PromptSetEnabled(StayPrompt[entity], false)
		
	end

	-- RTH PROMPT
	if Entity(entity).state.xp >= Config.FullGrownXp then
		PromptSetVisible(RTHPrompt[entity], true)
		PromptSetEnabled(RTHPrompt[entity], true)
		
	else
		PromptSetVisible(RTHPrompt[entity], false)
		PromptSetEnabled(RTHPrompt[entity], false)
	end
end

-- MAIN THREAD
Citizen.CreateThread(function()
    while true do
        Wait(0)
		TriggerServerEvent("sultan_animal_farm:GetPlayerJob")

		local restricted_towns = convertConfigTownRestrictionsToHashRegister()
		local ped = PlayerPedId()
		local playerCoords = GetEntityCoords(ped)

		if Config.NeedJob == true and Config.Job ~= PlayerJob then
			DeleteBlips()
		elseif #currentBlips <= 0 then 
			AddBlips()
		end

		-- ANIMAL DESPAWN WITH DISTANCE
		for i = 1, #currentPetPeds do
			local animalCoords = GetEntityCoords(currentPetPeds[i])

			if GetDistanceBetweenCoords(playerCoords, animalCoords, true) > 100.0 then
				TriggerEvent('sultan_animal_farm:removeanimal', Entity(currentPetPeds[i]).state.name)
			end

			if IsEntityDead( currentPetPeds[i]) and Config.PetAttributes.CompleteDeath == true then
				TriggerServerEvent('sultan_animal_farm:deadAnimal', Entity(currentPetPeds[i]).state.name)
				table.remove(currentPetPeds, i)
				TriggerEvent('sultan_animal_farm:getanimals', false)
			end
		end

        local id = PlayerId()
        if IsPlayerTargettingAnything(id) then
            local result, entity = GetPlayerTargetEntity(id)
			
			if not IsEntityDead( entity ) and checkIfBeast(entity) == true then
				updatePrompts(entity, playerCoords, restricted_towns)

				if PromptHasStandardModeCompleted(GrazePrompt[entity]) then
					grazing(entity, true)
				end	
				if PromptHasStandardModeCompleted(FollowPrompt[entity]) then
					local ped = PlayerPedId()
					PlaySoundFrontend("ALERT_WHISTLE_01", "GAROA_Sounds", true, 1)

					if Entity(entity).state.mother ~= 'nobody' and currentPetPeds[findPed(Entity(entity).state.mother)] and Entity(entity).state.xp < (Config.FullGrownXp/2) then
						followMother(entity, currentPetPeds[findPed(Entity(entity).state.mother)]) 
					else
						followOwner(currentPetPeds[findPed(Entity(entity).state.name)], ped, false)
					end
					
					Wait(2000)
				end
				
				if PromptHasStandardModeCompleted(StayPrompt[entity]) then
					petStay(entity)
				end

				if PromptHasHoldModeCompleted(RTHPrompt[entity]) then
					returnToHome(Entity(entity).state.name)			
				end	
			
			-- HIDING PROMPTS IF DEAD
			else
				PromptSetEnabled(FollowPrompt[entity], false)
				PromptSetEnabled(StayPrompt[entity], false)
				PromptSetEnabled(RTHPrompt[entity], false)
				PromptSetEnabled(GrazePrompt[entity], false)

				PromptSetVisible(FollowPrompt[entity], false)
				PromptSetVisible(StayPrompt[entity], false)
				PromptSetVisible(RTHPrompt[entity], false)
				PromptSetVisible(GrazePrompt[entity], false)
			end
		else
			Wait(500)
        end
    end
end)

function checkIfBeast(entity)
	for i = 1, #currentPetPeds do
		if currentPetPeds[i] == entity then
			return true
		end
	end

	return false
end

function findPed(name)
	for i = 1, #currentPetPeds do
		if Entity(currentPetPeds[i]).state.name == name then
			return i
		end
	end
	return false
end

function findAnimal(name)
	for i = 1, #MyAnimalsTable do
		if MyAnimalsTable.name == name then
			return i
		end
	end
end

function grazing(entity, bool)
	if bool == true then
		if Entity(entity).state.grazing == false then
			FreezeEntityPosition(entity,true)
			Entity(entity).state.grazing = true
			Entity(entity).state.stay = false
		end
	else
		if Entity(entity).state.grazing == true then
			FreezeEntityPosition(entity,false)
			Entity(entity).state.grazing = false
		end
	end
	animalEatAnimation(entity)
end

-- ANIMATIONS, YOU CAN CUSTOM THEM RIGHT HERE
function animalEatAnimation(entity)
	local waiting = 0
	local dict = ""

	if Entity(entity).state.animal == 'A_C_Pig_01' then
		dict = "amb_creature_mammal@world_pig_grazing@base"

	elseif Entity(entity).state.animal == 'A_C_rooster_01' or Entity(entity).state.animal == 'A_C_chicken_01' then
		dict = "amb_creatures_bird@world_rooster_eating@base"

	elseif Entity(entity).state.animal == 'a_c_bull_01' then
		dict = "amb_creature_mammal@world_bull_grazing@base"

	elseif Entity(entity).state.animal == 'a_c_cow' then
		dict = "amb_creature_mammal@world_cow_grazing@base"

	elseif Entity(entity).state.animal == 'a_c_sheep_01' then
		dict = "amb_creature_mammal@world_sheep_grazing@base"
	
	end

	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		waiting = waiting + 100
		Citizen.Wait(100)
		if waiting > 5000 then
			TriggerEvent( 'UI:DrawNotification', "You broke the animation, Relocate")
			break
		end      
	end

	TaskPlayAnim(entity, dict, "base", 1.0, 8.0, -1, 1, 0, false, false, false)
end

function animalStayAnimation(currentPetPed)
	local dict = ""
	local waiting = 0

	if Entity(currentPetPed).state.animal == 'A_C_Pig_01' then
		dict = "amb_creature_mammal@world_pig_sleeping@base"

	elseif Entity(currentPetPed).state.animal == 'A_C_rooster_01' or Entity(currentPetPed).state.animal == 'A_C_chicken_01' then
		dict = "amb_creatures_bird@world_chicken_eating_sitting@base"
	
	elseif Entity(currentPetPed).state.animal == 'a_c_bull_01' then
		dict = "amb_creature_mammal@world_bull_sleeping@base"

	elseif Entity(currentPetPed).state.animal == 'a_c_cow' then
		dict = "amb_creature_mammal@world_cow_sleeping@base"
		
	elseif Entity(currentPetPed).state.animal == 'a_c_sheep_01' then
		dict = "amb_creature_mammal@world_sheep_sleeping@base"
	end

	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		waiting = waiting + 100
		Citizen.Wait(100)
		if waiting > 5000 then
			TriggerEvent( 'UI:DrawNotification', "You broke the animation, Relocate")
			break
		end      
	end
	
	TaskPlayAnim(currentPetPed, dict, "base", 1.0, 8.0, -1, 1, 0, false, false, false)

end

function AddFollowPrompts(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
	local str4 = _U('FollowMe')	

	if Entity(entity).state.mother ~= 'nobody' and currentPetPeds[findPed(Entity(entity).state.mother)] and Entity(entity).state.xp < (Config.FullGrownXp/2) then
		str4 = _U('FollowMother')	
	end
    FollowPrompt[entity] = PromptRegisterBegin()
    PromptSetControlAction(FollowPrompt[entity], 0x63A38F2C)
    str = CreateVarString(10, 'LITERAL_STRING', str4)
    PromptSetText(FollowPrompt[entity], str)
    PromptSetEnabled(FollowPrompt[entity], true)
    PromptSetVisible(FollowPrompt[entity], true)
    PromptSetStandardMode(FollowPrompt[entity], true)
    PromptSetGroup(FollowPrompt[entity], group)
    PromptRegisterEnd(FollowPrompt[entity])
end

function AddStayPrompts(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
    local str4 = _U('Stay')	
    StayPrompt[entity] = PromptRegisterBegin()
    PromptSetControlAction(StayPrompt[entity], 0x8AAA0AD4)
    str = CreateVarString(10, 'LITERAL_STRING', str4)
    PromptSetText(StayPrompt[entity], str)
    PromptSetEnabled(StayPrompt[entity], true)
    PromptSetVisible(StayPrompt[entity], true)
    PromptSetStandardMode(StayPrompt[entity], true)
    PromptSetGroup(StayPrompt[entity], group)
    PromptRegisterEnd(StayPrompt[entity])
end

function AddRTHPrompt(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
    local str6 = _U('Despawn')
    RTHPrompt[entity] = PromptRegisterBegin()
    PromptSetControlAction(RTHPrompt[entity], 0x6319DB71)
    str = CreateVarString(10, 'LITERAL_STRING', str6)
    PromptSetText(RTHPrompt[entity], str)
    PromptSetEnabled(RTHPrompt[entity], true)
    PromptSetVisible(RTHPrompt[entity], true)
    PromptSetHoldMode(RTHPrompt[entity], 2000)
    PromptSetGroup(RTHPrompt[entity], group)
    PromptRegisterEnd(RTHPrompt[entity])
end

function AddGrazePrompt(entity)
	local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong()) -- PromptGetGroupIdForTargetEntity
	local str6 = _U('Grazing')
	GrazePrompt[entity] = PromptRegisterBegin()
	PromptSetControlAction(GrazePrompt[entity], 0x05CA7C52)
	str = CreateVarString(10, 'LITERAL_STRING', str6)
	PromptSetText(GrazePrompt[entity], str)
	PromptSetEnabled(GrazePrompt[entity], true)
	--PromptSetVisible(GrazePrompt[entity], true)
	PromptSetStandardMode(GrazePrompt[entity], true)
	PromptSetGroup(GrazePrompt[entity], group)
	PromptRegisterEnd(GrazePrompt[entity])
end

function GetTown(x, y, z)
    return Citizen.InvokeNative(0x43AD8FC02B429D33, x, y, z, 1)
end

function isInRestrictedTown(restricted_towns, player_coords)
    player_coords = player_coords or GetEntityCoords(PlayerPedId())

    local x, y, z = table.unpack(player_coords)
    local town_hash = GetTown(x, y, z)

    if town_hash == false then
        return false
    end

    if restricted_towns[town_hash] then
        return true
    end

    return false
end

-- | Notification | --

RegisterNetEvent('UI:DrawNotification')
AddEventHandler('UI:DrawNotification', function( _message )
	ShowNotification( _message )
end)

-- | Remove animal | --

RegisterNetEvent('sultan_animal_farm:removeanimal')
AddEventHandler('sultan_animal_farm:removeanimal', function (name)
	if #currentPetPeds > 0 then 
		for i = 1, #currentPetPeds do
			if name == nil then
				--ShowNotification(_U('ReleasePet'))
				TriggerServerEvent('sultan_animal_farm:setActifValue', Entity(currentPetPeds[1]).state.name, 0)
				DeleteEntity(currentPetPeds[1])
				table.remove(currentPetPeds, 1)

			elseif currentPetPeds[i] and Entity(currentPetPeds[i]).state.name == name then
				--ShowNotification(_U('ReleasePet'))
				DeleteEntity(currentPetPeds[i])
				TriggerServerEvent('sultan_animal_farm:setActifValue', name, 0)
				table.remove(currentPetPeds, i)
				TriggerEvent('vorp:TipRight', name .. _U('ReturnedToHome'), 4000)	
			end
		end
		if name == nil then
			TriggerEvent('vorp:TipRight', _U('AllAnimalsReturnedToHome'), 4000)	
		end
	else
		local all = 'all'
		TriggerServerEvent('sultan_animal_farm:setActifValue', all, 0)
	end
end)

RegisterNetEvent('sultan_animal_farm:putaway')
AddEventHandler('sultan_animal_farm:putaway', function (args)
	if currentPetPed then
		DeleteEntity(currentPetPed)
		currentPetPed = nil
		--ShowNotification(_U('PetAway'))
		TriggerEvent('vorp:TipRight', 'de', 4000)	
	end
end)

function returnToHome(name)
	local indice = findPed(name)
	if currentPetPeds[indice] then
		FreezeEntityPosition(currentPetPeds[indice],false)
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		ClearPedTasks(currentPetPeds[indice])
		ClearPedSecondaryTask(currentPetPeds[indice])

		print("return to home")
		TaskGoStraightToCoord(currentPetPeds[indice], coords.x + 50, coords.y, coords.z, 3.0, 100000, GetEntityHeading(ped), 500)
		--TaskGoToCoordAnyMeans(currentPetPeds[indice], coords.x + 50, coords.y, coords.z, 3.0, 0, 0, 786603, 0xbf800000)
		Wait(5000)
		TriggerServerEvent('sultan_animal_farm:setActifValue', Entity(currentPetPeds[indice]).state.name, 0)
		TriggerEvent('vorp:TipRight', Entity(currentPetPeds[indice]).state.name .. _U('ReturnedToHome'), 4000)	
		DeleteEntity(currentPetPeds[indice])
		--ShowNotification(_U('PetAway'))
		table.remove(currentPetPeds, indice)
	end
end


-- | Spawn animal | --

function setPetBehavior(animal)

	SetRelationshipBetweenGroups(0, GetPedRelationshipGroupHash(animal), GetHashKey('PLAYER'))
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 143493179)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -2040077242)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 1222652248)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 1077299173)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -887307738)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1998572072)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -661858713)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 1232372459)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1836932466)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 1878159675)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 1078461828)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1535431934)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 1862763509)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1663301869)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1448293989)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1201903818)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -886193798)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1996978098)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 555364152)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -2020052692)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 707888648)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 378397108)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -350651841)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1538724068)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 1030835986)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1919885972)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1976316465)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 841021282)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 889541022)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1329647920)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -319516747)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -767591988)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -989642646)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), 1986610512)
	SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(animal), -1683752762)
	
end

function followOwner(currentPetPed, PlayerPedId, isInShop)
	Entity(currentPetPed).state.grazing = false
	Entity(currentPetPed).state.stay = false
	FreezeEntityPosition(currentPetPed,false)
	ClearPedTasks(currentPetPed)
	ClearPedSecondaryTask(currentPetPed)
	
	TaskFollowToOffsetOfEntity(currentPetPed, PlayerPedId, 0.0, -1.5, 0.0, 1.0, -1,  Config.PetAttributes.FollowDistance * 100000000, 1, 1, 0, 0, 1)
	if isInShop then
		Citizen.InvokeNative(0x489FFCCCE7392B55, currentPetPed, PlayerPedId)
	end
end

-- FOLLOW MOTHER
function followMother(child, mother)
	Entity(child).state.grazing = false
	Entity(child).state.stay = false
	FreezeEntityPosition(child,false)
	ClearPedTasks(child)
	ClearPedSecondaryTask(child)
	TaskFollowToOffsetOfEntity(child, mother, 0.0, -1.5, 0.0, 1.0, -1,  Config.PetAttributes.FollowDistance * 100000000, 1, 1, 0, 0, 1)
end

function petStay(currentPetPed)
	Entity(currentPetPed).state.stay = true
	Entity(currentPetPed).state.grazing = false
	ClearPedTasks(currentPetPed)
	ClearPedSecondaryTask(currentPetPed)
	animalStayAnimation(currentPetPed)
	FreezeEntityPosition(currentPetPed,true)
end

function convertConfigTownRestrictionsToHashRegister()
    local restricted_towns = {}

    for _, town_restriction in pairs(Config.TownRestrictions) do
        if not town_restriction.grazing_allowed then
            local town_hash = GetHashKey(town_restriction.name)
            restricted_towns[town_hash] = town_restriction.name
        end
    end

    return restricted_towns
end

RegisterNetEvent('sultan_animal_farm:ConfirmSelling')
AddEventHandler('sultan_animal_farm:ConfirmSelling', function(indice)
	Citizen.Wait(500)
	local myInput = {
		type = 'enableinput', -- don't touch
		inputType = 'input', -- input type
		button = _U('Validate'), -- button name
		placeholder =  _U('AnimalName'), -- placeholder name
		style = 'block', -- don't touch
		attributes = {
			inputHeader = _U('EnterName'), -- header
			type = 'textarea', -- inputype text, number,date,textarea ETC
			pattern = '[A-Za-z]+', --  only numbers '[0-9]' | for letters only '[A-Za-z]+' 
			title = _U('NameTypeError'), -- if input doesnt match show this message
			style = 'border-radius: 10px; background-color: ; border:none;'-- style 
		}
	}
	
	TriggerEvent('vorpinputs:advancedInput', json.encode(myInput), function(name)
		if name ~= '' and name ~= ' ' then -- make sure its not empty
			TriggerServerEvent('sultan_animal_farm:sellpet', name, MyAnimalsTable[indice].difficulty, findAnimalBasePrice(MyAnimalsTable[indice].animaltype), MyAnimalsTable[indice].xp)
			Citizen.Wait(200)
			TriggerServerEvent('sultan_animal_farm:getanimals', true)
			WarMenu.OpenMenu('main')
		end
	end)

end)

function findAnimalBasePrice (animal)
	for i = 1, #pets do
		if pets[i].SubText == animal then
			return pets[i].Param.Price
		end
	end
end 

function findAnimalCoupleWith (animal)
	for i = 1, #pets do
		if pets[i].SubText == animal then
			return pets[i].CoupleWith
		end
	end
end 

function EnterChildName(animaltype, animal, mother_name, dad_name, mother_difficulty, male_difficulty, sex)
	Citizen.Wait(500)
	local myInput = {
		type = 'enableinput', -- don't touch
		inputType = 'input', -- input type
		button = _U('Validate'), -- button name
		placeholder =  _U('AnimalName'), -- placeholder name
		style = 'block', -- don't touch
		attributes = {
			inputHeader = _U('EnterChildName'), -- header
			type = 'textarea', -- inputype text, number,date,textarea ETC
			pattern = '[A-Za-z]+', --  only numbers '[0-9]' | for letters only '[A-Za-z]+' 
			title = _U('NameTypeError'), -- if input doesnt match show this message
			style = 'border-radius: 10px; background-color: ; border:none;'-- style 
		}
	}
	
	TriggerEvent('vorpinputs:advancedInput', json.encode(myInput), function(name)
		if name ~= '' and name ~= ' ' then -- make sure its not empty
			TriggerServerEvent('sultan_animal_farm:setCouple', dad_name, 'restricted')
			TriggerServerEvent('sultan_animal_farm:getChild', name, animaltype, animal, mother_name, mother_difficulty, male_difficulty, sex)
		end
	end)
end

RegisterNetEvent('sultan_animal_farm:EnterAnimalName')
AddEventHandler('sultan_animal_farm:EnterAnimalName', function(indice, sex)
	Citizen.Wait(500)
	local myInput = {
		type = 'enableinput', -- don't touch
		inputType = 'input', -- input type
		button = _U('Validate'), -- button name
		placeholder =  _U('AnimalName'), -- placeholder name
		style = 'block', -- don't touch
		attributes = {
			inputHeader = _U('EnterName'), -- header
			type = 'textarea', -- inputype text, number,date,textarea ETC
			pattern = '[A-Za-z]+', --  only numbers '[0-9]' | for letters only '[A-Za-z]+' 
			title = _U('NameTypeError'), -- if input doesnt match show this message
			style = 'border-radius: 10px; background-color: ; border:none;'-- style 
		}
	}
	
	TriggerEvent('vorpinputs:advancedInput', json.encode(myInput), function(name)
		if name ~= '' and name ~= ' ' then -- make sure its not empty
			TriggerServerEvent('sultan_animal_farm:buyanimal', pets[indice]['Param'], name, pets[indice]['SubText'], sex)
		end
	end)
end)

RegisterNetEvent('sultan_animal_farm:drawMyAnimalsMenu')
AddEventHandler('sultan_animal_farm:drawMyAnimalsMenu', function(animals)
	WarMenu.OpenMenu('my_animals')
	MyAnimalsTable = {}
	MyAnimalsTable = animals
end)

RegisterNetEvent('sultan_animal_farm:UpdateAnimalsClient')
AddEventHandler('sultan_animal_farm:UpdateAnimalsClient', function(animals)
	MyAnimalsTable = {}
	MyAnimalsTable = animals
	
	for i = 1, #MyAnimalsTable do
		for j = 1, #currentPetPeds do
			if MyAnimalsTable[i].name == Entity(currentPetPeds[j]).state.name then
				Entity(currentPetPeds[j]).state.actif = MyAnimalsTable[i].actif
				Entity(currentPetPeds[j]).state.couple = MyAnimalsTable[i].couple
				Entity(currentPetPeds[j]).state.mother = MyAnimalsTable[i].mother
				Entity(currentPetPeds[j]).state.couple = MyAnimalsTable[i].couple
				Entity(currentPetPeds[j]).state.xp = MyAnimalsTable[i].xp
			end
		end
	end
end)

RegisterNetEvent("makelocalfuckershutup")
AddEventHandler("makelocalfuckershutup", function(netid)
	Wait(500)
	local ent = NetToPed(netid)
	print('shutting up entity with id: '..ent)
	--if not notifyHungry then
	Citizen.InvokeNative(0x9D64D7405520E3D3, ent, true)
	--end
end)

function spawnAnimals (model, player, x, y, z, h, skin, PlayerPedId, isdead, isshop, xp, i) 
	local EntityPedCoord = GetEntityCoords( player )
	local EntityanimalCoord = GetEntityCoords( currentPetPeds[findPed(MyAnimalsTable[i].name)] )
	local currentPetPedIndex = #currentPetPeds+1

	if #( EntityPedCoord - EntityanimalCoord ) > 100.0 or isshop or isdead then
		if currentPetPeds[i] ~= nil then
			DeleteEntity(currentPetPeds[findPed(MyAnimalsTable[i].name)])
		end

		petXP = xp
		currentPetPeds[currentPetPedIndex] = CreatePed(model, x, y, z, h, 1, 1 )
		Entity(currentPetPeds[currentPetPedIndex]).state.name = MyAnimalsTable[i].name
		Entity(currentPetPeds[currentPetPedIndex]).state.mother = MyAnimalsTable[i].mother
		Entity(currentPetPeds[currentPetPedIndex]).state.searchCouple = false
		Entity(currentPetPeds[currentPetPedIndex]).state.sex = MyAnimalsTable[i].sex
		Entity(currentPetPeds[currentPetPedIndex]).state.mother = MyAnimalsTable[i].mother
		Entity(currentPetPeds[currentPetPedIndex]).state.couple = MyAnimalsTable[i].couple
		Entity(currentPetPeds[currentPetPedIndex]).state.animal = MyAnimalsTable[i].animal
		Entity(currentPetPeds[currentPetPedIndex]).state.animaltype = MyAnimalsTable[i].animaltype
		Entity(currentPetPeds[currentPetPedIndex]).state.xp = MyAnimalsTable[i].xp
		Entity(currentPetPeds[currentPetPedIndex]).state.difficulty = MyAnimalsTable[i].difficulty
		Entity(currentPetPeds[currentPetPedIndex]).state.timer = Entity(currentPetPeds[currentPetPedIndex]).state.difficulty
		Entity(currentPetPeds[currentPetPedIndex]).state.grazing = false
		Entity(currentPetPeds[currentPetPedIndex]).state.stay = false

		SET_PED_OUTFIT_PRESET( currentPetPeds[currentPetPedIndex], skin )
		--SET_BLIP_TYPE( currentPetPed )
		SetEntityAsMissionEntity(currentPetPeds[currentPetPedIndex], true, true)
    	--SetBlockingOfNonTemporaryEvents(currentPetPed, true)
	 	
		local blip = Citizen.InvokeNative(0x23f74c2fda6e7c61, 422991367, currentPetPeds[currentPetPedIndex])
		Citizen.InvokeNative(0x2D64376CF437363E, blip, 0x0B93E613)
		if Config.PetAttributes.Invincible then
			SetEntityInvincible(currentPetPeds[currentPetPedIndex], true)
		end
		SetModelAsNoLongerNeeded(currentPetPeds[currentPetPedIndex])
		
		if Entity(currentPetPeds[currentPetPedIndex]).state.mother ~= 'nobody' and Entity(currentPetPeds[currentPetPedIndex]).state.xp < (Config.FullGrownXp/2) then
			followOwner(currentPetPeds[currentPetPedIndex], currentPetPeds[findPed(Entity(currentPetPeds[currentPetPedIndex]).state.mother)], isshop)
		else
			followOwner(currentPetPeds[currentPetPedIndex], player, isshop)
		end
		AddFollowPrompts(currentPetPeds[currentPetPedIndex])
		AddGrazePrompt(currentPetPeds[currentPetPedIndex])
		AddStayPrompts(currentPetPeds[currentPetPedIndex])
		
		Citizen.InvokeNative(0x931B241409216C1F, player, currentPetPeds[currentPetPedIndex])
		SetEntityCanBeDamagedByRelationshipGroup(currentPetPeds[currentPetPedIndex], Config.PetAttributes.FriendlyFire, GetHashKey("PLAYER"))

		if Config.NoFear then
			Citizen.InvokeNative(0x013A7BA5015C1372, currentPetPeds[currentPetPedIndex], false)
			Citizen.InvokeNative(0x3B005FF0538ED2A9, currentPetPeds[currentPetPedIndex])
			Citizen.InvokeNative(0xAEB97D84CDF3C00B, currentPetPeds[currentPetPedIndex], false)
		end

		SetPetAttributes(currentPetPeds[currentPetPedIndex])
		setPetBehavior(currentPetPeds[currentPetPedIndex])
		SetPedAsGroupMember(currentPetPeds[currentPetPedIndex], GetPedGroupIndex(PlayerPedId))

		if Config.RaiseAnimal then
			local halfGrowth = Config.FullGrownXp / 2

			if MyAnimalsTable[i].xp >= Config.FullGrownXp then
				SetPedScale(currentPetPeds[currentPetPedIndex], 1.0) --Use this for the XP system with pets
				AddRTHPrompt(currentPetPeds[currentPetPedIndex])
			elseif MyAnimalsTable[i].xp >= halfGrowth then
				SetPedScale(currentPetPeds[currentPetPedIndex], 0.8)
				AddRTHPrompt(currentPetPeds[currentPetPedIndex])
			else
				SetPedScale(currentPetPeds[currentPetPedIndex], 0.6)
			end
		else 
			petXP = Config.FullGrownXp
			AddStayPrompts(currentPetPeds[currentPetPedIndex])
		end
	
		while (GetScriptTaskStatus(currentPetPeds[currentPetPedIndex], 0x4924437d) ~= 8) do
			Wait(1000)
		end
	
		if isdead and Config.PetAttributes.Invincible == false then
			--ShowNotification( _U('petHealed') )
			TriggerEvent('vorp:TipRight', "Vous avez soigné votre companion!", 4000)	
		end

		-- SEARCH CHILD
		for l = 1, #currentPetPeds do
			if Entity(currentPetPeds[l]).state.mother == Entity(currentPetPeds[currentPetPedIndex]).state.name and Entity(currentPetPeds[l]).state.xp <= Config.FullGrownXp then
				followOwner(currentPetPeds[l], currentPetPeds[currentPetPedIndex], isshop)
			end
		end
	end
end

RegisterNetEvent('sultan_animal_farm:UpdateanimalFed')
AddEventHandler('sultan_animal_farm:UpdateanimalFed', function (newXP, growAnimal)
		
		if Config.RaiseAnimal and growAnimal then
		petXP = newXP
		local halfGrowth = Config.FullGrownXp / 2
			if petXP >= Config.FullGrownXp then
				SetPedScale(currentPetPed, 1.0)
				AddStayPrompts(currentPetPed)
				AddQuietModePrompts(currentPetPed)
				AddRTHPrompt(currentPetPed)
				--Use this for the XP system with pets
			elseif petXP >= halfGrowth then
				SetPedScale(currentPetPed, 0.8)	
				AddStayPrompts(currentPetPed)				
			else
				SetPedScale(currentPetPed, 0.6)
			end
		end
		isPetHungry = false
		FeedTimer = 0
		notifyHungry = false
end)

RegisterNetEvent('sultan_animal_farm:updateAnimals')
AddEventHandler('sultan_animal_farm:updateAnimals', function ()
	TriggerServerEvent('sultan_animal_farm:getanimals', false)
end)

RegisterNetEvent('sultan_animal_farm:spawnanimal')
AddEventHandler('sultan_animal_farm:spawnanimal', function (animal,skin,isInShop,xp,canTrack, name, mothername)

	TrackingEnabled = canTrack
	local player = PlayerPedId()
	local model = GetHashKey( animal )
	local x, y, z, heading, a, b
	local indice = 1

	for i = 1, #MyAnimalsTable do
		if MyAnimalsTable[i].name == name then
			indice = i
			TriggerServerEvent('sultan_animal_farm:setActifValue', MyAnimalsTable[indice].name, 1)
		end
	end

	-- Set initial pet location
	if isInShop then
		x, y, z, heading = -373.302, 786.904, 116.169, 273.18
	else
		local mother = findPed(mothername)
		x, y, z = table.unpack( GetOffsetFromEntityInWorldCoords( currentPetPeds[mother], 0.0, -5.0, 0.3 ) )
		a, b = GetGroundZAndNormalFor_3dCoord( x, y, z + 10 )
	end

	RequestModel( model )

	while not HasModelLoaded( model ) do
		Wait(500)
	end

	if isInShop then
		local x, y, z, w = table.unpack(Config.Shops[CurrentZoneActive].Spawnanimal)
		spawnAnimals(model, player, x, y, z, w, skin, PlayerPedId(), false, true, xp, indice) 
	else
		local mother = findPed(mothername)
		local EntityIsDead = false
		if (currentPetPeds[i] ~= nil) then
			EntityIsDead = IsEntityDead( currentPetPeds[i] )
		end

		if EntityIsDead then
			spawnAnimals(model, player, x, y, b, heading, skin, PlayerPedId(), true, false, xp, indice)
		else
			spawnAnimals(model, player, GetEntityCoords(currentPetPeds[mother]).x, GetEntityCoords(currentPetPeds[mother]).y, GetEntityCoords(currentPetPeds[mother]).z, GetEntityHeading(currentPetPeds[mother]), skin, PlayerPedId(), false, false, xp, indice)
		end
	end
end)

function SecondsToClock(seconds)
  local seconds = tonumber(seconds)
  if seconds <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    return hours..":"..mins..":"..secs
  end
end

function SET_BLIP_TYPE ( animal )
	
	 Citizen.InvokeNative(0x23f74c2fda6e7c61, 422991367, currentPetPed)
	 Citizen.InvokeNative(0x662D364ABF16DE2F, currentPetPed, 0xB1AE1182)
	 
end

function SET_ANIMAL_TUNING_BOOL_PARAM ( animal, p1, p2 )
	return Citizen.InvokeNative( 0x9FF1E042FA597187, animal, p1, p2 )
end

function SET_PED_DEFAULT_OUTFIT ( animal )
	return Citizen.InvokeNative( 0x283978A15512B2FE, animal, true )
end

function SET_PED_OUTFIT_PRESET ( animal, preset )
	return Citizen.InvokeNative( 0x77FF8D35EEC6BBC4, animal, preset, 0 )
end


AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerServerEvent("sultan_animal_farm:GetPlayerJob")
		if fetchedObj ~= nil then
			DeleteEntity(fetchedObj)
		end		
	end
end)


AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent( 'sultan_animal_farm:removeanimal' )
		if fetchedObj ~= nil then
			DeleteEntity(fetchedObj)
		end		
	end
end)


