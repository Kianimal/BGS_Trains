local canSpawn = false

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

-- Render train blips after values are retrieved from server
local function RenderTrainBlips()
	local TrainBlip1
	local TrainBlip2
	if westTrain then
		TrainBlip1 = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 1664425300, westTrain)
		SetBlipSprite(TrainBlip1, -250506368)
		Citizen.InvokeNative(0x9CB1A1623062F402, TrainBlip1, Config.TrainBlipNameWest)
		SetBlipScale(TrainBlip1, 1.0)
	end
	if eastTrain then
		TrainBlip2 = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 1664425300, eastTrain)
		SetBlipSprite(TrainBlip2, -250506368)
		Citizen.InvokeNative(0x9CB1A1623062F402, TrainBlip2, Config.TrainBlipNameEast)
		SetBlipScale(TrainBlip2, 1.0)
	end
end

-- Create train and tram vehicles, network and store server side
local function TrainCreateVehicle(trainModel, location, trainArea)
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
		trainVeh = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, location, false, false, true, true)
		SetTrainSpeed(trainVeh, Config.TrainMaxSpeed)
		SetTrainCruiseSpeed(trainVeh, Config.TrainMaxSpeed)
		Citizen.InvokeNative(0x9F29999DFDF2AEB8, trainVeh, Config.TrainMaxSpeed)
		Citizen.InvokeNative(0x4182C037AA1F0091, trainVeh, true) 					-- Set train stops for stations
		Citizen.InvokeNative(0x8EC47DD4300BF063, trainVeh, 0.0) 					-- Set train offset for station
	else
		trainVeh = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, location, true, false, true, true)
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

	NetworkRegisterEntityAsNetworked(trainVeh)
	SetNetworkIdExistsOnAllMachines(VehToNet(trainVeh), true)
	NetworkRegisterEntityAsNetworked(trainDriverHandle)
	SetNetworkIdExistsOnAllMachines(PedToNet(trainDriverHandle), true)

	TriggerServerEvent("BGS_Trains:server:StoreNetIndex", VehToNet(trainVeh), PedToNet(trainDriverHandle), trainArea)

end

-- Prevent people from knocking driver out of train
local function ProtectTrainDriver(trainDriverHandle)
	if trainDriverHandle then
		SetPedCanBeKnockedOffVehicle(trainDriverHandle, 1)
		SetEntityInvincible(trainDriverHandle, true)
		SetBlockingOfNonTemporaryEvents(trainDriverHandle, true)
		SetEntityAsMissionEntity(trainDriverHandle, true, true)
		SetEntityCanBeDamaged(trainDriverHandle, false)
		CreateThread(function()
			while true and trainDriverHandle ~= tramConductor do
				Wait(1)
				if #(GetEntityCoords(trainDriverHandle) - GetEntityCoords(PlayerPedId())) < 12.5 then
					Citizen.InvokeNative(0xFC094EF26DD153FA, 12)
				end
			end
		end)
	end
end

-- Spawn trains if able, if unable then store train variables from server and render blips for existing trains
RegisterNetEvent("vorp:SelectedCharacter", function()
	TriggerServerEvent("BGS_Trains:server:CanSpawnTrain")
	Wait(100)
	if canSpawn then
		if Config.UseEastTrain then
			if Config.UseChristmasTrainEast then
				TrainCreateVehicle(christmasTrainHash, Config.EastTrainSpawnLocation, "east")
			else
				TrainCreateVehicle(Config.EastTrain, Config.EastTrainSpawnLocation, "east")
			end
		end
		if Config.UseWestTrain then
			if Config.UseChristmasTrainWest then
				TrainCreateVehicle(christmasTrainHash, Config.WestTrainSpawnLocation, "west")
			else
				TrainCreateVehicle(Config.WestTrain, Config.WestTrainSpawnLocation, "west")
			end
		end
		if Config.UseTram then
			TrainCreateVehicle(Config.Trolley, Config.TramSpawnLocation)
		end
		if Config.UseChristmasTrainEast or Config.UseChristmasTrainWest then
			HandleChristmasTrains()
		end
		Wait(1000)
		TriggerServerEvent("BGS_Trains:server:GetTrainsFromServer")
		Wait(1000)
		RenderTrainBlips()
	else
		TriggerServerEvent("BGS_Trains:server:GetTrainsFromServer")
		Wait(1000)
		RenderTrainBlips()
	end
end)

-- Determine if player can spawn first trains or not
RegisterNetEvent("BGS_Trains:client:CanSpawnTrain", function(canSpawnTrains)
	canSpawn = canSpawnTrains
end)

-- Get net indexes for train values from server, convert and store
RegisterNetEvent("BGS_Trains:client:GetTrainsFromServer", function (eastNet, westNet, tramNet, eastConductorNet, westConductorNet, tramConductorNet)
	eastTrain = NetToVeh(eastNet)
	eastConductor = NetToPed(eastConductorNet)
	westTrain = NetToVeh(westNet)
	westConductor = NetToPed(westConductorNet)
	tram = NetToVeh(tramNet)
	tramConductor = NetToPed(tramConductorNet)
	if eastConductor then
		ProtectTrainDriver(eastConductor)
	end
	if westConductor then
		ProtectTrainDriver(eastConductor)
	end
	if tramConductor then
		ProtectTrainDriver(tramConductor)
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
			if not Config.RandomizeWestJunctions then
				for i = 1, #Config.WestJunctions do
					if GetDistanceBetweenCoords(GetEntityCoords(westTrain), Config.WestJunctions[i].coords) < 25 then
						Citizen.InvokeNative(0xE6C5E2125EB210C1, Config.WestJunctions[i].trainTrack, Config.WestJunctions[i].junctionIndex, Config.WestJunctions[i].enabled)
						Citizen.InvokeNative(0x3ABFA128F5BF5A70, Config.WestJunctions[i].trainTrack, Config.WestJunctions[i].junctionIndex, Config.WestJunctions[i].enabled)
					end
				end
			end
			if Citizen.InvokeNative(0xE887BD31D97793F6, westTrain) then
				Citizen.InvokeNative(0x3660BCAB3A6BB734, westTrain)
				Wait(Config.StationWaitTime*1000)
				Citizen.InvokeNative(0x787E43477746876F, westTrain)
			end
			for index, stop in ipairs(Config.CustomStops) do
				if GetDistanceBetweenCoords(stop.coords, GetEntityCoords(westTrain)) < 15 and not stopped then
					Citizen.InvokeNative(0x3660BCAB3A6BB734, westTrain)
					Wait(Config.StationWaitTime*1000)
					Citizen.InvokeNative(0x787E43477746876F, westTrain)
					stopped = true
				end
				if GetDistanceBetweenCoords(stop.coords, GetEntityCoords(westTrain)) > 15 then
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
			if not Config.RandomizeEastJunctions then
				for i = 1, #Config.EastJunctions do
					if GetDistanceBetweenCoords(GetEntityCoords(eastTrain), Config.EastJunctions[i].coords) < 15 then
						if Config.EastJunctions[i].trainTrack == -705539859 and Config.EastJunctions[i].junctionIndex == 2 then
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

-- Handle "luxury train" shit
-- if Config.UseFancyTrainEast then
-- 	CreateThread(function()
-- 		local deleted = false
-- 		local attached = false
-- 		local spawned = false
-- 		local propset
-- 		local propset2
-- 		local propsetHash
-- 		local propsetHash2

-- 		while true do
-- 			Wait(1000)
-- 			if eastTrain then

-- 				local carriage = Citizen.InvokeNative(0xD0FB093A4CDB932C, eastTrain, 3)
-- 				local carriage2 = Citizen.InvokeNative(0xD0FB093A4CDB932C, eastTrain, 4)
-- 				local carriage3 = Citizen.InvokeNative(0xD0FB093A4CDB932C, eastTrain, 6)
-- 				local carriage4 = Citizen.InvokeNative(0xD0FB093A4CDB932C, eastTrain, 5)

-- 				if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(carriage4)) < 150 and not Config.UseNetwork then
-- 					propset = Citizen.InvokeNative(0xCFC0BD09BB1B73FF, carriage)
-- 					propsetHash = Citizen.InvokeNative(0xA6A9712955F53D9C, propset)

-- 					propset2 = Citizen.InvokeNative(0xCFC0BD09BB1B73FF, carriage2)
-- 					propsetHash2 = Citizen.InvokeNative(0xA6A9712955F53D9C, propset2)

-- 					if Citizen.InvokeNative(0xF42DB680A8B2A4D9, propset) and (Citizen.InvokeNative(0xF42DB680A8B2A4D9, propset2)) and not deleted then
-- 						while not (Citizen.InvokeNative(0x48A88FC684C55FDC, propsetHash) and Citizen.InvokeNative(0x48A88FC684C55FDC, propsetHash2)) do
-- 							Wait(1)
-- 						end
-- 						Citizen.InvokeNative(0x3BCF32FF37EA9F1D, carriage)
-- 						Citizen.InvokeNative(0x3BCF32FF37EA9F1D, carriage2)
-- 						deleted = true
-- 					end

-- 					if not attached then

-- 						local request = Citizen.InvokeNative(0xF3DE57A46D5585E9, barPropsHash)
-- 						local request2 = Citizen.InvokeNative(0xF3DE57A46D5585E9, sleeperPropsHash)

-- 						while not Citizen.InvokeNative(0x48A88FC684C55FDC, barPropsHash) do
-- 							Wait(1)
-- 						end

-- 						while not Citizen.InvokeNative(0x48A88FC684C55FDC, sleeperPropsHash) do
-- 							Wait(1)
-- 						end

-- 						local barPropsetOnTrain = Citizen.InvokeNative(0x9609DBDDE18FAD8C, barPropsHash, 0, 0, 0, carriage, 0, true, 0, true)
-- 						local sleeperPropsetOnTrain = Citizen.InvokeNative(0x9609DBDDE18FAD8C, sleeperPropsHash, 0, 0, 0, carriage2, 0, true, 0, true)

-- 						attached = true
-- 					end

-- 					if not spawned and Config.UseEastTrainBartender then
-- 						local coords = GetEntityCoords(carriage)

-- 						local scenario_type_hash = joaat("WORLD_HUMAN_BARTENDER_CLEAN_GLASS")
-- 						local scenario_duration = -1  -- (1000 = 1 second, -1 = forever)
-- 						local must_play_enter_anim = true
-- 						local optional_conditional_anim_hash = joaat("WORLD_HUMAN_BARTENDER_CLEAN_GLASS_MALE_B")  -- 0 = play random conditional anim. Every conditional anim has requirements to play it. If requirements are not met, ped plays random allowed conditional anim or can be stuck. For example, this scenario type have possible conditional anim "WORLD_HUMAN_LEAN_BACK_WALL_SMOKING_MALE_D", but it can not be played by player, because condition is set to NOT be CAIConditionIsPlayer (check file amb_rest.meta and amb_rest_CA.meta with OPENIV to clarify requirements). 
-- 						local unknown_5 = -1.0
-- 						local unknown_6 = 0

-- 						eastTrainBartender = CreatePed(518339740, coords.x+0.85, coords.y+1.25, coords.z+0.5, GetEntityHeading(carriage), true, false, false, false)
-- 						SetPedRandomComponentVariation(eastTrainBartender, 0)
-- 						Citizen.InvokeNative(0xA5C38736C426FCB8, eastTrainBartender, true)
-- 						Citizen.InvokeNative(0x9F8AA94D6D97DBF4, eastTrainBartender, true)
-- 						Citizen.InvokeNative(0x63F58F7C80513AAD, eastTrainBartender, false)
-- 						Citizen.InvokeNative(0x7A6535691B477C48, eastTrainBartender, false)
-- 						SetBlockingOfNonTemporaryEvents(eastTrainBartender, true)
-- 						SetEntityAsMissionEntity(eastTrainBartender, true, true)
-- 						SetEntityCanBeDamaged(eastTrainBartender, false)

-- 						if Config.UseNetwork then
-- 							NetworkRegisterEntityAsNetworked(eastTrainBartender)
-- 						end

-- 						Citizen.InvokeNative(0x524B54361229154F, eastTrainBartender, scenario_type_hash, scenario_duration, must_play_enter_anim, optional_conditional_anim_hash, unknown_5, unknown_6)
-- 						spawned = true
-- 						TriggerServerEvent("BGS_Trains:StoreServerTrainEast", eastTrain, eastTrainBartender)
-- 					end

-- 					Citizen.InvokeNative(0xB1964A83B345B4AB, barPropsHash)
-- 					Citizen.InvokeNative(0xB1964A83B345B4AB, sleeperPropsHash)

-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 9, true, true)			-- Open fancy cabin doors
-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 10, true, true)			-- Open fancy cabin doors
-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 11, true, true)			-- Open fancy cabin doors

-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 9, true, true)			-- Open fancy cabin doors
-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 10, true, true)			-- Open fancy cabin doors
-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 11, true, true)			-- Open fancy cabin doors

-- 				elseif Config.UseNetwork then
-- 					propset = Citizen.InvokeNative(0xCFC0BD09BB1B73FF, carriage)
-- 					propsetHash = Citizen.InvokeNative(0xA6A9712955F53D9C, propset)

-- 					propset2 = Citizen.InvokeNative(0xCFC0BD09BB1B73FF, carriage2)
-- 					propsetHash2 = Citizen.InvokeNative(0xA6A9712955F53D9C, propset2)

-- 					if Citizen.InvokeNative(0xF42DB680A8B2A4D9, propset) and (Citizen.InvokeNative(0xF42DB680A8B2A4D9, propset2)) and not deleted then
-- 						while not (Citizen.InvokeNative(0x48A88FC684C55FDC, propsetHash) and Citizen.InvokeNative(0x48A88FC684C55FDC, propsetHash2)) do
-- 							Wait(1)
-- 						end
-- 						Citizen.InvokeNative(0x3BCF32FF37EA9F1D, carriage)
-- 						Citizen.InvokeNative(0x3BCF32FF37EA9F1D, carriage2)
-- 						deleted = true
-- 					end

-- 					if not attached then

-- 						local request = Citizen.InvokeNative(0xF3DE57A46D5585E9, barPropsHash)
-- 						local request2 = Citizen.InvokeNative(0xF3DE57A46D5585E9, sleeperPropsHash)

-- 						while not Citizen.InvokeNative(0x48A88FC684C55FDC, barPropsHash) do
-- 							Wait(1)
-- 						end

-- 						while not Citizen.InvokeNative(0x48A88FC684C55FDC, sleeperPropsHash) do
-- 							Wait(1)
-- 						end

-- 						local barPropsetOnTrain = Citizen.InvokeNative(0x9609DBDDE18FAD8C, barPropsHash, 0, 0, 0, carriage, 0, true, 0, true)
-- 						local sleeperPropsetOnTrain = Citizen.InvokeNative(0x9609DBDDE18FAD8C, sleeperPropsHash, 0, 0, 0, carriage2, 0, true, 0, true)

-- 						attached = true
-- 					end

-- 					if not spawned and Config.UseEastTrainBartender then
-- 						local coords = GetEntityCoords(carriage)

-- 						local scenario_type_hash = joaat("WORLD_HUMAN_BARTENDER_CLEAN_GLASS")
-- 						local scenario_duration = -1  -- (1000 = 1 second, -1 = forever)
-- 						local must_play_enter_anim = true
-- 						local optional_conditional_anim_hash = joaat("WORLD_HUMAN_BARTENDER_CLEAN_GLASS_MALE_B")  -- 0 = play random conditional anim. Every conditional anim has requirements to play it. If requirements are not met, ped plays random allowed conditional anim or can be stuck. For example, this scenario type have possible conditional anim "WORLD_HUMAN_LEAN_BACK_WALL_SMOKING_MALE_D", but it can not be played by player, because condition is set to NOT be CAIConditionIsPlayer (check file amb_rest.meta and amb_rest_CA.meta with OPENIV to clarify requirements). 
-- 						local unknown_5 = -1.0
-- 						local unknown_6 = 0

-- 						eastTrainBartender = CreatePed(518339740, coords.x+0.85, coords.y+1.25, coords.z+0.5, GetEntityHeading(carriage), true, false, false, false)
-- 						SetPedRandomComponentVariation(eastTrainBartender, 0)
-- 						Citizen.InvokeNative(0xA5C38736C426FCB8, eastTrainBartender, true)
-- 						Citizen.InvokeNative(0x9F8AA94D6D97DBF4, eastTrainBartender, true)
-- 						Citizen.InvokeNative(0x63F58F7C80513AAD, eastTrainBartender, false)
-- 						Citizen.InvokeNative(0x7A6535691B477C48, eastTrainBartender, false)
-- 						SetBlockingOfNonTemporaryEvents(eastTrainBartender, true)
-- 						SetEntityAsMissionEntity(eastTrainBartender, true, true)
-- 						SetEntityCanBeDamaged(eastTrainBartender, false)

-- 						if Config.UseNetwork then
-- 							NetworkRegisterEntityAsNetworked(eastTrainBartender)
-- 						end

-- 						Citizen.InvokeNative(0x524B54361229154F, eastTrainBartender, scenario_type_hash, scenario_duration, must_play_enter_anim, optional_conditional_anim_hash, unknown_5, unknown_6)
-- 						spawned = true
-- 						TriggerServerEvent("BGS_Trains:StoreServerTrainEast", eastTrain, eastTrainBartender)
-- 					end

-- 					Citizen.InvokeNative(0xB1964A83B345B4AB, barPropsHash)
-- 					Citizen.InvokeNative(0xB1964A83B345B4AB, sleeperPropsHash)

-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 9, true, true)			-- Open fancy cabin doors
-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 10, true, true)			-- Open fancy cabin doors
-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 11, true, true)			-- Open fancy cabin doors

-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 9, true, true)			-- Open fancy cabin doors
-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 10, true, true)			-- Open fancy cabin doors
-- 					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 11, true, true)			-- Open fancy cabin doors
					
-- 				end
				
-- 			end
-- 		end
-- 	end)
-- end