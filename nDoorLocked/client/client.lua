--||TO DO THIS SCRIPT I TAKE EXEMPLE FROM qalle-fivem, THANKS TO HIM||--
				--||Edit By Super.Cool.Ninja||--
ESX = nil
local secretCode = nil
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
    end
    
	-- Update the door list
	ESX.TriggerServerCallback('esx_doorlock:getDoorInfo', function(doorInfo, count)
		for localID = 1, count, 1 do
			if doorInfo[localID] ~= nil then
				Config.DoorList[doorInfo[localID].doorID].locked = doorInfo[localID].state
			end
		end
	end)
end)


local function KeyboardInput(TextEntry, ExampleText, MaxStringLenght)
	AddTextEntry('FMMC_KEY_TIP1', TextEntry)
	DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
	blockinput = true

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Citizen.Wait(0)
	end
		
	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult()
		Citizen.Wait(500)
		blockinput = false
		return result --Returns the result
	else
		Citizen.Wait(500)
		blockinput = false
		return nil
	end
end

function ToggleDoor()
	local playerCoords = GetEntityCoords(PlayerPedId())
	local secretCode = KeyboardInput("Enter the correct security code :", "", 4)
	local dict, anim = 'mp_common_heist', 'a_atm_mugging'

	for i=1, #Config.DoorList do
		local doorID   = Config.DoorList[i]
		local distance = GetDistanceBetweenCoords(playerCoords, doorID.objCoords.x, doorID.objCoords.y, doorID.objCoords.z, true)
		local maxDistance = 1.0
		
		if doorID.distance then
			maxDistance = doorID.distance
		end

		if distance < maxDistance then
			--Check if the security code is nill then we return false.
			if tonumber(secretCode) == nil then
				ESX.ShowNotification("~y~Please enter a valid number.")
				return false
			end

			--Play some animation:
			ESX.Streaming.RequestAnimDict(dict)
			TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)

			--Check if the security code is correct.
			if tonumber(secretCode) == doorID.authorizedCodes then
				ESX.ShowNotification("~g~Permission Granted")
				doorID.locked = not doorID.locked
				TriggerServerEvent('esx_doorlock:updateState', i, doorID.locked) -- Broadcast new state of the door to everyone
			else
				ESX.ShowNotification("~r~Permission Denied")
			end				
		end
	end		
end

Citizen.CreateThread(function()
	while true do
        Citizen.Wait(0)
		local playerCoords = GetEntityCoords(PlayerPedId())
		for i=1, #Config.DoorList do
			local doorID   = Config.DoorList[i]
			local distance = GetDistanceBetweenCoords(playerCoords, doorID.objCoords.x, doorID.objCoords.y, doorID.objCoords.z, true)
			local maxDistance = 1.0

			if doorID.distance then
				maxDistance = doorID.distance
			end

			if distance < maxDistance then
				ApplyDoorState(doorID)

				local size = 1
				if doorID.size then
					size = doorID.size
				end

				local displayText = 'Open' --Ouvert
				if doorID.locked then
					displayText = 'Lock' --Fermer
				end

                if IsControlJustReleased(0, 38) then
					ToggleDoor()
				end
				
				ESX.Game.Utils.DrawText3D(doorID.textCoords, displayText, size)
			end
		end
	end
end)

function ApplyDoorState(doorID)
	local closeDoor = GetClosestObjectOfType(doorID.objCoords.x, doorID.objCoords.y, doorID.objCoords.z, 1.0, GetHashKey(doorID.objName), false, false, false)
	FreezeEntityPosition(closeDoor, doorID.locked)
end

-- Update State of the door
RegisterNetEvent('esx_doorlock:setState')
AddEventHandler('esx_doorlock:setState', function(doorID, state)
	Config.DoorList[doorID].locked = state
end)