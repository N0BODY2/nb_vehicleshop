local HasAlreadyEnteredMarker = false
local LastZone                = nil
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local IsInShopMenu            = false
local Categories              = {}
local Vehicles                = {}
local LastVehicles            = {}
local CurrentVehicleData      = nil
local timer_testdrive 		  = 40
  
ESX                           = nil
  
Citizen.CreateThread(function ()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
  
	Citizen.Wait(10000)
  
	ESX.TriggerServerCallback('nb_vehicleshop:getCategories', function (categories)
		Categories = categories
	end)
  
	ESX.TriggerServerCallback('nb_vehicleshop:getVehicles', function (vehicles)
		Vehicles = vehicles
	end)
  
	if Config.EnablePlayerManagement then
		if ESX.PlayerData.job.name == 'vehicle' then
			Config.Zones.ShopEntering.Type = 1
  
			if ESX.PlayerData.job.grade_name == 'boss' then
				Config.Zones.BossActions.Type = 1
			end
  
		else
			Config.Zones.ShopEntering.Type = -1
			Config.Zones.BossActions.Type  = -1
		end
	end
end)
  
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
  
	if Config.EnablePlayerManagement then
		if ESX.PlayerData.job.name == 'vehicle' then
			Config.Zones.ShopEntering.Type = 1
  
			if ESX.PlayerData.job.grade_name == 'boss' then
				Config.Zones.BossActions.Type = 1
			end
  
		else
			Config.Zones.ShopEntering.Type = -1
			Config.Zones.BossActions.Type  = -1
		end
	end
end)
  
RegisterNetEvent('nb_vehicleshop:sendCategories')
AddEventHandler('nb_vehicleshop:sendCategories', function (categories)
	Categories = categories
end)
  
RegisterNetEvent('nb_vehicleshop:sendVehicles')
AddEventHandler('nb_vehicleshop:sendVehicles', function (vehicles)
	Vehicles = vehicles
end)
  
function DeleteShopInsideVehicles()
	while #LastVehicles > 0 do
		local vehicle = LastVehicles[1]
  
		ESX.Game.DeleteVehicle(vehicle)
		table.remove(LastVehicles, 1)
	end
end
  
function ReturnVehicleProvider()
	ESX.TriggerServerCallback('nb_vehicleshop:getCommercialVehicles', function (vehicles)
		local elements = {}
		local returnPrice
		for i=1, #vehicles, 1 do
			returnPrice = ESX.Math.Round(vehicles[i].price * 0.75)
  
			table.insert(elements, {
				label = ('%s [<span style="color:orange;">%s</span>]'):format(vehicles[i].name, _U('generic_shopitem', ESX.Math.GroupDigits(returnPrice))),
				value = vehicles[i].name
			})
		end
  
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_provider_menu', {
			title    = _U('return_provider_menu'),
			align    = Config.allign,
			elements = elements
		}, function (data, menu)
			TriggerServerEvent('nb_vehicleshop:returnProvider', data.current.value)
  
			Citizen.Wait(300)
			menu.close()
			ReturnVehicleProvider()
		end, function (data, menu)
			menu.close()
		end)
	end)
end
  
function StartShopRestriction()
	Citizen.CreateThread(function()
		while IsInShopMenu do
			Citizen.Wait(1)
  
			DisableControlAction(0, 75,  true) -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle
		end
	end)
end
  
function OpenShopMenu()
	IsInShopMenu = true

	StartShopRestriction()
	ESX.UI.Menu.CloseAll()

	local playerPed = PlayerPedId()

	FreezeEntityPosition(playerPed, true)
	SetEntityVisible(playerPed, false)
	SetEntityCoords(playerPed, Config.Zones.ShopInside.Pos)

	local vehiclesByCategory = {}
	local elements           = {}
	local firstVehicleData   = nil

	for i=1, #Categories, 1 do
		vehiclesByCategory[Categories[i].name] = {}
	end

	for i=1, #Vehicles, 1 do
		if IsModelInCdimage(GetHashKey(Vehicles[i].model)) then
			table.insert(vehiclesByCategory[Vehicles[i].category], Vehicles[i])
		else
			print(('nb_vehicleshop: vehicle "%s" does not exist'):format(Vehicles[i].model))
		end
	end

	for i=1, #Categories, 1 do
		local category         = Categories[i]
		local categoryVehicles = vehiclesByCategory[category.name]
		local options          = {}

		for j=1, #categoryVehicles, 1 do
			local vehicle = categoryVehicles[j]

			if i == 1 and j == 1 then
				firstVehicleData = vehicle
			end

			table.insert(options, ('%s <span style="color:green;">%s</span>'):format(vehicle.name, _U('generic_shopitem', ESX.Math.GroupDigits(vehicle.price))))
		end

		table.insert(elements, {
			name    = category.name,
			label   = category.label,
			value   = 0,
			type    = 'slider',
			max     = #Categories[i],
			options = options
		})
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop', {
		title    = _U('car_dealer'),
		align    = Config.allign,
		elements = elements
	}, function (data, menu)
		local vehicleData = vehiclesByCategory[data.current.name][data.current.value + 1]

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop_confirm', {
			title = _U('buy_vehicle_shop', vehicleData.name, ESX.Math.GroupDigits(vehicleData.price)),
			align = Config.allign,
			elements = {
			  {label = _U('cena', vehicleData.price), value = 'cena'},
			  {label = _U('zobrazit'), value = 'zobrazit'},
			  {label = _U('testdrive'), value = 'testdrive'},
			  {label = _U('yes'), value = 'yes'},
			  {label = _U('no'),  value = 'no'}
			}
		}, function(data2, menu2)

		if data2.current.value == 'zobrazit' then
		  local vehicleData = vehiclesByCategory[data.current.name][data.current.value + 1]
		  local playerPed   = PlayerPedId()
  
		  DeleteShopInsideVehicles()
		  WaitForVehicleToLoad(vehicleData.model)
  
		  ESX.Game.SpawnLocalVehicle(vehicleData.model, Config.Zones.ShopInside.Pos, Config.Zones.ShopInside.Heading, function (vehicle)
			  table.insert(LastVehicles, vehicle)
			  TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
			  FreezeEntityPosition(vehicle, true)
			  SetModelAsNoLongerNeeded(vehicleData.model)
		  end)
		elseif data2.current.value == 'testdrive' then
			local playerPed = PlayerPedId()
		 
			IsInShopMenu = false
			WaitForVehicleToLoad(vehicleData.model)
		 
			ESX.Game.SpawnLocalVehicle(vehicleData.model, Config.Zones.ShopOutside.Pos, Config.Zones.ShopOutside.Heading, function (vehicle)

			 TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
			 SetVehicleNumberPlateText(vehicle, "TEST")
			 ESX.ShowNotification(_U('testdrive_notification',timer_testdrive))
			 SetEntityVisible(playerPed, true)
			 ESX.UI.Menu.CloseAll()
			 Citizen.CreateThread(function () 
				 local counter = timer_testdrive
				 
				 while counter > 0 do 
					 counter = counter -1
					 Citizen.Wait(1000)
				 end
				 
				 DeleteVehicle(vehicle)
				 SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos, false, false, false, false)
		 
				 ESX.ShowNotification(_U('testdrive_finished'))
				 FreezeEntityPosition(playerPed, false)
				 DeleteShopInsideVehicles()
			 end) 
		   end)
  elseif data2.current.value == 'yes' then

				if Config.EnablePlayerManagement then
					ESX.TriggerServerCallback('nb_vehicleshop:buyVehicleSociety', function(hasEnoughMoney)
						if hasEnoughMoney then
							IsInShopMenu = false

							DeleteShopInsideVehicles()

							local playerPed = PlayerPedId()

							CurrentAction     = 'shop_menu'
							CurrentActionMsg  = _U('shop_menu')
							CurrentActionData = {}

							FreezeEntityPosition(playerPed, false)
							SetEntityVisible(playerPed, true)
							SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)

							menu2.close()
							menu.close()

							exports['mythic_notify']:SendAlert('success', _U('vehicle_purchased'))
						else
							ESX.ShowNotification(_U('broke_company'))
						end
					end, 'vehicle', vehicleData.model)
				else
					local playerData = ESX.GetPlayerData()

					if Config.EnableSocietyOwnedVehicles then
						ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop_confirm_buy_type', {
							title = _U('purchase_type'),
							align = Config.allign,
							elements = {
								{label = _U('staff_type'),   value = 'personnal'},
								{label = _U('society_type'), value = 'society'}
						}}, function (data3, menu3)

							if data3.current.value == 'personnal' then

								ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'person_kupovani', {
									title = _U('zaplatit'),
									align = Config.allign,
									elements = {
										{label = _U('penize'),   value = 'penize'},
										{label = _U('banka'), value = 'banka'}
								}}, function (data4, menu4)
									if data4.current.value == 'penize' then 

										ESX.TriggerServerCallback('nb_vehicleshop:buyVehicleCash', function(hascash)
											if hascash then
												IsInShopMenu = false

												menu4.close()
												menu3.close()
												menu2.close()
												menu.close()
												DeleteShopInsideVehicles()
		
												ESX.Game.SpawnVehicle(vehicleData.model, Config.Zones.ShopOutside.Pos, Config.Zones.ShopOutside.Heading, function (vehicle)
													TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		
													local newPlate     = GeneratePlate()
													local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
													vehicleProps.plate = newPlate
													SetVehicleNumberPlateText(vehicle, newPlate)
		
													if Config.EnableOwnedVehicles then
														TriggerServerEvent('nb_vehicleshop:setVehicleOwned', vehicleProps)
													end
		
													exports['mythic_notify']:SendAlert('success', _U('vehicle_purchased'))
												end)
		
												FreezeEntityPosition(playerPed, false)
												SetEntityVisible(playerPed, true)
											else
												ESX.ShowNotification(_U('not_enough_money'))
											end
										end, vehicleData.model)
							          end
							        end, function (data4, menu4)
								        menu4.close()
							        end)
							elseif data3.current.value == 'society' then

								ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'person_kupovani', {
									title = _U('zaplatit'),
									align = Config.allign,
									elements = {
										{label = _U('penize'),   value = 'penize'},
										{label = _U('banka'), value = 'banka'}
								}}, function (data5, menu5)
									if data5.current.value == 'penize' then 

										ESX.TriggerServerCallback('nb_vehicleshop:buyVehicle', function(hasbank)
											if hasbank then
												IsInShopMenu = false

												menu5.close()
												menu3.close()
												menu2.close()
												menu.close()
												DeleteShopInsideVehicles()
		
												ESX.Game.SpawnVehicle(vehicleData.model, Config.Zones.ShopOutside.Pos, Config.Zones.ShopOutside.Heading, function (vehicle)
													TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		
													local newPlate     = GeneratePlate()
													local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
													vehicleProps.plate = newPlate
													SetVehicleNumberPlateText(vehicle, newPlate)
		
													if Config.EnableOwnedVehicles then
														TriggerServerEvent('nb_vehicleshop:setVehicleOwned', vehicleProps)
													end
		
													exports['mythic_notify']:SendAlert('success', _U('vehicle_purchased'))
												end)
		
												FreezeEntityPosition(playerPed, false)
												SetEntityVisible(playerPed, true)
											else
												ESX.ShowNotification(_U('not_enough_money'))
											end
										end, vehicleData.model)
							          end
							        end, function (data5, menu5)
								        menu5.close()
							        end)

							end
						end, function (data3, menu3)
							menu3.close()
						end)
					else
						ESX.TriggerServerCallback('nb_vehicleshop:buyVehicle', function (hasEnoughMoney)
							if hasEnoughMoney then
								IsInShopMenu = false
								menu2.close()
								menu.close()
								DeleteShopInsideVehicles()

								ESX.Game.SpawnVehicle(vehicleData.model, Config.Zones.ShopOutside.Pos, Config.Zones.ShopOutside.Heading, function (vehicle)
									TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

									local newPlate     = GeneratePlate()
									local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
									vehicleProps.plate = newPlate
									SetVehicleNumberPlateText(vehicle, newPlate)

									if Config.EnableOwnedVehicles then
										TriggerServerEvent('nb_vehicleshop:setVehicleOwned', vehicleProps)
									end

									exports['mythic_notify']:SendAlert('success', _U('vehicle_purchased'))
								end)

								FreezeEntityPosition(playerPed, false)
								SetEntityVisible(playerPed, true)
							else
								ESX.ShowNotification(_U('not_enough_money'))
							end
						end, vehicleData.model)
					end
				end
			end
		end, function (data2, menu2)
			menu2.close()
		end)
	end, function (data, menu)
		menu.close()
		DeleteShopInsideVehicles()
		local playerPed = PlayerPedId()

		CurrentAction     = 'shop_menu'
		CurrentActionMsg  = _U('shop_menu')
		CurrentActionData = {}

		FreezeEntityPosition(playerPed, false)
		SetEntityVisible(playerPed, true)
		SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)

		IsInShopMenu = false
	end)
  end

function WaitForVehicleToLoad(modelHash)
	  modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))
  
	  if not HasModelLoaded(modelHash) then
		  RequestModel(modelHash)
  
		  BeginTextCommandBusyString('STRING')
		  AddTextComponentSubstringPlayerName(_U('shop_awaiting_model'))
		  EndTextCommandBusyString(4)
  
		  while not HasModelLoaded(modelHash) do
			  Citizen.Wait(1)
			  DisableAllControlActions(0)
		  end
  
		  RemoveLoadingPrompt()
	  end
end
  
  
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function (job)
	  ESX.PlayerData.job = job
  
	  if Config.EnablePlayerManagement then
		  if ESX.PlayerData.job.name == 'vehicle' then
			  Config.Zones.ShopEntering.Type = 1
  
			  if ESX.PlayerData.job.grade_name == 'boss' then
				  Config.Zones.BossActions.Type = 1
			  end
		  else
			  Config.Zones.ShopEntering.Type = -1
			  Config.Zones.BossActions.Type  = -1
		end
	end
end)
  
AddEventHandler('nb_vehicleshop:hasEnteredMarker', function (zone)
	  if zone == 'ShopEntering' then
  
		  if Config.EnablePlayerManagement then
			  if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == 'vehicle' then
				  CurrentAction     = 'reseller_menu'
				  CurrentActionMsg  = _U('shop_menu')
				  CurrentActionData = {}
			  end
		  else
			  CurrentAction     = 'shop_menu'
			  CurrentActionMsg  = _U('shop_menu')
			  CurrentActionData = {}
		  end
  
	  elseif zone == 'GiveBackVehicle' and Config.EnablePlayerManagement then
  
		  local playerPed = PlayerPedId()
  
		  if IsPedInAnyVehicle(playerPed, false) then
			  local vehicle = GetVehiclePedIsIn(playerPed, false)
  
			  CurrentAction     = 'give_back_vehicle'
			  CurrentActionMsg  = _U('vehicle_menu')
			  CurrentActionData = {vehicle = vehicle}
		  end
  
	  elseif zone == 'ResellVehicle' then
  
		  local playerPed = PlayerPedId()
  
		  if IsPedSittingInAnyVehicle(playerPed) then
  
			  local vehicle     = GetVehiclePedIsIn(playerPed, false)
			  local vehicleData, model, resellPrice, plate
  
			  if GetPedInVehicleSeat(vehicle, -1) == playerPed then
				  for i=1, #Vehicles, 1 do
					  if GetHashKey(Vehicles[i].model) == GetEntityModel(vehicle) then
						  vehicleData = Vehicles[i]
						  break
					  end
				  end
  
				  resellPrice = ESX.Math.Round(vehicleData.price / 100 * Config.ResellPercentage)
				  model = GetEntityModel(vehicle)
				  plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
  
				  CurrentAction     = 'resell_vehicle'
				  CurrentActionMsg  = _U('sell_menu', vehicleData.name, ESX.Math.GroupDigits(resellPrice))
  
				  CurrentActionData = {
					  vehicle = vehicle,
					  label = vehicleData.name,
					  price = resellPrice,
					  model = model,
					  plate = plate
				  }
			  end
  
		  end
  
	  elseif zone == 'BossActions' and Config.EnablePlayerManagement and ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == 'vehicle' and ESX.PlayerData.job.grade_name == 'boss' then
  
		  CurrentAction     = 'boss_actions_menu'
		  CurrentActionMsg  = _U('shop_menu')
		  CurrentActionData = {}
  
	  end
  end)
  
AddEventHandler('nb_vehicleshop:hasExitedMarker', function (zone)
	if not IsInShopMenu then
		ESX.UI.Menu.CloseAll()
	end
  
	CurrentAction = nil
end)
  
AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		if IsInShopMenu then
			ESX.UI.Menu.CloseAll()
  
			DeleteShopInsideVehicles()
			local playerPed = PlayerPedId()
  
			FreezeEntityPosition(playerPed, false)
			SetEntityVisible(playerPed, true)
			SetEntityCoords(playerPed, Config.Zones.ShopEntering.Pos)
		end
	end
end)
  
-- Enter / Exit marker events & Draw Markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerCoords = GetEntityCoords(PlayerPedId())
		local isInMarker, letSleep, currentZone = false, true

		for k,v in pairs(Config.Zones) do
			local distance = #(playerCoords - v.Pos)

			if distance < Config.DrawDistance then
				letSleep = false

				if v.Type ~= -1 then
					DrawMarker(v.Type, v.Pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)
				end

				if distance < v.Size.x then
					isInMarker, currentZone = true, k
				end
			end
		end

		if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
			HasAlreadyEnteredMarker, LastZone = true, currentZone
			LastZone = currentZone
			TriggerEvent('nb_vehicleshop:hasEnteredMarker', currentZone)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('nb_vehicleshop:hasExitedMarker', LastZone)
		end

		if letSleep then
			Citizen.Wait(500)
		end
	end
end)

-- Key controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) then
				if CurrentAction == 'shop_menu' then
					if Config.LicenseEnable then
						ESX.TriggerServerCallback('esx_license:checkLicense', function(hasDriversLicense)
							if hasDriversLicense then
								OpenShopMenu()
							else
								ESX.ShowNotification(_U('license_missing'))
							end
						end, GetPlayerServerId(PlayerId()), 'drive')
					else
						OpenShopMenu()
					end
				elseif CurrentAction == 'reseller_menu' then
					OpenResellerMenu()
				elseif CurrentAction == 'give_back_vehicle' then
					ESX.TriggerServerCallback('nb_vehicleshop:giveBackVehicle', function(isRentedVehicle)
						if isRentedVehicle then
							ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
							ESX.ShowNotification(_U('delivered'))
						else
							ESX.ShowNotification(_U('not_rental'))
						end
					end, ESX.Math.Trim(GetVehicleNumberPlateText(CurrentActionData.vehicle)))
				elseif CurrentAction == 'resell_vehicle' then
					ESX.TriggerServerCallback('nb_vehicleshop:resellVehicle', function(vehicleSold)
						if vehicleSold then
							ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
							ESX.ShowNotification(_U('vehicle_sold_for', CurrentActionData.label, ESX.Math.GroupDigits(CurrentActionData.price)))
						else
							ESX.ShowNotification(_U('not_yours'))
						end
					end, CurrentActionData.plate, CurrentActionData.model)
				elseif CurrentAction == 'boss_actions_menu' then
					OpenBossActionsMenu()
				end

				CurrentAction = nil
			end
		else
			Citizen.Wait(500)
		end
	end
end)

  
Citizen.CreateThread(function()
	RequestIpl('shr_int') -- Load walls and floor
  
	local interiorID = 7170
	LoadInterior(interiorID)
	EnableInteriorProp(interiorID, 'csr_beforeMission') -- Load large window
	RefreshInterior(interiorID)
end)