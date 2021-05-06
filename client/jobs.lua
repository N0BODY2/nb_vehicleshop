function OpenGetStocksMenu()
    ESX.TriggerServerCallback('nb_vehicleshop:getStockItems', function (items)
        local elements = {}

        for i=1, #items, 1 do
            table.insert(elements, {
                label = 'x' .. items[i].count .. ' ' .. items[i].label,
                value = items[i].name
            })
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
            title    = _U('dealership_stock'),
            align    = Config.allign,
            elements = elements
        }, function (data, menu)
            local itemName = data.current.value

            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
                title = _U('amount')
            }, function (data2, menu2)
                local count = tonumber(data2.value)

                if count == nil then
                    ESX.ShowNotification(_U('quantity_invalid'))
                else
                    TriggerServerEvent('nb_vehicleshop:getStockItem', itemName, count)
                    menu2.close()
                    menu.close()
                    OpenGetStocksMenu()
                end
            end, function (data2, menu2)
                menu2.close()
            end)

        end, function (data, menu)
            menu.close()
        end)
    end)
end

function OpenPutStocksMenu()
    ESX.TriggerServerCallback('nb_vehicleshop:getPlayerInventory', function (inventory)
        local elements = {}

        for i=1, #inventory.items, 1 do
            local item = inventory.items[i]

            if item.count > 0 then
                table.insert(elements, {
                    label = item.label .. ' x' .. item.count,
                    type = 'item_standard',
                    value = item.name
                })
            end
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
            title    = _U('inventory'),
            align    = Config.allign,
            elements = elements
        }, function (data, menu)
            local itemName = data.current.value

            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
                title = _U('amount')
            }, function (data2, menu2)
                local count = tonumber(data2.value)

                if count == nil then
                    ESX.ShowNotification(_U('quantity_invalid'))
                else
                    TriggerServerEvent('nb_vehicleshop:putStockItems', itemName, count)
                    menu2.close()
                    menu.close()
                    OpenPutStocksMenu()
                end
            end, function (data2, menu2)
                menu2.close()
            end)
        end, function (data, menu)
            menu.close()
        end)
    end)
end

function OpenBossActionsMenu()
    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'reseller',{
        title    = _U('dealer_boss'),
        align    = Config.allign,
        elements = {
            {label = _U('boss_actions'), value = 'boss_actions'},
            {label = _U('boss_sold'), value = 'sold_vehicles'}
    }}, function (data, menu)
        if data.current.value == 'boss_actions' then
            TriggerEvent('esx_society:openBossMenu', Config.job, function(data2, menu2)
                menu2.close()
            end)
        elseif data.current.value == 'sold_vehicles' then

            ESX.TriggerServerCallback('nb_vehicleshop:getSoldVehicles', function(customers)
                local elements = {
                    head = { _U('customer_client'), _U('customer_model'), _U('customer_plate'), _U('customer_soldby'), _U('customer_date') },
                    rows = {}
                }

                for i=1, #customers, 1 do
                    table.insert(elements.rows, {
                        data = customers[i],
                        cols = {
                            customers[i].client,
                            customers[i].model,
                            customers[i].plate,
                            customers[i].soldby,
                            customers[i].date
                        }
                    })
                end

                ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'sold_vehicles', elements, function(data2, menu2)

                end, function(data2, menu2)
                    menu2.close()
                end)
            end)
        end

    end, function (data, menu)
        menu.close()

        CurrentAction     = 'boss_actions_menu'
        CurrentActionMsg  = _U('shop_menu')
        CurrentActionData = {}
    end)
end

function OpenResellerMenu()
    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'reseller', {
        title    = _U('car_dealer'),
        align    = Config.allign,
        elements = {
            {label = _U('buy_vehicle'),                    value = 'buy_vehicle'},
            {label = _U('pop_vehicle'),                    value = 'pop_vehicle'},
            {label = _U('depop_vehicle'),                  value = 'depop_vehicle'},
            {label = _U('return_provider'),                value = 'return_provider'},
            {label = _U('create_bill'),                    value = 'create_bill'},
            {label = _U('get_rented_vehicles'),            value = 'get_rented_vehicles'},
            {label = _U('set_vehicle_owner_sell'),         value = 'set_vehicle_owner_sell'},
            {label = _U('set_vehicle_owner_rent'),         value = 'set_vehicle_owner_rent'},
            {label = _U('set_vehicle_owner_sell_society'), value = 'set_vehicle_owner_sell_society'},
            {label = _U('deposit_stock'),                  value = 'put_stock'},
            {label = _U('take_stock'),                     value = 'get_stock'}
        }
    }, function (data, menu)
        local action = data.current.value

        if action == 'buy_vehicle' then
            OpenShopMenu()
        elseif action == 'put_stock' then
            OpenPutStocksMenu()
        elseif action == 'get_stock' then
            OpenGetStocksMenu()
        elseif action == 'pop_vehicle' then
            OpenPopVehicleMenu()
        elseif action == 'depop_vehicle' then
            DeleteShopInsideVehicles()
        elseif action == 'return_provider' then
            ReturnVehicleProvider()
        elseif action == 'create_bill' then

            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
            if closestPlayer == -1 or closestDistance > 3.0 then
                ESX.ShowNotification(_U('no_players'))
                return
            end

            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'set_vehicle_owner_sell_amount', {
                title = _U('invoice_amount')
            }, function (data2, menu2)
                local amount = tonumber(data2.value)

                if amount == nil then
                    ESX.ShowNotification(_U('invalid_amount'))
                else
                    menu2.close()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

                    if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification(_U('no_players'))
                    else
                        TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_vehicle', _U('car_dealer'), tonumber(data2.value))
                    end
                end
            end, function (data2, menu2)
                menu2.close()
            end)

        elseif action == 'get_rented_vehicles' then
            OpenRentedVehiclesMenu()
        elseif action == 'set_vehicle_owner_sell' then

            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

            if closestPlayer == -1 or closestDistance > 3.0 then
                ESX.ShowNotification(_U('no_players'))
            else
                local newPlate     = GeneratePlate()
                local vehicleProps = ESX.Game.GetVehicleProperties(LastVehicles[#LastVehicles])
                local model        = CurrentVehicleData.model
                vehicleProps.plate = newPlate
                SetVehicleNumberPlateText(LastVehicles[#LastVehicles], newPlate)

                TriggerServerEvent('nb_vehicleshop:sellVehicle', model)
                TriggerServerEvent('nb_vehicleshop:addToList', GetPlayerServerId(closestPlayer), model, newPlate)

                if Config.EnableOwnedVehicles then
                    TriggerServerEvent('nb_vehicleshop:setVehicleOwnedPlayerId', GetPlayerServerId(closestPlayer), vehicleProps)
                    ESX.ShowNotification(_U('vehicle_set_owned', vehicleProps.plate, GetPlayerName(closestPlayer)))
                else
                    ESX.ShowNotification(_U('vehicle_sold_to', vehicleProps.plate, GetPlayerName(closestPlayer)))
                end
            end

        elseif action == 'set_vehicle_owner_sell_society' then

            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

            if closestPlayer == -1 or closestDistance > 3.0 then
                ESX.ShowNotification(_U('no_players'))
            else
                ESX.TriggerServerCallback('esx:getOtherPlayerData', function (xPlayer)

                    local newPlate     = GeneratePlate()
                    local vehicleProps = ESX.Game.GetVehicleProperties(LastVehicles[#LastVehicles])
                    local model        = CurrentVehicleData.model
                    vehicleProps.plate = newPlate
                    SetVehicleNumberPlateText(LastVehicles[#LastVehicles], newPlate)
                    TriggerServerEvent('nb_vehicleshop:sellVehicle', model)
                    TriggerServerEvent('nb_vehicleshop:addToList', GetPlayerServerId(closestPlayer), model, newPlate)

                    if Config.EnableSocietyOwnedVehicles then
                        TriggerServerEvent('nb_vehicleshop:setVehicleOwnedSociety', xPlayer.job.name, vehicleProps)
                        ESX.ShowNotification(_U('vehicle_set_owned', vehicleProps.plate, GetPlayerName(closestPlayer)))
                    else
                        ESX.ShowNotification(_U('vehicle_sold_to', vehicleProps.plate, GetPlayerName(closestPlayer)))
                    end

                end, GetPlayerServerId(closestPlayer))
            end

        elseif action == 'set_vehicle_owner_rent' then

            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'set_vehicle_owner_rent_amount', {
                title = _U('rental_amount')
            }, function (data2, menu2)
                local amount = tonumber(data2.value)

                if amount == nil then
                    ESX.ShowNotification(_U('invalid_amount'))
                else
                    menu2.close()

                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

                    if closestPlayer == -1 or closestDistance > 5.0 then
                        ESX.ShowNotification(_U('no_players'))
                    else
                        local newPlate     = 'RENT' .. string.upper(ESX.GetRandomString(4))
                        local vehicleProps = ESX.Game.GetVehicleProperties(LastVehicles[#LastVehicles])
                        local model        = CurrentVehicleData.model
                        vehicleProps.plate = newPlate
                        SetVehicleNumberPlateText(LastVehicles[#LastVehicles], newPlate)
                        TriggerServerEvent('nb_vehicleshop:rentVehicle', model, vehicleProps.plate, GetPlayerName(closestPlayer), CurrentVehicleData.price, amount, GetPlayerServerId(closestPlayer))

                        if Config.EnableOwnedVehicles then
                            TriggerServerEvent('nb_vehicleshop:setVehicleOwnedPlayerId', GetPlayerServerId(closestPlayer), vehicleProps)
                        end

                        ESX.ShowNotification(_U('vehicle_set_rented', vehicleProps.plate, GetPlayerName(closestPlayer)))
                        TriggerServerEvent('nb_vehicleshop:setVehicleForAllPlayers', vehicleProps, Config.Zones.ShopInside.Pos.x, Config.Zones.ShopInside.Pos.y, Config.Zones.ShopInside.Pos.z, 5.0)
                    end
                end
            end, function (data2, menu2)
                menu2.close()
            end)
        end
    end, function (data, menu)
        menu.close()

        CurrentAction     = 'reseller_menu'
        CurrentActionMsg  = _U('shop_menu')
        CurrentActionData = {}
    end)
end

function OpenPopVehicleMenu()
    ESX.TriggerServerCallback('nb_vehicleshop:getCommercialVehicles', function (vehicles)
        local elements = {}

        for i=1, #vehicles, 1 do
            table.insert(elements, {
                label = ('%s [VehicleShop <span style="color:green;">%s</span>]'):format(vehicles[i].name, _U('generic_shopitem', ESX.Math.GroupDigits(vehicles[i].price))),
                value = vehicles[i].name
            })
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'commercial_vehicles', {
            title    = _U('vehicle_dealer'),
            align    = Config.allign,
            elements = elements
        }, function (data, menu)
            local model = data.current.value

            DeleteShopInsideVehicles()

            ESX.Game.SpawnVehicle(model, Config.Zones.ShopInside.Pos, Config.Zones.ShopInside.Heading, function (vehicle)
                table.insert(LastVehicles, vehicle)

                for i=1, #Vehicles, 1 do
                    if model == Vehicles[i].model then
                        CurrentVehicleData = Vehicles[i]
                        break
                    end
                end
            end)
        end, function (data, menu)
            menu.close()
        end)
    end)
end

function OpenRentedVehiclesMenu()
    ESX.TriggerServerCallback('nb_vehicleshop:getRentedVehicles', function (vehicles)
        local elements = {}

        for i=1, #vehicles, 1 do
            table.insert(elements, {
                label = ('%s: %s - <span style="color:orange;">%s</span>'):format(vehicles[i].playerName, vehicles[i].name, vehicles[i].plate),
                value = vehicles[i].name
            })
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'rented_vehicles', {
            title    = _U('rent_vehicle'),
            align    = Config.allign,
            elements = elements
        }, nil, function (data, menu)
            menu.close()
        end)
    end)
end