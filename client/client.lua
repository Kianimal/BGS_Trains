local canSpawn = false
local switch
local switchPrompt

local westTrain
local westConductor
local eastTrain
local eastConductor
local tram
local tramConductor
local Trains = {}
local TrainModels = {
    'northsteamer01x'
}
local object

local christmasTrainHash = 0x124A1F89

local entityEnumerator = {
    __gc = function(enum)
        if enum.destructor and enum.handle then
            enum.destructor(enum.handle)
        end
        enum.destructor = nil
        enum.handle = nil
    end
}

local function EnumerateEntities(firstFunc, nextFunc, endFunc)
    return coroutine.wrap(function()
        local iter, id = firstFunc()

        if not id or id == 0 then
            endFunc(iter)
            return
        end

        local enum = {handle = iter, destructor = endFunc}
        setmetatable(enum, entityEnumerator)

        local next = true
        repeat
            coroutine.yield(id)
            next, id = nextFunc(iter)
        until not next

        enum.destructor, enum.handle = nil, nil
        endFunc(iter)
    end)
end

local function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

local function IsTrain(vehicle)
    local model = GetEntityModel(vehicle)

    for _, trainModel in ipairs(TrainModels) do
        if model == GetHashKey(trainModel) then
            return true
        end
    end

    return false
end

local function GetSwitchObject()

	if switchPrompt then
		return
	end

    local size = 0

	local itemSet = CreateItemset(true)

	size = Citizen.InvokeNative(0x59B57C4B06531E1E, GetEntityCoords(PlayerPedId()), 7.5, itemSet, 3, Citizen.ResultAsInteger())

	if size > 0 then
		for index = 0, size do
			local entity = GetIndexedItemInItemset(index, itemSet)
			local model_hash = GetEntityModel(entity)
			if model_hash == joaat("s_railswitch01x_cmbd") then
				if IsItemsetValid(itemSet) then
					DestroyItemset(itemSet)
				end
				return entity
			end
		end
	end

	if IsItemsetValid(itemSet) then
		DestroyItemset(itemSet)
	end
end

local function SwitchJunction(railswitch, switchInfo)
	local sound = GetSoundId()
	ClearPedTasks(PlayerPedId())
	RequestAnimDict("script_story@trn3@ig@ig_1_pulllever")
	while not HasAnimDictLoaded("script_story@trn3@ig@ig_1_pulllever") do
		Wait(1)
	end
	if switchInfo.pushed then
		SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(railswitch, vec3(0.0, 3.425791, 0.0)), false, false, false, false)
		TaskTurnPedToFaceEntity(PlayerPedId(), railswitch, -1)
		Wait(2000)
		PlayEntityAnim(railswitch, "pulllever_railswitch", "script_story@trn3@ig@ig_1_pulllever", 1.0, false, true,false,0.0,32768)
		TaskPlayAnim(PlayerPedId(), "script_story@trn3@ig@ig_1_pulllever", "pulllever_arthur", 1.0,	1.0, -1, 0, 0.0, false, false, false, '', false)
		Wait(1250)
		Citizen.InvokeNative(0xF1C5310FEAA36B48, sound, "lock_gate", railswitch, "MOB1_Sounds", 0)
	else
		SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(railswitch, vec3(0.0, 3.425791, 0.0)), false, false, false, false)
		TaskTurnPedToFaceEntity(PlayerPedId(), railswitch, -1)
		Wait(2000)
		PlayEntityAnim(railswitch, "leverpush_railswitch", "script_story@trn3@ig@ig_1_pulllever", 1.0, false, true,false,0.0,32768)
		TaskPlayAnim(PlayerPedId(), "script_story@trn3@ig@ig_1_pulllever", "leverpush_arthur", 1.0,	1.0, -1, 0, 0.0, false, false, false, '', false)
		Wait(1250)
		Citizen.InvokeNative(0xF1C5310FEAA36B48, sound, "lock_gate", railswitch, "MOB1_Sounds", 0)
	end

	Wait(250)
	Citizen.InvokeNative(0x3210BCB36AF7621B, sound)
	if switchInfo.enabled == 0 then
		switchInfo.enabled = 1
	else
		switchInfo.enabled = 0
	end
	switchInfo.pushed = not switchInfo.pushed

	for index, value in ipairs(Config.SwitchObjects) do
		if value.coords == switchInfo.coords then
			value.enabled = switchInfo.enabled
			value.pushed = switchInfo.pushed
		end
	end

	for index, value in ipairs(Config.EastJunctions) do
		if value.trainTrack == switchInfo.trainTrack and value.junctionIndex == switchInfo.junctionIndex then
			value.enabled = switchInfo.enabled
		end
	end

	for index, value in ipairs(Config.WestJunctions) do
		if value.trainTrack == switchInfo.trainTrack and value.junctionIndex == switchInfo.junctionIndex then
			value.enabled = switchInfo.enabled
		end
	end
end

local function RenderSwitchPrompt(switchObject)
	if switchPrompt then
		return
	end
	if switchObject then
		for j, switchInfo in ipairs(Config.SwitchObjects) do
			if #(GetEntityCoords(switchObject) - switchInfo.coords) < 1.0 then
				CreateThread(function ()
					switchPrompt = PromptRegisterBegin()
					PromptSetControlAction(switchPrompt, joaat("INPUT_CONTEXT_Y"))
					PromptSetText(switchPrompt, CreateVarString(10, "LITERAL_STRING", "Switch Track"))
					PromptSetStandardMode(switchPrompt, true)
					PromptRegisterEnd(switchPrompt)

					local coords = GetOffsetFromEntityInWorldCoords(switchObject, 0.0, 3.525791, 0)

					if coords.x == 0 or coords.z == 0 then
						PromptDelete(switchPrompt)
						switchPrompt = nil
						return
					end

					local radius = 0.5
					-- _UI_PROMPT_CONTEXT_SET_POINT
					Citizen.InvokeNative(0xAE84C5EE2C384FB3, switchPrompt, coords)
					-- _UI_PROMPT_CONTEXT_SET_RADIUS
					Citizen.InvokeNative(0x0C718001B77CA468, switchPrompt, radius)

					while true do
						PromptSetEnabled(switchPrompt, true)
						Wait(1)
						if PromptHasStandardModeCompleted(switchPrompt, 0) then
							PromptSetEnabled(switchPrompt, false)
							SwitchJunction(switchObject, switchInfo)
							Wait(10000)
						end
					end
				end)
			end
		end
	end
end

-- Decorate Christmas train
local function DecorateTrain(vehicle)
    object = CreateObjectNoOffset(GetHashKey('mp006_p_veh_xmasnsteamer01x'), 0, 0, 0, false, false, false, false)
    AttachEntityToEntity(object, vehicle, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true, false, false)
    return object
end

-- Handle Christmas train shit
local function HandleChristmasTrains()
	CreateThread(function()
		while true do
			Wait(1000)
	
			if Config.UseChristmasTrainEast or Config.UseChristmasTrainWest then
				for vehicle in EnumerateVehicles() do
					if Config.UseChristmasTrainEast and vehicle == eastTrain then
						if IsTrain(vehicle) and not Trains[vehicle] then
							Trains[vehicle] = DecorateTrain(vehicle)
						end
					end
					if Config.UseChristmasTrainWest and vehicle == westTrain then
						if IsTrain(vehicle) and not Trains[vehicle] then
							Trains[vehicle] = DecorateTrain(vehicle)
						end
					end
				end
	
				for train, object in pairs(Trains) do
					if not DoesEntityExist(train) then
						DeleteEntity(object)
						Trains[train] = nil
					end
				end
			end
		end
	end)
end

local function ReplaceCabinInterior(carriage, interior)
	local propset = Citizen.InvokeNative(0xCFC0BD09BB1B73FF, carriage)
	local propsetHash = Citizen.InvokeNative(0xA6A9712955F53D9C, propset)
	local request = Citizen.InvokeNative(0xF3DE57A46D5585E9, interior)

	if Citizen.InvokeNative(0xF42DB680A8B2A4D9, propset) then
		while not Citizen.InvokeNative(0x48A88FC684C55FDC, propsetHash) do
			Wait(1)
		end
		Citizen.InvokeNative(0x3BCF32FF37EA9F1D, carriage)
	else
		return false
	end

	while not Citizen.InvokeNative(0x48A88FC684C55FDC, interior) do
		Wait(1)
	end

	local attachedPropset = Citizen.InvokeNative(0x9609DBDDE18FAD8C, interior, 0, 0, 0, carriage, 0, true, 0, true)

	Citizen.InvokeNative(0xB1964A83B345B4AB, interior)
	return true
end

local function UnlockCabinDoors(carriage)
	Citizen.InvokeNative(0x550CE392A4672412, carriage, 9, true, true)			-- Open fancy cabin doors
	Citizen.InvokeNative(0x550CE392A4672412, carriage, 10, true, true)			-- Open fancy cabin doors
	Citizen.InvokeNative(0x550CE392A4672412, carriage, 11, true, true)			-- Open fancy cabin doors
end

local function HandleFancyTrain(train)
	local barCreated = false
	local sleepersCreated = false
	CreateThread(function ()

		while true do
			Wait(1000)
			local carriage = Citizen.InvokeNative(0xD0FB093A4CDB932C, train, 3)
			local carriage2 = Citizen.InvokeNative(0xD0FB093A4CDB932C, train, 4)
			local carriage3 = Citizen.InvokeNative(0xD0FB093A4CDB932C, train, 6)
			local carriage4 = Citizen.InvokeNative(0xD0FB093A4CDB932C, train, 5)
			if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(carriage4)) < 150 and (not barCreated or not sleepersCreated) then
				if not barCreated or not sleepersCreated then
					if not barCreated then
						barCreated = ReplaceCabinInterior(carriage, -1747631964)
					end
					if not sleepersCreated then
						sleepersCreated = ReplaceCabinInterior(carriage2, -317994478)
					end
					UnlockCabinDoors(carriage3)
					UnlockCabinDoors(carriage4)
				end
			end
		end
	end)
end

-- Render train blips after values are retrieved from server
local function RenderTrainBlip(train)
	if Config.UseTrainBlips then
		local TrainBlip
		if train then
			if IsThisModelATrain(GetEntityModel(train)) then
				TrainBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 1664425300, train)
				SetBlipSprite(TrainBlip, -250506368)
				if train == eastTrain then
					Citizen.InvokeNative(0x9CB1A1623062F402, TrainBlip, Config.TrainBlipNameEast)
				elseif train == westTrain then
					Citizen.InvokeNative(0x9CB1A1623062F402, TrainBlip, Config.TrainBlipNameWest)
				end
				SetBlipScale(TrainBlip, 1.0)
			end
		end
	end
end

RegisterNetEvent("BGS_Trains:client:RenderTrainBlip", function (train)
	RenderTrainBlip(train)
end)

-- Create train and tram vehicles, network and store server side
local function TrainCreateVehicle(trainModel, location, trainArea, direction)

	CreateThread(function ()
		while true do
			Wait(1000)
			local trainWagons = N_0x635423d55ca84fc8(trainModel)

			for i = 0, trainWagons - 1 do
				local trainWagonModel = N_0x8df5f6a19f99f0d5(trainModel, i)
				RequestModel(trainWagonModel)
				while not HasModelLoaded(trainWagonModel) do
					Citizen.Wait(0)
				end
			end

			local trainVeh

			if trainModel ~= Config.Trolley then
				if trainArea == "east" then
					trainVeh = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, location, direction, false, true, true)
				else
					trainVeh = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, location, direction, false, true, true)
				end
				SetTrainSpeed(trainVeh, Config.TrainMaxSpeed)
				SetTrainCruiseSpeed(trainVeh, Config.TrainMaxSpeed)
				Citizen.InvokeNative(0x9F29999DFDF2AEB8, trainVeh, Config.TrainMaxSpeed)
				Citizen.InvokeNative(0x4182C037AA1F0091, trainVeh, true) 					-- Set train stops for stations
				Citizen.InvokeNative(0x8EC47DD4300BF063, trainVeh, 0.0) 					-- Set train offset for station
			else
				trainVeh = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, location, true, Config.UsePassengersTram, true, true)
				SetTrainSpeed(trainVeh, 2.0)
				Citizen.InvokeNative(0x4182C037AA1F0091, trainVeh, true) 					-- Set train stops for stations
				Citizen.InvokeNative(0x8EC47DD4300BF063, trainVeh, 0.0) 					-- Set train offset for station
			end

			local trainDriverHandle = GetPedInVehicleSeat(trainVeh, -1)
			while not DoesEntityExist(trainDriverHandle) do
				trainDriverHandle = GetPedInVehicleSeat(trainVeh, -1)
				SetEntityAsMissionEntity(trainDriverHandle, true, true)
				Citizen.Wait(1)
			end

			if DoesEntityExist(trainVeh) and DoesEntityExist(trainDriverHandle) then
				NetworkRegisterEntityAsNetworked(trainVeh)
				NetworkRegisterEntityAsNetworked(trainDriverHandle)
				if NetworkDoesNetworkIdExist(NetworkGetNetworkIdFromEntity(trainVeh)) and NetworkDoesNetworkIdExist(NetworkGetNetworkIdFromEntity(trainDriverHandle)) then
					SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(trainVeh), true)
					SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(trainDriverHandle), true)
					TriggerServerEvent("BGS_Trains:server:StoreNetIndex", NetworkGetNetworkIdFromEntity(trainVeh), NetworkGetNetworkIdFromEntity(trainDriverHandle), trainArea)
					return
				end
			end
		end
	end)
end

-- Prevent people from knocking driver out of train
local function ProtectTrainDriver(trainDriverHandle)
	if trainDriverHandle then
		SetPedCanBeKnockedOffVehicle(trainDriverHandle, 1)
		SetEntityInvincible(trainDriverHandle, true)
		SetBlockingOfNonTemporaryEvents(trainDriverHandle, true)
		SetEntityAsMissionEntity(trainDriverHandle, true, true)
		SetEntityCanBeDamaged(trainDriverHandle, false)
	end
end

local function SpawnTrains()
	TriggerServerEvent("BGS_Trains:server:CanSpawnTrain")
	Wait(3000)
	if canSpawn then
		if Config.UseEastTrain then
			if Config.UseChristmasTrainEast then
				TrainCreateVehicle(christmasTrainHash, Config.EastTrainSpawnLocation, "east", Config.EastTrainDirection)
			elseif Config.UseFancyTrainEast then
				TrainCreateVehicle(0xCD2C7CA1, Config.EastTrainSpawnLocation, "east", Config.EastTrainDirection)
			else
				TrainCreateVehicle(Config.EastTrain, Config.EastTrainSpawnLocation, "east", Config.EastTrainDirection)
			end
		end
		if Config.UseWestTrain then
			if Config.UseChristmasTrainWest then
				TrainCreateVehicle(christmasTrainHash, Config.WestTrainSpawnLocation, "west", Config.WestTrainDirection)
			elseif Config.UseFancyTrainWest then
				TrainCreateVehicle(0xCD2C7CA1, Config.WestTrainSpawnLocation, "west", Config.WestTrainDirection)
			else
				TrainCreateVehicle(Config.WestTrain, Config.WestTrainSpawnLocation, "west", Config.WestTrainDirection)
			end
		end
		if Config.UseTram then
			TrainCreateVehicle(Config.Trolley, Config.TramSpawnLocation)
		end
		Wait(3000)
		TriggerServerEvent("BGS_Trains:server:AllPlayersGetTrainsFromServer")
	else
		Wait(3000)
		TriggerServerEvent("BGS_Trains:server:GetTrainsFromServer")
	end
end

-- Spawn trains if able, if unable then store train variables from server and render blips for existing trains
RegisterNetEvent("vorp:SelectedCharacter", function()
	SpawnTrains()
end)

RegisterNetEvent("RSGCore:Client:OnPlayerLoaded", function()
	SpawnTrains()
end)

-- Determine if player can spawn first trains or not
RegisterNetEvent("BGS_Trains:client:CanSpawnTrain", function(canSpawnTrains)
	canSpawn = canSpawnTrains
end)

-- Get net indexes for train values from server, convert and store
RegisterNetEvent("BGS_Trains:client:GetTrainsFromServer", function (eastNet, westNet, tramNet, eastConductorNet, westConductorNet, tramConductorNet)
	local spawnedWest = true
	local spawnedEast = true
	local spawnedTram = true
	if Config.UseEastTrain then
		spawnedEast = false
		if eastNet then
			eastTrain = NetworkGetEntityFromNetworkId(eastNet)
			eastConductor = NetworkGetEntityFromNetworkId(eastConductorNet)
			ProtectTrainDriver(eastConductor)
			spawnedEast = true
			RenderTrainBlip(eastTrain)
			Citizen.InvokeNative(0xA670B3662FAFFBD0, eastNet)
			Citizen.InvokeNative(0xA670B3662FAFFBD0, eastConductorNet)
		end
	end
	if Config.UseWestTrain then
		spawnedWest = false
		if westNet then
			westTrain = NetworkGetEntityFromNetworkId(westNet)
			westConductor = NetworkGetEntityFromNetworkId(westConductorNet)
			ProtectTrainDriver(westConductor)
			spawnedWest = true
			RenderTrainBlip(westTrain)
			Citizen.InvokeNative(0xA670B3662FAFFBD0, westNet)
			Citizen.InvokeNative(0xA670B3662FAFFBD0, westConductorNet)
		end
	end
	if Config.UseTram then
		spawnedTram = false
		if tramNet then
			tram = NetworkGetEntityFromNetworkId(tramNet)
			tramConductor = NetworkGetEntityFromNetworkId(tramConductorNet)
			ProtectTrainDriver(tramConductor)
			spawnedTram = true
			Citizen.InvokeNative(0xA670B3662FAFFBD0, tramNet)
			Citizen.InvokeNative(0xA670B3662FAFFBD0, tramConductorNet)
		end
	end

	if spawnedWest and spawnedEast and spawnedTram then
		if Config.UseChristmasTrainEast or Config.UseChristmasTrainWest then
			HandleChristmasTrains()
		end
		if Config.UseFancyTrainEast then
			HandleFancyTrain(eastTrain)
		end
		if Config.UseFancyTrainWest then
			HandleFancyTrain(westTrain)
		end
		return
	else
		Wait(1000)
		TriggerServerEvent("BGS_Trains:server:GetTrainsFromServer")
		return
	end
end)

RegisterNetEvent("BGS_Trains:client:ResetTrain", function (trainArea)
	if trainArea == "east" then
		if Config.UseChristmasTrainEast then
			TrainCreateVehicle(christmasTrainHash, Config.EastTrainSpawnLocation, "east", Config.EastTrainDirection)
		elseif Config.UseFancyTrainEast then
			TrainCreateVehicle(0xCD2C7CA1, Config.EastTrainSpawnLocation, "east", Config.EastTrainDirection)
		else
			TrainCreateVehicle(Config.EastTrain, Config.EastTrainSpawnLocation, "east", Config.EastTrainDirection)
		end
		Wait(2500)
		TriggerServerEvent("BGS_Trains:server:AllPlayersGetTrainsFromServer")
		Wait(2500)
		TriggerServerEvent("BGS_Trains:server:ResetTrainBlip", eastTrain)
	elseif trainArea == "west" then
		if Config.UseChristmasTrainWest then
			TrainCreateVehicle(christmasTrainHash, Config.WestTrainSpawnLocation, "west", Config.WestTrainDirection)
		elseif Config.UseFancyTrainWest then
			TrainCreateVehicle(0xCD2C7CA1, Config.WestTrainSpawnLocation, "west", Config.WestTrainDirection)
		else
			TrainCreateVehicle(Config.WestTrain, Config.WestTrainSpawnLocation, "west", Config.WestTrainDirection)
		end
		Wait(2500)
		TriggerServerEvent("BGS_Trains:server:AllPlayersGetTrainsFromServer")
		Wait(2500)
		TriggerServerEvent("BGS_Trains:server:ResetTrainBlip", westTrain)
	end
end)

CreateThread(function ()
	if not Config.UseManualJunctions then
		return
	end
	while true do
		Wait(2500)
		for index, value in ipairs(Config.SwitchObjects) do
			if #(GetEntityCoords(PlayerPedId()) - value.coords) < 20 and not switch then
				switch = GetSwitchObject()
				RenderSwitchPrompt(switch)
			end
		end
		if switch and switchPrompt then
			if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(switch)) > 20 then
				PromptDelete(switchPrompt)
				switchPrompt = nil
				switch = nil
			end
		end
	end
end)

-- Handle west train shit
CreateThread(function()
	if not Config.UseWestTrain then
		return
	end
	local stopped = false
	while true do
		Wait(500)
		if westTrain then
			for i = 1, #Config.WestJunctions do
				if GetDistanceBetweenCoords(GetEntityCoords(westTrain), Config.WestJunctions[i].coords) < 25 then
					Citizen.InvokeNative(0xE6C5E2125EB210C1, Config.WestJunctions[i].trainTrack, Config.WestJunctions[i].junctionIndex, Config.WestJunctions[i].enabled)
					Citizen.InvokeNative(0x3ABFA128F5BF5A70, Config.WestJunctions[i].trainTrack, Config.WestJunctions[i].junctionIndex, Config.WestJunctions[i].enabled)
				end
			end
			if Citizen.InvokeNative(0xE887BD31D97793F6, westTrain) then
				Citizen.InvokeNative(0x3660BCAB3A6BB734, westTrain)
				Wait(Config.StationWaitTime*1000)
				Citizen.InvokeNative(0x787E43477746876F, westTrain)
			end
			for index, stop in ipairs(Config.CustomStops) do
				if GetDistanceBetweenCoords(stop.coords, GetEntityCoords(westTrain)) < 7.5 and not stopped then
					Citizen.InvokeNative(0x3660BCAB3A6BB734, westTrain)
					Wait(Config.StationWaitTime*1000)
					Citizen.InvokeNative(0x787E43477746876F, westTrain)
					stopped = true
				end
				if GetDistanceBetweenCoords(stop.coords, GetEntityCoords(westTrain)) > 7.5 then
					stopped = false
				end
			end
		end
	end
end)

-- Handle east train shit
CreateThread(function()
	if not Config.UseEastTrain then
		return
	end
	local stopped = false
	while true do
		Wait(500)
		if eastTrain then
			for i = 1, #Config.EastJunctions do
				if GetDistanceBetweenCoords(GetEntityCoords(eastTrain), Config.EastJunctions[i].coords) < 15 then
					if Config.EastJunctions[i].trainTrack == -705539859 and Config.EastJunctions[i].junctionIndex == 2 and not Config.UseManualJunctions then
						Config.EastJunctions[i].enabled = Config.EastJunctions[i].enabled == 0 and 1 or 0
						Citizen.InvokeNative(0xE6C5E2125EB210C1, Config.EastJunctions[i].trainTrack, Config.EastJunctions[i].junctionIndex, Config.EastJunctions[i].enabled)
						Citizen.InvokeNative(0x3ABFA128F5BF5A70, Config.EastJunctions[i].trainTrack, Config.EastJunctions[i].junctionIndex, Config.EastJunctions[i].enabled)
						Wait(45000)
					else
						Citizen.InvokeNative(0xE6C5E2125EB210C1, Config.EastJunctions[i].trainTrack, Config.EastJunctions[i].junctionIndex, Config.EastJunctions[i].enabled)
						Citizen.InvokeNative(0x3ABFA128F5BF5A70, Config.EastJunctions[i].trainTrack, Config.EastJunctions[i].junctionIndex, Config.EastJunctions[i].enabled)
					end
				end
			end
			if Citizen.InvokeNative(0xE887BD31D97793F6, eastTrain) then
				Citizen.InvokeNative(0x3660BCAB3A6BB734, eastTrain)
				Wait(Config.StationWaitTime*1000)
				Citizen.InvokeNative(0x787E43477746876F, eastTrain)
			end
			for index, stop in ipairs(Config.CustomStops) do
				if GetDistanceBetweenCoords(stop.coords, GetEntityCoords(eastTrain)) < 15 and not stopped then
					Citizen.InvokeNative(0x3660BCAB3A6BB734, eastTrain)
					Wait(Config.StationWaitTime*1000)
					Citizen.InvokeNative(0x787E43477746876F, eastTrain)
					stopped = true
				end
				if GetDistanceBetweenCoords(stop.coords, GetEntityCoords(eastTrain)) > 15 then
					stopped = false
				end
			end
		end
	end
end)

-- Handle tram shit
CreateThread(function()
	if not Config.UseTram then
		return
	end
	while true do
		Wait(250)
		if tram then
			local coords = GetEntityCoords(tram)
        	local traincoords = vector3(coords.x, coords.y, coords.z)
			for i = 1, #Config.RouteOneTramSwitches do
				local switchdist = #(Config.RouteOneTramSwitches[i].coords - traincoords)
				if switchdist < 10.0 then
					if Config.RouteOneTramSwitches[i].junctionIndex == 10 or Config.RouteOneTramSwitches[i].junctionIndex == 13 then
						Config.RouteOneTramSwitches[i].enabled = Config.RouteOneTramSwitches[i].enabled == 0 and 1 or 0
						Citizen.InvokeNative(0xE6C5E2125EB210C1, Config.RouteOneTramSwitches[i].trainTrack, Config.RouteOneTramSwitches[i].junctionIndex, Config.RouteOneTramSwitches[i].enabled)
						Citizen.InvokeNative(0x3ABFA128F5BF5A70, Config.RouteOneTramSwitches[i].trainTrack, Config.RouteOneTramSwitches[i].junctionIndex, Config.RouteOneTramSwitches[i].enabled)
						Wait(45000)
					else
						Citizen.InvokeNative(0xE6C5E2125EB210C1, Config.RouteOneTramSwitches[i].trainTrack, Config.RouteOneTramSwitches[i].junctionIndex, Config.RouteOneTramSwitches[i].enabled)
						Citizen.InvokeNative(0x3ABFA128F5BF5A70, Config.RouteOneTramSwitches[i].trainTrack, Config.RouteOneTramSwitches[i].junctionIndex, Config.RouteOneTramSwitches[i].enabled)
					end
				end
			end
		end
	end
end)

-- Protect west train driver from being knocked out of train
CreateThread(function()
	if not Config.UseWestTrain or not Config.ProtectTrainDrivers then
		return
	end
	while true do
		Wait(0)
		if westConductor and Config.ProtectTrainDrivers then
			if #(GetEntityCoords(westConductor) - GetEntityCoords(PlayerPedId())) < 20.0 then
				Citizen.InvokeNative(0xFC094EF26DD153FA, 12)
			end
		end
	end
end)

-- Protect east train driver from being knocked out of train
CreateThread(function()
	if not Config.UseEastTrain or not Config.ProtectTrainDrivers then
		return
	end
	while true do
		Wait(0)
		if eastConductor and Config.ProtectTrainDrivers then
			if #(GetEntityCoords(eastConductor) - GetEntityCoords(PlayerPedId())) < 20.0 then
				Citizen.InvokeNative(0xFC094EF26DD153FA, 12)
			end
		end
	end
end)