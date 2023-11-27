local eastTrain = nil
local westTrain = nil
local tram = nil

RegisterServerEvent("BGS_Trains:StoreServerTram")
AddEventHandler("BGS_Trains:StoreServerTram", function(clientTram)
	tram = clientTram
end)

RegisterServerEvent("BGS_Trains:StoreServerTrainEast")
AddEventHandler("BGS_Trains:StoreServerTrainEast", function(clientTrain)
	eastTrain = clientTrain
end)

RegisterServerEvent("BGS_Trains:StoreServerTrainWest")
AddEventHandler("BGS_Trains:StoreServerTrainEast", function(clientTrain)
	westTrain = clientTrain
end)

RegisterServerEvent("BGS_Trains:ReturnServerTrains")
AddEventHandler("BGS_Trains:ReturnServerTrains", function()
	local _source = source
	TriggerClientEvent("BGS_Trains:GetServerTrains", _source, eastTrain, westTrain, tram)
end)

Citizen.CreateThread(function()
	local hasPlayers
	while true do
		Wait(5000)
		hasPlayers = false
		local peds = GetAllPeds()
		for index, ped in ipairs(peds) do
			if IsPedAPlayer(ped) then
				hasPlayers = true
			end
		end
		if not hasPlayers then
			eastTrain = nil
			westTrain = nil
			tram = nil
		end
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
        eastTrain = nil
		westTrain = nil
		tram = nil
	end
end)