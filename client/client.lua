local TrainBlip
local westTrain = nil
local eastTrain = nil
local tram = nil

local loc = vector3(2590.34, -1477.24, 45.86)
local loc2 = vector3(2608.38, -1203.12, 53.16)
local loc3 = vector3(-3763.37, -2782.54, -14.43)

RegisterNetEvent("BGS_Trains:GetServerTrains")
AddEventHandler("BGS_Trains:GetServerTrains", function(serverTrainWest, serverTrainEast, serverTram)
	westTrain = serverTrainWest
	eastTrain = serverTrainEast
	tram = serverTram
end)

function RenderTrainBlip(vehicle)
	TrainBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 1664425300, vehicle)
	SetBlipSprite(TrainBlip, -250506368)
	if vehicle == eastTrain then
		Citizen.InvokeNative(0x9CB1A1623062F402, TrainBlip, Config.TrainBlipNameEast)
	else
		Citizen.InvokeNative(0x9CB1A1623062F402, TrainBlip, Config.TrainBlipNameWest)
	end
	SetBlipScale(TrainBlip, 1.0)
end

local function TrainCreateVehicle(trainModel, loc, line)
	local trainWagons = N_0x635423d55ca84fc8(trainModel)

	for i = 0, trainWagons - 1 do
		local trainWagonModel = N_0x8df5f6a19f99f0d5(trainModel, i)
		RequestModel(trainWagonModel)
		while not HasModelLoaded(trainWagonModel) do
			Citizen.Wait(0)
		end
	end

	local train = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, loc.x, loc.y, loc.z, false, false, true, true)

	if line == "east" then
		eastTrain = train
	end

	if line == "west" then
		westTrain = train
	end

	SetTrainSpeed(train, Config.TrainMaxSpeed)
	SetTrainCruiseSpeed(train, Config.TrainMaxSpeed)
	Citizen.InvokeNative(0x9F29999DFDF2AEB8, train, Config.TrainMaxSpeed)
	Citizen.InvokeNative(0x4182C037AA1F0091, train, true) 					-- Set train stops for stations
	Citizen.InvokeNative(0x8EC47DD4300BF063, train, 0.0) 					-- Set train offset for station

	RenderTrainBlip(train)

	local trainDriverHandle = GetPedInVehicleSeat(train, -1)
	while not DoesEntityExist(trainDriverHandle) do
		trainDriverHandle = GetPedInVehicleSeat(train, -1)
		SetEntityAsMissionEntity(trainDriverHandle, true, true)
		Citizen.Wait(1)
	end

	Citizen.InvokeNative(0xA5C38736C426FCB8, trainDriverHandle, true)
	Citizen.InvokeNative(0x9F8AA94D6D97DBF4, trainDriverHandle, true)
	Citizen.InvokeNative(0x63F58F7C80513AAD, trainDriverHandle, false)
	Citizen.InvokeNative(0x7A6535691B477C48, trainDriverHandle, false)
	SetBlockingOfNonTemporaryEvents(trainDriverHandle, true)
	Citizen.InvokeNative(0x05254BA0B44ADC16, train, false)
	SetEntityAsMissionEntity(trainDriverHandle, true, true)
	SetEntityCanBeDamaged(trainDriverHandle, false)

	NetworkRegisterEntityAsNetworked(train)
	SetNetworkIdExistsOnAllMachines(VehToNet(train), true)
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

end

local function TramCreateVehicle(trainModel, loc)
	local trainWagons = N_0x635423d55ca84fc8(trainModel)

	for i = 0, trainWagons - 1 do
		local trainWagonModel = N_0x8df5f6a19f99f0d5(trainModel, i)
		RequestModel(trainWagonModel)
		while not HasModelLoaded(trainWagonModel) do
			Citizen.Wait(0)
		end
	end

	tram = Citizen.InvokeNative(0xC239DBD9A57D2A71, trainModel, loc, true, false, true, true)
	SetTrainSpeed(tram, 2.0)
	Citizen.InvokeNative(0x4182C037AA1F0091, tram, true) 					-- Set train stops for stations
	Citizen.InvokeNative(0x8EC47DD4300BF063, tram, 0.0) 					-- Set train offset for station

	local trainDriverHandle = GetPedInVehicleSeat(tram, -1)
	while not DoesEntityExist(trainDriverHandle) do
		trainDriverHandle = GetPedInVehicleSeat(tram, -1)
		Citizen.Wait(1)
	end

	SetEntityAsMissionEntity(trainDriverHandle, true, true)
	SetEntityCanBeDamaged(trainDriverHandle, false)
	SetEntityInvincible(trainDriverHandle, true)
	FreezeEntityPosition(trainDriverHandle, true)
	SetBlockingOfNonTemporaryEvents(trainDriverHandle, true)

	NetworkRegisterEntityAsNetworked(tram)
	NetworkRegisterEntityAsNetworked(trainDriverHandle)

	NetworkRegisterEntityAsNetworked(tram)
	SetNetworkIdExistsOnAllMachines(VehToNet(tram), true)
	NetworkRegisterEntityAsNetworked(trainDriverHandle)
	SetNetworkIdExistsOnAllMachines(PedToNet(trainDriverHandle), true)

end

RegisterNetEvent("vorp:SelectedCharacter", function()
	TriggerServerEvent("BGS_Trains:ReturnServerTrains", true)
	Wait(100)
	if not eastTrain then
		if Config.UseEastTrain then
			TrainCreateVehicle(Config.EastTrain, loc, "east")
			TriggerServerEvent("BGS_Trains:StoreServerTrainEast", eastTrain)
		end
	elseif eastTrain then
		RenderTrainBlip(eastTrain)
	end
	if tram == nil then
		if Config.UseTrams then
			TramCreateVehicle(Config.Trolley, loc2)
			TriggerServerEvent("BGS_Trains:StoreServerTram", tram)
		end
	end
	if westTrain == nil then
		if Config.UseWestTrain then
			TrainCreateVehicle(Config.WestTrain, loc3, "west")
			TriggerServerEvent("BGS_Trains:StoreServerTrainWest", westTrain)
		end
	elseif westTrain then
		RenderTrainBlip(westTrain)
	end
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

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
		if westTrain then
			DeleteEntity(westTrain)
			westTrain = nil
		end
		if eastTrain then
			DeleteEntity(eastTrain)
			eastTrain = nil
		end
		if tram then
			DeleteEntity(tram)
			tram = nil
		end
	end
end)