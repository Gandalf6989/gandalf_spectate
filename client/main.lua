ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
	TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
	Citizen.Wait(0)
	end
end)

local lastSpectateLocation
local isSpectateEnabled = false
local storedTargetPed
local storedTargetPlayerId
local storedGameTag

AddEventHandler("playerSpawned", function(spawn)
    TriggerServerEvent("gandalf_spectate:getData")
end)

RegisterCommand(Config.OpenSpectate.Command, function()
	ESX.TriggerServerCallback("gandalf_spectate:getGroup", function(group)
		for k,v in ipairs(Config.AllowAdmins) do
			if group == v then
				TriggerEvent('gandalf_spectate:spectate')
			end
		end
	end)
end)

RegisterKeyMapping(Config.OpenSpectate.Command, Config.OpenSpectate.Name, "keyboard", Config.OpenSpectate.Button)


local existid = {}

function getPlayersList()
	local players = nil
	local data = {}

    ESX.TriggerServerCallback('gandalf_spectate:data', function(data, player)
        players = data
		playernumber = player
    end)

	while players == nil do
		Citizen.Wait(100)
	end

	if players ~= nil then
		for k, v in pairs(players) do
			table.insert(data, {
				players		= playernumber,
				id        	= players[k].id,
				name     	= players[k].name,
				steamName   = players[k].steamName,
				job    		= players[k].job,
				money  		= players[k].money,
				bank  		= players[k].bank,
				black  		= players[k].black,
				group		= players[k].group
			})
		end
	end

    return data
end

RegisterNetEvent('gandalf_spectate:spectate')
AddEventHandler('gandalf_spectate:spectate', function()

	SetNuiFocus(true, true)

	SendNUIMessage({
		type = 'show',
		data = getPlayersList(),
		player = GetPlayerServerId(PlayerId())
	})

end)

RegisterNUICallback('select', function(data, cb)
	ESX.TriggerServerCallback("gandalf_spectate:getGroup", function(group)
		for k,v in ipairs(Config.AllowAdmins) do
			if group == v then
				SetNuiFocus(false)
                if isSpectateEnabled then
                    toggleSpectate(storedTargetPed)
                    preparePlayerForSpec(false)
                    TriggerServerEvent('gandalf_spectate:endSpectate')
                end
				TriggerServerEvent('gandalf_spectate:spectatePlayer', tonumber(data.id))
			end
		end
	end)
end)

local function clearGamerTagInfo()
    if not storedGameTag then return end
    RemoveMpGamerTag(storedGameTag)
    storedGameTag = nil
end

local function preparePlayerForSpec(bool)
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, bool)
    SetEntityVisible(playerPed, not bool, 0)
end

local function InstructionalButton(controlButton, text)
    ScaleformMovieMethodAddParamPlayerNameString(controlButton)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

local function calculateSpectatorCoords(coords)
    return vec3(coords[1], coords[2], coords[3] - 15.0)
end

local function createGamerTagInfo()
    if storedGameTag and IsMpGamerTagActive(storedGameTag) then return end
    local nameTag = ('[%d] %s'):format(GetPlayerServerId(storedTargetPlayerId), GetPlayerName(storedTargetPlayerId))
    storedGameTag = CreateFakeMpGamerTag(storedTargetPed, nameTag, false, false, '', 0, 0, 0, 0)
    SetMpGamerTagVisibility(storedGameTag, 2, 1)  --set the visibility of component 2(healthArmour) to true
    SetMpGamerTagAlpha(storedGameTag, 2, 255) --set the alpha of component 2(healthArmour) to 255
    SetMpGamerTagHealthBarColor(storedGameTag, 129) --set component 2(healthArmour) color to 129(HUD_COLOUR_YOGA)
    SetMpGamerTagVisibility(storedGameTag, 4, NetworkIsPlayerTalking(i))
end

local function cleanupFailedResolve()
    local playerPed = PlayerPedId()

    RequestCollisionAtCoord(lastSpectateLocation.x, lastSpectateLocation.y, lastSpectateLocation.z)
    SetEntityCoords(playerPed, lastSpectateLocation.x, lastSpectateLocation.y, lastSpectateLocation.z)
    while not HasCollisionLoadedAroundEntity(playerPed) do
        Wait(5)
    end
    preparePlayerForSpec(false)

    DoScreenFadeIn(500)
end


local function createSpectatorTeleportThread()
    CreateThread(function()
        while isSpectateEnabled do
            Wait(500)

            if not DoesEntityExist(storedTargetPed) then
                local _ped = GetPlayerPed(storedTargetPlayerId)
                if _ped > 0 then
                    if _ped ~= storedTargetPed then
                        storedTargetPed = _ped
                    end
                    storedTargetPed = _ped
                else
                    toggleSpectate(storedTargetPed, storedTargetPlayerId)
                    break
                end
            end

            local newSpectateCoords = calculateSpectatorCoords(GetEntityCoords(storedTargetPed))
            SetEntityCoords(PlayerPedId(), newSpectateCoords.x, newSpectateCoords.y, newSpectateCoords.z, 0, 0, 0, false)
        end
    end)
end

local function toggleSpectate(targetPed, targetPlayerId)
    local playerPed = PlayerPedId()

    if isSpectateEnabled then
        isSpectateEnabled = false

        if not lastSpectateLocation then
            print('Last location previous to spectate was not stored properly')
        end

        if not storedTargetPed then
            print('Target ped was not stored to unspectate')
        end

        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end

        RequestCollisionAtCoord(lastSpectateLocation.x, lastSpectateLocation.y, lastSpectateLocation.z)
        SetEntityCoords(playerPed, lastSpectateLocation.x, lastSpectateLocation.y, lastSpectateLocation.z)
        while not HasCollisionLoadedAroundEntity(playerPed) do
            Wait(5)
        end

        preparePlayerForSpec(false)
        NetworkSetInSpectatorMode(false, storedTargetPed)
        clearGamerTagInfo()
        DoScreenFadeIn(500)

        storedTargetPed = nil
    else
        storedTargetPed = targetPed
        storedTargetPlayerId = targetPlayerId
        local targetCoords = GetEntityCoords(targetPed)

        RequestCollisionAtCoord(targetCoords.x, targetCoords.y, targetCoords.z)
        while not HasCollisionLoadedAroundEntity(targetPed) do
            Wait(5)
        end

        NetworkSetInSpectatorMode(true, targetPed)
        DoScreenFadeIn(500)
        isSpectateEnabled = true
        createSpectatorTeleportThread()
    end
end

RegisterNetEvent('gandalf_spectate:specPlayer')
AddEventHandler('gandalf_spectate:specPlayer', function(targetServerId, coords)
	local spectatorPed = PlayerPedId()
    lastSpectateLocation = GetEntityCoords(spectatorPed)

    local targetPlayerId = GetPlayerFromServerId(targetServerId)

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    local tpCoords = calculateSpectatorCoords(coords)
    SetEntityCoords(spectatorPed, tpCoords.x, tpCoords.y, tpCoords.z, 0, 0, 0, false)
    preparePlayerForSpec(true)

    local resolvePlayerAttempts = 0
    local resolvePlayerFailed

    repeat
        if resolvePlayerAttempts > 100 then
            resolvePlayerFailed = true
            break;
        end
        Wait(50)
        --debugPrint('Waiting for player to resolve')
        targetPlayerId = GetPlayerFromServerId(targetServerId)
        resolvePlayerAttempts = resolvePlayerAttempts + 1
    until (GetPlayerPed(targetPlayerId) > 0) and targetPlayerId ~= -1

    if resolvePlayerFailed then
        return cleanupFailedResolve()
    end

    toggleSpectate(GetPlayerPed(targetPlayerId), targetPlayerId)
end)

RegisterCommand('gandalf_spectate:endSpectate', function()
    if isSpectateEnabled then
        toggleSpectate(storedTargetPed)
        preparePlayerForSpec(false)
        TriggerServerEvent('gandalf_spectate:endSpectate')
    end
end)

RegisterNUICallback('close', function(data, cb)
	SetNuiFocus(false)
	if isSpectateEnabled then
        toggleSpectate(storedTargetPed)
        preparePlayerForSpec(false)
        TriggerServerEvent('gandalf_spectate:endSpectate')
    end
end)

RegisterNUICallback('quit', function(data, cb)
	SetNuiFocus(false)
	if isSpectateEnabled then
        toggleSpectate(storedTargetPed)
        preparePlayerForSpec(false)
        TriggerServerEvent('gandalf_spectate:endSpectate')
    end
end)

CreateThread(function()
    while true do
        if isSpectateEnabled then
            createGamerTagInfo()
        else
            clearGamerTagInfo()
        end
        Wait(50)
    end
end)
