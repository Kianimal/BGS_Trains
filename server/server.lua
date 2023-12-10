local eastTrain = nil
local eastDriver = nil

local westTrain = nil
local westDriver = nil

local tram = nil
local tramDriver = nil

local players = {}

RegisterServerEvent("BGS_Trains:StoreServerTram")
AddEventHandler("BGS_Trains:StoreServerTram", function(clientTram, clientTramDriver)
	tram = clientTram
	tramDriver = clientTramDriver
	TriggerEvent("BGS_Trains:UpdateTrainsAllPlayers")
end)

RegisterServerEvent("BGS_Trains:StoreServerTrainEast")
AddEventHandler("BGS_Trains:StoreServerTrainEast", function(clientTrain, clientEastDriver)
	eastTrain = clientTrain
	eastDriver = clientEastDriver
	TriggerEvent("BGS_Trains:UpdateTrainsAllPlayers")
end)

RegisterServerEvent("BGS_Trains:StoreServerTrainWest")
AddEventHandler("BGS_Trains:StoreServerTrainWest", function(clientTrain, clientWestDriver)
	westTrain = clientTrain
	westDriver = clientWestDriver
	TriggerEvent("BGS_Trains:UpdateTrainsAllPlayers")
end)

RegisterServerEvent("BGS_Trains:ReturnServerTrains")
AddEventHandler("BGS_Trains:ReturnServerTrains", function(addToList)
	local _source = source
	if addToList then
		table.insert(players, _source)
	end
	TriggerClientEvent("BGS_Trains:GetServerTrains", _source, eastTrain, westTrain, tram, eastDriver, westDriver, tramDriver)
end)

RegisterServerEvent("BGS_Trains:UpdateTrainsAllPlayers", function ()
	for index, player in ipairs(players) do
		TriggerClientEvent("BGS_Trains:GetServerTrains", player, eastTrain, westTrain, tram, eastDriver, westDriver, tramDriver)
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
		eastTrain = nil
		westTrain = nil
		tram = nil
	end
end)