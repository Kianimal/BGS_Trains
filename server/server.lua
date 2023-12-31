local eastTrain = nil
local westTrain = nil
local tram = nil

local players = {}

RegisterServerEvent("BGS_Trains:StoreServerTram")
AddEventHandler("BGS_Trains:StoreServerTram", function(clientTram)
	tram = clientTram
end)

RegisterServerEvent("BGS_Trains:StoreServerTrainEast")
AddEventHandler("BGS_Trains:StoreServerTrainEast", function(clientTrain)
	eastTrain = clientTrain
end)

RegisterServerEvent("BGS_Trains:StoreServerTrainWest")
AddEventHandler("BGS_Trains:StoreServerTrainWest", function(clientTrain)
	westTrain = clientTrain
end)

RegisterServerEvent("BGS_Trains:ReturnServerTrains")
AddEventHandler("BGS_Trains:ReturnServerTrains", function(addToList)
	local _source = source
	if addToList then
		table.insert(players, _source)
	end
	TriggerClientEvent("BGS_Trains:GetServerTrains", _source, eastTrain, westTrain, tram)
end)

RegisterServerEvent("BGS_Trains:GetPlayerCount", function()
	local _source = source
	TriggerClientEvent("BGS_Trains:GetPlayerCount", _source, players)
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
		print(eastTrain, westTrain, tram)
		if eastTrain then
			eastTrain = nil
		end
		if westTrain then
			westTrain = nil
		end
		if tram then
			tram = nil
		end
		print(eastTrain, westTrain, tram)
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
        eastTrain = nil
		westTrain = nil
		tram = nil
	end
end)