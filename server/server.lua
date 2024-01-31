local spawned = false

local players = {}

local eastTrain
local eastConductor
local westTrain
local westConductor
local tram
local tramConductor

RegisterServerEvent("BGS_Trains:server:CanSpawnTrain", function ()
	local src = source
	local canSpawn = false

	table.insert(players, src)

	if not spawned then
		spawned = true
		canSpawn = true
	end

	Wait(1000)

	TriggerClientEvent("BGS_Trains:client:CanSpawnTrain", src, canSpawn)
end)

RegisterServerEvent("BGS_Trains:server:StoreNetIndex", function (trainNetIndex, driverNetIndex, trainArea)
	if trainArea == "east" then
		eastTrain = trainNetIndex
		eastConductor = driverNetIndex
	elseif trainArea == "west" then
		westTrain = trainNetIndex
		westConductor = driverNetIndex
	else
		tram = trainNetIndex
		tramConductor = driverNetIndex
	end
end)

RegisterServerEvent("BGS_Trains:server:GetTrainsFromServer", function ()
	local src = source
	TriggerClientEvent("BGS_Trains:client:GetTrainsFromServer", src, eastTrain, westTrain, tram, eastConductor, westConductor, tramConductor)
end)

RegisterServerEvent("BGS_Trains:server:AllPlayersGetTrainsFromServer", function ()
	for index, player in ipairs(players) do
		TriggerClientEvent("BGS_Trains:client:GetTrainsFromServer", player, eastTrain, westTrain, tram, eastConductor, westConductor, tramConductor)
	end
end)

RegisterServerEvent("BGS_Trains:server:ResetTrainBlip", function (train)
	for index, player in ipairs(players) do
		TriggerClientEvent("BGS_Trains:client:RenderTrainBlip", player, train)
	end
end)

AddEventHandler("playerDropped", function(reason)
	local _source = source
	for index, player in ipairs(players) do
		if player == _source then
			table.remove(players, index)
			break
		end
	end
	if #players < 1 then
		spawned = false
		if Config.UseEastTrain then
			DeleteEntity(NetworkGetEntityFromNetworkId(eastTrain))
			DeleteEntity(NetworkGetEntityFromNetworkId(eastConductor))
		end
		if Config.UseWestTrain then
			DeleteEntity(NetworkGetEntityFromNetworkId(westTrain))
			DeleteEntity(NetworkGetEntityFromNetworkId(westConductor))
		end
		if Config.UseTram then
			DeleteEntity(NetworkGetEntityFromNetworkId(tram))
			DeleteEntity(NetworkGetEntityFromNetworkId(tramConductor))
		end
		eastTrain, eastConductor, westTrain, westConductor, tram, tramConductor = nil, nil, nil, nil, nil, nil
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
        spawned = false
		if Config.UseEastTrain then
			DeleteEntity(NetworkGetEntityFromNetworkId(eastTrain))
			DeleteEntity(NetworkGetEntityFromNetworkId(eastConductor))
		end
		if Config.UseWestTrain then
			DeleteEntity(NetworkGetEntityFromNetworkId(westTrain))
			DeleteEntity(NetworkGetEntityFromNetworkId(westConductor))
		end
		if Config.UseTram then
			DeleteEntity(NetworkGetEntityFromNetworkId(tram))
			DeleteEntity(NetworkGetEntityFromNetworkId(tramConductor))
		end
		eastTrain, eastConductor, westTrain, westConductor, tram, tramConductor = nil, nil, nil, nil, nil, nil
		players = {}
	end
end)

-- Despawn stuck trains
CreateThread(function ()
	if not Config.UseWestTrain and not Config.UseEastTrain then
		return
	end
	local lastCoordsEast = vec3(0,0,0)
	local lastCoordsWest = vec3(0,0,0)
	local countEast = 0
	local countWest = 0
	while true do
		local coordsEast
		local coordsWest
		Wait(10000)
		if eastTrain and #players > 0 then
			coordsEast = GetEntityCoords(NetworkGetEntityFromNetworkId(eastTrain))
			if lastCoordsEast ~= coordsEast then
				lastCoordsEast = coordsEast
				countEast = 0
			else
				countEast = countEast + 1
			end
			if countEast == Config.TrainDespawnTimer*6 then
				countEast = 0
				DeleteEntity(NetworkGetEntityFromNetworkId(eastTrain))
				DeleteEntity(NetworkGetEntityFromNetworkId(eastConductor))
				eastTrain, eastConductor = nil, nil
				TriggerClientEvent("BGS_Trains:client:ResetTrain", players[#players], "east")
			end
		else
			lastCoordsEast = vec3(0,0,0)
			countEast = 0
		end
		if westTrain and #players > 0 then
			coordsWest = GetEntityCoords(NetworkGetEntityFromNetworkId(westTrain))
			if lastCoordsWest ~= coordsWest then
				lastCoordsWest = coordsWest
				countWest = 0
			else
				countWest = countWest + 1
			end
			if countWest == Config.TrainDespawnTimer*6 then
				countWest = 0
				DeleteEntity(NetworkGetEntityFromNetworkId(westTrain))
				DeleteEntity(NetworkGetEntityFromNetworkId(westConductor))
				westTrain, westConductor = nil, nil
				TriggerClientEvent("BGS_Trains:client:ResetTrain", players[#players], "west")
			end
		else
			lastCoordsWest = vec3(0,0,0)
			countWest = 0
		end
	end
end)