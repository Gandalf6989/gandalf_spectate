ESX = nil

TriggerEvent('esx:getSharedObject', function(obj)ESX = obj end)

ESX.RegisterServerCallback("gandalf_spectate:getGroup", function(source, cb)
    local player = ESX.GetPlayerFromId(source)

    if player ~= nil then
        local group = player.getGroup()

        if group ~= nil then 
            cb(group)
        else
            cb("user")
        end
    else
        cb("user")
    end
end)

ESX.RegisterServerCallback('gandalf_spectate:getAllPlayers', function(source, cb)
	local players = {}
	
	for _, playerId in ipairs(GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
		table.insert(players, {source = xPlayer.source, steamidentifier = GetPlayerIdentifiers(playerId)[1], identifier = xPlayer.identifier, name = xPlayer.name})
	end

	cb(players)
end)

function CheckPlayerOnSpectate(source)
	for k,v in ipairs(data) do
		if v.id == source then
			return true
		end
	end
	return false
end

data = {}

RegisterServerEvent("gandalf_spectate:getData")
AddEventHandler("gandalf_spectate:getData", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if not CheckPlayerOnSpectate(source) then
        table.insert(data, {
            id = xPlayer.source,
            job = xPlayer.getJob().label .. " - " .. xPlayer.getJob().grade_label,
            name = xPlayer.getName(),
            steamName = GetPlayerName(xPlayer.source),
            money = xPlayer.getMoney(),
            bank = xPlayer.getAccount('bank').money,
            black = xPlayer.getAccount('black_money').money,
            group = xPlayer.getGroup()
        })
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.UpdateTime*60000)

        for k,v in ipairs(data) do
            local xPlayer = ESX.GetPlayerFromId(v.id)
            v.job = xPlayer.getJob().label .. " - " .. xPlayer.getJob().grade_label
            v.money = xPlayer.getMoney()
            v.bank = xPlayer.getAccount('bank').money
            v.black = xPlayer.getAccount('black_money').money
        end
    end
end)

ESX.RegisterServerCallback("gandalf_spectate:data", function(source, cb)
    local playernumber = GetPlayers()
    cb(data, #playernumber)
end)


local ORIGINAL_SPEC_BUCKET = {}

AddEventHandler('playerDropped', function(reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer ~= nil then
        for k,v in ipairs(data) do
            if v.id == xPlayer.source then
                table.remove(data, k)
                local src = source
                if ORIGINAL_SPEC_BUCKET[src] then
                  ORIGINAL_SPEC_BUCKET[src] = nil
                end
                break
            end
        end
    end
end)


RegisterNetEvent('gandalf_spectate:spectatePlayer')
AddEventHandler('gandalf_spectate:spectatePlayer', function(id)
    local src = source
    if type(id) ~= 'string' and type(id) ~= 'number' then
      return
    end
  
    id = tonumber(id)
  
    local target = GetPlayerPed(id)
    if not target then
        return
    end
    local tgtBucket = GetPlayerRoutingBucket(id)
    local srcBucket = GetPlayerRoutingBucket(src)
    
    if tgtBucket ~= srcBucket then
        ORIGINAL_SPEC_BUCKET[src] = srcBucket
        SetPlayerRoutingBucket(src, tgtBucket)
    end
    local tgtCoords = GetEntityCoords(target)
    TriggerClientEvent('gandalf_spectate:specPlayer', src, id, tgtCoords)
end)


RegisterNetEvent('gandalf_spectate:endSpectate', function()
    local src = source
    
    local prevRoutBucket = ORIGINAL_SPEC_BUCKET[src]

    if prevRoutBucket then
        SetPlayerRoutingBucket(src, prevRoutBucket)

        ORIGINAL_SPEC_BUCKET[src] = nil
    end

end)