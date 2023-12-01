-- various globals
local westTrain = false
local eastTrain = false
local tram = false
local westBlipRendered = false
local eastBlipRendered = false
local eastTrainDriver = nil
local westTrainDriver = nil
local eastTrainBartender = nil
local westTrainBartender = nil
local tramDriver = nil
local Trains = {}
local TrainModels = {
    'northsteamer01x'
}
local christmasTrainHash = 0x124A1F89
local barPropsHash = -1747631964
local sleeperPropsHash = -317994478
local object

-- Check for server stored train variables
RegisterNetEvent("BGS_Trains:GetServerTrains")
AddEventHandler("BGS_Trains:GetServerTrains", function(serverEastTrain, serverWestTrain, serverTram)
	eastTrain = serverEastTrain
	westTrain = serverWestTrain
	tram = serverTram
end)

-- Render train blips
function RenderTrainBlip(vehicle, line)
	local TrainBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 1664425300, vehicle)
	SetBlipSprite(TrainBlip, -250506368)
	if line == "east" then
		eastBlipRendered = true
		Citizen.InvokeNative(0x9CB1A1623062F402, TrainBlip, Config.EastTrainBlipName)
	else
		westBlipRendered = true
		Citizen.InvokeNative(0x9CB1A1623062F402, TrainBlip, Config.WestTrainBlipName)
	end
	SetBlipScale(TrainBlip, 1.0)
end

-- Create west train line
local function WestTrainCreateVehicle(trainModel, loc, speed)
	local trainWagons = N_0x635423d55ca84fc8(trainModel)

	for i = 0, trainWagons - 1 do
		local trainWagonModel = N_0x8df5f6a19f99f0d5(trainModel, i)
		RequestModel(trainWagonModel)
		while not HasModelLoaded(trainWagonModel) do
			Citizen.Wait(0)
		end
	end

	westTrain = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, loc.x, loc.y, loc.z, false, Config.EnablePassengers, true, true)
	SetTrainSpeed(westTrain, speed)
	SetTrainCruiseSpeed(westTrain, speed)
	Citizen.InvokeNative(0x9F29999DFDF2AEB8, westTrain, speed)
	Citizen.InvokeNative(0x4182C037AA1F0091, westTrain, true) 					-- Set train stops for stations
	Citizen.InvokeNative(0x8EC47DD4300BF063, westTrain, 30.0) 					-- Set train offset for station

	RenderTrainBlip(westTrain, "west")

	local trainDriverHandle = GetPedInVehicleSeat(westTrain, -1)
	while not DoesEntityExist(trainDriverHandle) do
		trainDriverHandle = GetPedInVehicleSeat(westTrain, -1)
		SetEntityAsMissionEntity(trainDriverHandle, true, true)
		Citizen.Wait(1)
	end

	westTrainDriver = trainDriverHandle

	-- Make driver invincible
	Citizen.InvokeNative(0xA5C38736C426FCB8, trainDriverHandle, true)
	Citizen.InvokeNative(0x9F8AA94D6D97DBF4, trainDriverHandle, true)
	Citizen.InvokeNative(0x63F58F7C80513AAD, trainDriverHandle, false)
	Citizen.InvokeNative(0x7A6535691B477C48, trainDriverHandle, false)
	SetBlockingOfNonTemporaryEvents(trainDriverHandle, true)
	Citizen.InvokeNative(0x05254BA0B44ADC16, westTrain, false)
	SetEntityAsMissionEntity(trainDriverHandle, true, true)
	SetEntityCanBeDamaged(trainDriverHandle, false)

	-- Network the train and driver
	if Config.UseNetwork then
		NetworkRegisterEntityAsNetworked(westTrain)
		NetworkRegisterEntityAsNetworked(trainDriverHandle)
	end

end

-- Create east train line
local function EastTrainCreateVehicle(trainModel, loc, speed)
	local trainWagons = N_0x635423d55ca84fc8(trainModel)

	for i = 0, trainWagons - 1 do
		local trainWagonModel = N_0x8df5f6a19f99f0d5(trainModel, i)
		RequestModel(trainWagonModel)
		while not HasModelLoaded(trainWagonModel) do
			Citizen.Wait(0)
		end
	end

	eastTrain = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, loc.x, loc.y, loc.z, false, Config.EnablePassengers, true, true)
	SetTrainSpeed(eastTrain, speed)
	SetTrainCruiseSpeed(eastTrain, speed)
	Citizen.InvokeNative(0x9F29999DFDF2AEB8, eastTrain, speed)
	Citizen.InvokeNative(0x4182C037AA1F0091, eastTrain, true) 					-- Set train stops for stations
	Citizen.InvokeNative(0x8EC47DD4300BF063, eastTrain, 0.0) 					-- Set train offset for station

	RenderTrainBlip(eastTrain, "east")

	local trainDriverHandle = GetPedInVehicleSeat(eastTrain, -1)
	while not DoesEntityExist(trainDriverHandle) do
		trainDriverHandle = GetPedInVehicleSeat(eastTrain, -1)
		SetEntityAsMissionEntity(trainDriverHandle, true, true)
		Citizen.Wait(1)
	end

	eastTrainDriver = trainDriverHandle

	-- Make driver invincible
	Citizen.InvokeNative(0xA5C38736C426FCB8, trainDriverHandle, true)
	Citizen.InvokeNative(0x9F8AA94D6D97DBF4, trainDriverHandle, true)
	Citizen.InvokeNative(0x63F58F7C80513AAD, trainDriverHandle, false)
	Citizen.InvokeNative(0x7A6535691B477C48, trainDriverHandle, false)
	SetBlockingOfNonTemporaryEvents(trainDriverHandle, true)
	Citizen.InvokeNative(0x05254BA0B44ADC16, eastTrain, false)
	SetEntityAsMissionEntity(trainDriverHandle, true, true)
	SetEntityCanBeDamaged(trainDriverHandle, false)

	-- Network the train and driver
	if Config.UseNetwork then
		NetworkRegisterEntityAsNetworked(eastTrain)
		NetworkRegisterEntityAsNetworked(trainDriverHandle)
	end

end

-- Create tram
local function TramCreateVehicle(trainModel, loc)
	local trainWagons = N_0x635423d55ca84fc8(trainModel)

	for i = 0, trainWagons - 1 do
		local trainWagonModel = N_0x8df5f6a19f99f0d5(trainModel, i)
		RequestModel(trainWagonModel)
		while not HasModelLoaded(trainWagonModel) do
			Citizen.Wait(0)
		end
	end

	tram = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, loc, true, Config.EnablePassengers, true, true)
	SetTrainSpeed(tram, 2.0)
	Citizen.InvokeNative(0x4182C037AA1F0091, tram, true) 					-- Set train stops for stations
	Citizen.InvokeNative(0x8EC47DD4300BF063, tram, 0.0) 					-- Set train offset for station

	local trainDriverHandle = GetPedInVehicleSeat(tram, -1)
	while not DoesEntityExist(trainDriverHandle) do
		trainDriverHandle = GetPedInVehicleSeat(tram, -1)
		Citizen.Wait(1)
	end

	tramDriver = trainDriverHandle

	-- Make driver invincible
	SetEntityAsMissionEntity(trainDriverHandle, true, true)
	SetEntityCanBeDamaged(trainDriverHandle, false)
	SetEntityInvincible(trainDriverHandle, true)
	FreezeEntityPosition(trainDriverHandle, true)
	SetBlockingOfNonTemporaryEvents(trainDriverHandle, true)

	-- Network the train and driver
	if Config.UseNetwork then
		NetworkRegisterEntityAsNetworked(tram)
		NetworkRegisterEntityAsNetworked(trainDriverHandle)
	end

end

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

local function DecorateTrain(vehicle)
    object = CreateObjectNoOffset(GetHashKey('mp006_p_veh_xmasnsteamer01x'), 0, 0, 0, false, false, false, false)
    AttachEntityToEntity(object, vehicle, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true, false, false)
    return object
end

-- Spawn and store trains server side
if not Config.Debug then
	RegisterNetEvent("vorp:SelectedCharacter", function()
		CreateThread(function ()
			TriggerServerEvent("BGS_Trains:ReturnServerTrains", true)
			while true do
				Wait(1000)
				if Config.UseEastTrain and not eastTrain then
					if Config.UseNetwork then
						if Config.UseChristmasTrainEast then
							EastTrainCreateVehicle(christmasTrainHash, Config.eastLoc, Config.EastTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainEast", eastTrain)
						elseif Config.UseFancyTrainEast and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), Config.eastLoc) < 150 then
							EastTrainCreateVehicle(0xCD2C7CA1, Config.eastLoc, Config.EastTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainEast", eastTrain, eastTrainBartender)
						else
							EastTrainCreateVehicle(Config.EastTrain, Config.eastLoc, Config.EastTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainEast", eastTrain)
						end
					elseif GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), Config.eastLoc) < 150 then
						if Config.UseChristmasTrainEast then
							EastTrainCreateVehicle(christmasTrainHash, Config.eastLoc, Config.EastTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainEast", eastTrain)
						elseif Config.UseFancyTrainEast then
							EastTrainCreateVehicle(0xCD2C7CA1, Config.eastLoc, Config.EastTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainEast", eastTrain, eastTrainBartender)
						else
							EastTrainCreateVehicle(Config.EastTrain, Config.eastLoc, Config.EastTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainEast", eastTrain)
						end
						TriggerServerEvent("BGS_Trains:UpdateTrainsAllPlayers")
					end
				end
				if Config.UseWestTrain and not westTrain then
					if Config.UseNetwork then
						if Config.UseChristmasTrainWest then
							WestTrainCreateVehicle(christmasTrainHash, Config.westLoc, Config.WestTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainWest", westTrain)
						elseif Config.UseFancyTrainWest and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), Config.westLoc) < 150 then
							WestTrainCreateVehicle(0xCD2C7CA1, Config.westLoc, Config.WestTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainWest", westTrain, westTrainBartender)
						else
							WestTrainCreateVehicle(Config.WestTrain, Config.westLoc, Config.WestTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainWest", westTrain)
						end
					elseif GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), Config.westLoc) < 150 then
						if Config.UseChristmasTrainWest then
							WestTrainCreateVehicle(christmasTrainHash, Config.westLoc, Config.WestTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainWest", westTrain)
						elseif Config.UseFancyTrainWest then
							WestTrainCreateVehicle(0xCD2C7CA1, Config.westLoc, Config.WestTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainWest", westTrain, westTrainBartender)
						else
							WestTrainCreateVehicle(Config.WestTrain, Config.westLoc, Config.WestTrainMaxSpeed)
							TriggerServerEvent("BGS_Trains:StoreServerTrainWest", westTrain)
						end
						TriggerServerEvent("BGS_Trains:UpdateTrainsAllPlayers")
					end
				end
				if Config.UseTrams and not tram then
					if Config.UseNetwork then
						TramCreateVehicle(Config.Trolley, Config.tramLoc)
						TriggerServerEvent("BGS_Trains:StoreServerTram", tram)
					elseif GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), Config.tramLoc) < 150 then
						TramCreateVehicle(Config.Trolley, Config.tramLoc)
						TriggerServerEvent("BGS_Trains:StoreServerTram", tram)
						TriggerServerEvent("BGS_Trains:UpdateTrainsAllPlayers")
					end
				end
			end
		end)
	end)
end

-- Function for randomizing the junctions
function RandomizeJunctionsEnabled(junctionsList)
    if Config.UseRandomJunctions then  -- Check whether randomization is activated
        for _, junction in ipairs(junctionsList) do
            local NullOne = math.random(1, 100)
            if NullOne > 50 then
                junction.enabled = 0
            else
                junction.enabled = 1
            end
        end
    end
end

-- Main thread that checks whether junctions should be randomized
CreateThread(function()
    -- End this thread immediately if randomization is not activated
    if not Config.UseRandomJunctions then
        return
    end

    while true do
        Wait(Config.RandomJunctionstime)  -- Wait for the specified time

        -- Check which junctions are to be randomized
        if Config.RandomizeWestJunctions then
            RandomizeJunctionsEnabled(Config.WestJunctions)
        end
        if Config.RandomizeEastJunctions then
            RandomizeJunctionsEnabled(Config.EastJunctions)
        end
        if Config.RandomizeTramJunctions then
            RandomizeJunctionsEnabled(Config.RouteOneTramSwitches)
        end
    end
end)

-- Handle west train shit
CreateThread(function()
	local stopped = false
	while true do
		Wait(500)
		if westTrain and not Config.RandomizeWestJunctions then
			if not westBlipRendered then
				RenderTrainBlip(westTrain, "west")
			end
			for i = 1, #Config.WestJunctions do
				if GetDistanceBetweenCoords(GetEntityCoords(westTrain), Config.WestJunctions[i].coords) < 25 then
					Citizen.InvokeNative(0xE6C5E2125EB210C1, Config.WestJunctions[i].trainTrack, Config.WestJunctions[i].junctionIndex, Config.WestJunctions[i].enabled)
					Citizen.InvokeNative(0x3ABFA128F5BF5A70, Config.WestJunctions[i].trainTrack, Config.WestJunctions[i].junctionIndex, Config.WestJunctions[i].enabled)
				end
			end
			if Citizen.InvokeNative(0xE887BD31D97793F6, westTrain) then
				Citizen.InvokeNative(0x3660BCAB3A6BB734, westTrain)
				Wait(Config.WestTrainStationWait*1000)
				Citizen.InvokeNative(0x787E43477746876F, westTrain)
			end
			for index, stop in ipairs(Config.CustomStops) do
				if GetDistanceBetweenCoords(stop.coords, GetEntityCoords(westTrain)) < 15 and not stopped then
					Citizen.InvokeNative(0x3660BCAB3A6BB734, westTrain)
					Wait(Config.WestTrainStationWait*1000)
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
	local stopped = false
	while true do
		Wait(500)
		if eastTrain and not Config.RandomizeEastJunctions then
			if not eastBlipRendered then
				RenderTrainBlip(eastTrain, "east")
			end
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
			if Citizen.InvokeNative(0xE887BD31D97793F6, eastTrain) then
				Citizen.InvokeNative(0x3660BCAB3A6BB734, eastTrain)
				Wait(Config.EastTrainStationWait*1000)
				Citizen.InvokeNative(0x787E43477746876F, eastTrain)
			end
			for index, stop in ipairs(Config.CustomStops) do
				if GetDistanceBetweenCoords(stop.coords, GetEntityCoords(eastTrain)) < 15 and not stopped then
					Citizen.InvokeNative(0x3660BCAB3A6BB734, eastTrain)
					Wait(Config.EastTrainStationWait*1000)
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

-- Prevent people from knocking driver out of trains
CreateThread(function()
	while true do
		Wait(1)
		if westTrainDriver then
			if GetDistanceBetweenCoords(GetEntityCoords(westTrainDriver), GetEntityCoords(PlayerPedId())) < 12.5 then
				Citizen.InvokeNative(0xFC094EF26DD153FA,12)
			end
		end
		if eastTrainDriver then
			if GetDistanceBetweenCoords(GetEntityCoords(eastTrainDriver), GetEntityCoords(PlayerPedId())) < 12.5 then
				Citizen.InvokeNative(0xFC094EF26DD153FA,12)
			end
		end
	end
end)

-- Handle tram shit
CreateThread(function()
	while true do
		Wait(250)
		if tram and not Config.RandomizeTramJunctions then
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

-- Handle Christmas train shit
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

-- Handle "luxury train" shit
if Config.UseFancyTrainEast then
	CreateThread(function()
		local deleted = false
		local attached = false
		local spawned = false
		local propset
		local propset2
		local propsetHash
		local propsetHash2

		while true do
			Wait(1000)
			if eastTrain then

				local carriage = Citizen.InvokeNative(0xD0FB093A4CDB932C, eastTrain, 3)
				local carriage2 = Citizen.InvokeNative(0xD0FB093A4CDB932C, eastTrain, 4)
				local carriage3 = Citizen.InvokeNative(0xD0FB093A4CDB932C, eastTrain, 6)
				local carriage4 = Citizen.InvokeNative(0xD0FB093A4CDB932C, eastTrain, 5)

				if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(carriage4)) < 150 then
					propset = Citizen.InvokeNative(0xCFC0BD09BB1B73FF, carriage)
					propsetHash = Citizen.InvokeNative(0xA6A9712955F53D9C, propset)

					propset2 = Citizen.InvokeNative(0xCFC0BD09BB1B73FF, carriage2)
					propsetHash2 = Citizen.InvokeNative(0xA6A9712955F53D9C, propset2)

					if Citizen.InvokeNative(0xF42DB680A8B2A4D9, propset) and (Citizen.InvokeNative(0xF42DB680A8B2A4D9, propset2)) and not deleted then
						while not (Citizen.InvokeNative(0x48A88FC684C55FDC, propsetHash) and Citizen.InvokeNative(0x48A88FC684C55FDC, propsetHash2)) do
							Wait(1)
						end
						Citizen.InvokeNative(0x3BCF32FF37EA9F1D, carriage)
						Citizen.InvokeNative(0x3BCF32FF37EA9F1D, carriage2)
						deleted = true
					end

					if not attached then

						local request = Citizen.InvokeNative(0xF3DE57A46D5585E9, barPropsHash)
						local request2 = Citizen.InvokeNative(0xF3DE57A46D5585E9, sleeperPropsHash)

						while not Citizen.InvokeNative(0x48A88FC684C55FDC, barPropsHash) do
							Wait(1)
						end

						while not Citizen.InvokeNative(0x48A88FC684C55FDC, sleeperPropsHash) do
							Wait(1)
						end

						local barPropsetOnTrain = Citizen.InvokeNative(0x9609DBDDE18FAD8C, barPropsHash, 0, 0, 0, carriage, 0, true, 0, true)
						local sleeperPropsetOnTrain = Citizen.InvokeNative(0x9609DBDDE18FAD8C, sleeperPropsHash, 0, 0, 0, carriage2, 0, true, 0, true)

						attached = true
					end

					if not spawned then
						local coords = GetEntityCoords(carriage)
	
						local scenario_type_hash = joaat("WORLD_HUMAN_BARTENDER_CLEAN_GLASS")
						local scenario_duration = -1  -- (1000 = 1 second, -1 = forever)
						local must_play_enter_anim = true
						local optional_conditional_anim_hash = joaat("WORLD_HUMAN_BARTENDER_CLEAN_GLASS_MALE_B")  -- 0 = play random conditional anim. Every conditional anim has requirements to play it. If requirements are not met, ped plays random allowed conditional anim or can be stuck. For example, this scenario type have possible conditional anim "WORLD_HUMAN_LEAN_BACK_WALL_SMOKING_MALE_D", but it can not be played by player, because condition is set to NOT be CAIConditionIsPlayer (check file amb_rest.meta and amb_rest_CA.meta with OPENIV to clarify requirements). 
						local unknown_5 = -1.0
						local unknown_6 = 0
	
						eastTrainBartender = CreatePed(518339740, coords.x+0.85, coords.y+1.25, coords.z+0.5, GetEntityHeading(carriage), true, false, false, false)
						SetPedRandomComponentVariation(eastTrainBartender, 0)
						Citizen.InvokeNative(0xA5C38736C426FCB8, eastTrainBartender, true)
						Citizen.InvokeNative(0x9F8AA94D6D97DBF4, eastTrainBartender, true)
						Citizen.InvokeNative(0x63F58F7C80513AAD, eastTrainBartender, false)
						Citizen.InvokeNative(0x7A6535691B477C48, eastTrainBartender, false)
						SetBlockingOfNonTemporaryEvents(eastTrainBartender, true)
						SetEntityAsMissionEntity(eastTrainBartender, true, true)
						SetEntityCanBeDamaged(eastTrainBartender, false)
	
						Citizen.InvokeNative(0x524B54361229154F, eastTrainBartender, scenario_type_hash, scenario_duration, must_play_enter_anim, optional_conditional_anim_hash, unknown_5, unknown_6)
						spawned = true
					end

					Citizen.InvokeNative(0xB1964A83B345B4AB, barPropsHash)
					Citizen.InvokeNative(0xB1964A83B345B4AB, sleeperPropsHash)

					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 9, true, true)			-- Open fancy cabin doors
					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 10, true, true)			-- Open fancy cabin doors
					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 11, true, true)			-- Open fancy cabin doors

					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 9, true, true)			-- Open fancy cabin doors
					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 10, true, true)			-- Open fancy cabin doors
					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 11, true, true)			-- Open fancy cabin doors

				else
					attached = false
				end
				
			end
		end
	end)
end

if Config.UseFancyTrainWest then
	CreateThread(function()
		local deleted = false
		local attached = false
		local spawned = false
		local propset
		local propset2
		local propsetHash
		local propsetHash2

		while true do
			Wait(1000)
			if westTrain then

				local carriage = Citizen.InvokeNative(0xD0FB093A4CDB932C, westTrain, 3)
				local carriage2 = Citizen.InvokeNative(0xD0FB093A4CDB932C, westTrain, 4)
				local carriage3 = Citizen.InvokeNative(0xD0FB093A4CDB932C, westTrain, 6)
				local carriage4 = Citizen.InvokeNative(0xD0FB093A4CDB932C, westTrain, 5)

				if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(carriage4)) < 150 then
					propset = Citizen.InvokeNative(0xCFC0BD09BB1B73FF, carriage)
					propsetHash = Citizen.InvokeNative(0xA6A9712955F53D9C, propset)

					propset2 = Citizen.InvokeNative(0xCFC0BD09BB1B73FF, carriage2)
					propsetHash2 = Citizen.InvokeNative(0xA6A9712955F53D9C, propset2)

					if Citizen.InvokeNative(0xF42DB680A8B2A4D9, propset) and (Citizen.InvokeNative(0xF42DB680A8B2A4D9, propset2)) and not deleted then
						while not (Citizen.InvokeNative(0x48A88FC684C55FDC, propsetHash) and Citizen.InvokeNative(0x48A88FC684C55FDC, propsetHash2)) do
							Wait(1)
						end
						Citizen.InvokeNative(0x3BCF32FF37EA9F1D, carriage)
						Citizen.InvokeNative(0x3BCF32FF37EA9F1D, carriage2)
						deleted = true
					end

					if not attached then

						local request = Citizen.InvokeNative(0xF3DE57A46D5585E9, barPropsHash)
						local request2 = Citizen.InvokeNative(0xF3DE57A46D5585E9, sleeperPropsHash)

						while not Citizen.InvokeNative(0x48A88FC684C55FDC, barPropsHash) do
							Wait(1)
						end

						while not Citizen.InvokeNative(0x48A88FC684C55FDC, sleeperPropsHash) do
							Wait(1)
						end

						local barPropsetOnTrain = Citizen.InvokeNative(0x9609DBDDE18FAD8C, barPropsHash, 0, 0, 0, carriage, 0, true, 0, true)
						local sleeperPropsetOnTrain = Citizen.InvokeNative(0x9609DBDDE18FAD8C, sleeperPropsHash, 0, 0, 0, carriage2, 0, true, 0, true)

						attached = true
					end

					if not spawned then
						local coords = GetEntityCoords(carriage)
	
						local scenario_type_hash = joaat("WORLD_HUMAN_BARTENDER_CLEAN_GLASS")
						local scenario_duration = -1  -- (1000 = 1 second, -1 = forever)
						local must_play_enter_anim = true
						local optional_conditional_anim_hash = joaat("WORLD_HUMAN_BARTENDER_CLEAN_GLASS_MALE_B")  -- 0 = play random conditional anim. Every conditional anim has requirements to play it. If requirements are not met, ped plays random allowed conditional anim or can be stuck. For example, this scenario type have possible conditional anim "WORLD_HUMAN_LEAN_BACK_WALL_SMOKING_MALE_D", but it can not be played by player, because condition is set to NOT be CAIConditionIsPlayer (check file amb_rest.meta and amb_rest_CA.meta with OPENIV to clarify requirements). 
						local unknown_5 = -1.0
						local unknown_6 = 0
	
						westTrainBartender = CreatePed(518339740, coords.x+0.85, coords.y+1.25, coords.z+0.5, GetEntityHeading(carriage), true, false, false, false)
						SetPedRandomComponentVariation(westTrainBartender, 0)
						Citizen.InvokeNative(0xA5C38736C426FCB8, westTrainBartender, true)
						Citizen.InvokeNative(0x9F8AA94D6D97DBF4, westTrainBartender, true)
						Citizen.InvokeNative(0x63F58F7C80513AAD, westTrainBartender, false)
						Citizen.InvokeNative(0x7A6535691B477C48, westTrainBartender, false)
						SetBlockingOfNonTemporaryEvents(westTrainBartender, true)
						SetEntityAsMissionEntity(westTrainBartender, true, true)
						SetEntityCanBeDamaged(westTrainBartender, false)
	
						Citizen.InvokeNative(0x524B54361229154F, westTrainBartender, scenario_type_hash, scenario_duration, must_play_enter_anim, optional_conditional_anim_hash, unknown_5, unknown_6)
						spawned = true
					end

					Citizen.InvokeNative(0xB1964A83B345B4AB, barPropsHash)
					Citizen.InvokeNative(0xB1964A83B345B4AB, sleeperPropsHash)

					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 9, true, true)			-- Open fancy cabin doors
					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 10, true, true)			-- Open fancy cabin doors
					Citizen.InvokeNative(0x550CE392A4672412, carriage3, 11, true, true)			-- Open fancy cabin doors

					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 9, true, true)			-- Open fancy cabin doors
					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 10, true, true)			-- Open fancy cabin doors
					Citizen.InvokeNative(0x550CE392A4672412, carriage4, 11, true, true)			-- Open fancy cabin doors

				else
					attached = false
				end
				
			end
		end
	end)
end

-- CreateThread(function ()
-- 	if Config.UseFancyTrainEast then
-- 		local registered = false
-- 		local inMenu = false
-- 		local prompt
-- 		local position
-- 		while true do
-- 			Wait(10)

-- 			if eastTrainBartender and not registered then
-- 				Wait(10)
-- 				-- creates a prompt with text "My prompt" with R button as control.
-- 				prompt = PromptRegisterBegin()
-- 				PromptSetControlAction(prompt, GetHashKey("INPUT_CONTEXT_X")) -- R key
-- 				PromptSetText(prompt, CreateVarString(10, "LITERAL_STRING", "Buy"))
-- 				PromptSetHoldMode(prompt, 1000)
-- 				PromptRegisterEnd(prompt)

-- 				registered = true
-- 			end

-- 			if prompt and eastTrainBartender and registered then
-- 				-- _UI_PROMPT_CONTEXT_SET_POINT
-- 				position = GetEntityCoords(eastTrainBartender) -- rhodes station
-- 				Citizen.InvokeNative(0xAE84C5EE2C384FB3, prompt, position.x, position.y, position.z)

-- 				local radius = 2.0
-- 				-- _UI_PROMPT_CONTEXT_SET_RADIUS
-- 				Citizen.InvokeNative(0x0C718001B77CA468, prompt, radius)
-- 			end

-- 			if PromptHasHoldModeCompleted(prompt) then
-- 				inMenu = true
-- 			end

-- 			if inMenu then
-- 				PromptSetVisible(prompt, false)
-- 			end
-- 		end
-- 	end
-- end)

if Config.Debug then

	if Config.UseTrams then
		TramCreateVehicle(Config.Trolley, Config.tramLoc)
		TriggerServerEvent("BGS_Trains:StoreServerTram", tram)
	end

	if Config.UseEastTrain then
		if Config.UseChristmasTrainEast then
			EastTrainCreateVehicle(christmasTrainHash, Config.eastLoc, Config.EastTrainMaxSpeed)
		elseif Config.UseFancyTrainEast then
			EastTrainCreateVehicle(0xCD2C7CA1, Config.eastLoc, Config.EastTrainMaxSpeed)
		else
			EastTrainCreateVehicle(Config.EastTrain, Config.eastLoc, Config.EastTrainMaxSpeed)
		end
		TriggerServerEvent("BGS_Trains:StoreServerTrainEast", eastTrain)
	end

	AddEventHandler('onResourceStop', function(resourceName)
		if GetCurrentResourceName() == resourceName then
			if Config.UseChristmasTrainEast or Config.UseChristmasTrainWest then
				DeleteEntity(object)
			end
			if Config.UseNetwork then
				NetworkRequestControlOfEntity(westTrain)
				NetworkRequestControlOfEntity(eastTrain)
				NetworkRequestControlOfEntity(tram)
				NetworkRequestControlOfEntity(westTrainDriver)
				NetworkRequestControlOfEntity(eastTrainDriver)
				NetworkRequestControlOfEntity(tramDriver)
			end
			DeleteEntity(westTrain)
			DeleteEntity(eastTrain)
			DeleteEntity(tram)
			DeleteEntity(westTrainDriver)
			DeleteEntity(eastTrainDriver)
			DeleteEntity(tramDriver)
			eastTrain = nil
			westTrain = nil
			tram = nil
			eastTrainDriver = nil
			westTrainDriver = nil
			tramDriver = nil
		end
	end)

	CreateThread(function()
		while true do
			Wait(10)
			if tram then
				Citizen.InvokeNative(0x3660BCAB3A6BB734, tram)
			end
			if eastTrain then
				Citizen.InvokeNative(0x3660BCAB3A6BB734, eastTrain)
			end
			if westTrain then
				Citizen.InvokeNative(0x3660BCAB3A6BB734, westTrain)
			end
		end
	end)
end