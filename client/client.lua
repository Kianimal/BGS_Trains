local canSpawn = false

local westTrain
local eastTrain
local tram

local netIndex

local loc = vector3(2590.34, -1477.24, 45.86)
local loc2 = vector3(2608.38, -1203.12, 53.16)
local loc3 = vector3(-3763.37, -2782.54, -14.43)

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

local function TrainCreateVehicle(trainModel, location, trainArea)
	local trainWagons = N_0x635423d55ca84fc8(trainModel)

	for i = 0, trainWagons - 1 do
		local trainWagonModel = N_0x8df5f6a19f99f0d5(trainModel, i)
		RequestModel(trainWagonModel)
		while not HasModelLoaded(trainWagonModel) do
			Citizen.Wait(0)
		end
	end

	local trainVeh = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, location.x, location.y, location.z, false, false, true, true)

	SetTrainSpeed(trainVeh, Config.TrainMaxSpeed)
	SetTrainCruiseSpeed(trainVeh, Config.TrainMaxSpeed)
	Citizen.InvokeNative(0x9F29999DFDF2AEB8, trainVeh, Config.TrainMaxSpeed)
	Citizen.InvokeNative(0x4182C037AA1F0091, trainVeh, true) 					-- Set train stops for stations
	Citizen.InvokeNative(0x8EC47DD4300BF063, trainVeh, 0.0) 					-- Set train offset for station

	local trainDriverHandle = GetPedInVehicleSeat(trainVeh, -1)
	while not DoesEntityExist(trainDriverHandle) do
		trainDriverHandle = GetPedInVehicleSeat(trainVeh, -1)
		SetEntityAsMissionEntity(trainDriverHandle, true, true)
		Citizen.Wait(1)
	end

	Citizen.InvokeNative(0xA5C38736C426FCB8, trainDriverHandle, true)
	Citizen.InvokeNative(0x9F8AA94D6D97DBF4, trainDriverHandle, true)
	Citizen.InvokeNative(0x63F58F7C80513AAD, trainDriverHandle, false)
	Citizen.InvokeNative(0x7A6535691B477C48, trainDriverHandle, false)
	SetBlockingOfNonTemporaryEvents(trainDriverHandle, true)
	Citizen.InvokeNative(0x05254BA0B44ADC16, trainVeh, false)
	SetEntityAsMissionEntity(trainDriverHandle, true, true)
	SetEntityCanBeDamaged(trainDriverHandle, false)

	NetworkRegisterEntityAsNetworked(trainVeh)
	SetNetworkIdExistsOnAllMachines(VehToNet(trainVeh), true)
	NetworkRegisterEntityAsNetworked(trainDriverHandle)
	SetNetworkIdExistsOnAllMachines(PedToNet(trainDriverHandle), true)

	-- Prevent people from knocking driver out of train
	CreateThread(function()
		while true do
			Wait(1)
			if GetDistanceBetweenCoords(GetEntityCoords(trainDriverHandle), GetEntityCoords(PlayerPedId())) < 12.5 then
				Citizen.InvokeNative(0xFC094EF26DD153FA,12)
			end
		end
	end)

	TriggerServerEvent("BGS_Trains:server:StoreNetIndex", VehToNet(trainVeh), trainArea)

end

local function TramCreateVehicle(trainModel, location)
	local trainWagons = N_0x635423d55ca84fc8(trainModel)

	for i = 0, trainWagons - 1 do
		local trainWagonModel = N_0x8df5f6a19f99f0d5(trainModel, i)
		RequestModel(trainWagonModel)
		while not HasModelLoaded(trainWagonModel) do
			Citizen.Wait(0)
		end
	end

	local tramVeh = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, location, true, false, true, true)
	SetTrainSpeed(tramVeh, 2.0)
	Citizen.InvokeNative(0x4182C037AA1F0091, tramVeh, true) 					-- Set train stops for stations
	Citizen.InvokeNative(0x8EC47DD4300BF063, tramVeh, 0.0) 					-- Set train offset for station

	local trainDriverHandle = GetPedInVehicleSeat(tramVeh, -1)
	while not DoesEntityExist(trainDriverHandle) do
		trainDriverHandle = GetPedInVehicleSeat(tramVeh, -1)
		Citizen.Wait(1)
	end

	SetEntityAsMissionEntity(trainDriverHandle, true, true)
	SetEntityCanBeDamaged(trainDriverHandle, false)
	SetEntityInvincible(trainDriverHandle, true)
	FreezeEntityPosition(trainDriverHandle, true)
	SetBlockingOfNonTemporaryEvents(trainDriverHandle, true)

	NetworkRegisterEntityAsNetworked(tramVeh)
	NetworkRegisterEntityAsNetworked(trainDriverHandle)

	NetworkRegisterEntityAsNetworked(tramVeh)
	SetNetworkIdExistsOnAllMachines(VehToNet(tramVeh), true)
	NetworkRegisterEntityAsNetworked(trainDriverHandle)
	SetNetworkIdExistsOnAllMachines(PedToNet(trainDriverHandle), true)

	TriggerServerEvent("BGS_Trains:server:StoreNetIndex", VehToNet(tramVeh))

end

RegisterNetEvent("vorp:SelectedCharacter", function()
	TriggerServerEvent("BGS_Trains:server:CanSpawnTrain")
	Wait(100)
	if canSpawn then
		if Config.UseEastTrain then
			TrainCreateVehicle(Config.EastTrain, loc, "east")
		end
		if Config.UseWestTrain then
			TrainCreateVehicle(Config.WestTrain, loc3, "west")
		end
		if Config.UseTrams then
			TramCreateVehicle(Config.Trolley, loc2)
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

RegisterNetEvent("BGS_Trains:client:CanSpawnTrain", function(canSpawnTrains)
	canSpawn = canSpawnTrains
end)

RegisterNetEvent("BGS_Trains:client:GetTrainsFromServer", function (eastNet, westNet, tramNet)
	print(eastNet, westNet, tramNet)
	eastTrain = NetToVeh(eastNet)
	westTrain = NetToVeh(westNet)
	tram = NetToVeh(tramNet)
end)

-- Handle west train shit
CreateThread(function()
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
	while true do
		Wait(250)
		if tram then
			-- SetTrainSpeed(tram, 2.0)
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