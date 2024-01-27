local spawned = false

local players = {}

local eastTrain
local westTrain
local tram

RegisterServerEvent("BGS_Trains:server:CanSpawnTrain", function ()
	local _source = source
	local canSpawn = false

	table.insert(players, _source)

	if not spawned then
		spawned = true
		canSpawn = true
	end

	TriggerClientEvent("BGS_Trains:client:CanSpawnTrain", _source, canSpawn)
end)

RegisterServerEvent("BGS_Trains:server:StoreNetIndex", function (netIndex, trainArea)
	if trainArea == "east" then
		eastTrain = netIndex
	elseif trainArea == "west" then
		westTrain = netIndex
	else
		tram = netIndex
	end
end)

RegisterServerEvent("BGS_Trains:server:GetTrainsFromServer", function ()
	local src = source
	print(eastTrain, westTrain, tram)
	TriggerClientEvent("BGS_Trains:client:GetTrainsFromServer", src, eastTrain, westTrain, tram)
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
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
        spawned = false
		players = {}
	end
end)