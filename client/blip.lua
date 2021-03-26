
Citizen.CreateThread(function()
	local blip = AddBlipForCoord(Config.Zones.ShopEntering.Pos)

	SetBlipSprite (blip, 326)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, 1.0)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName(_U('car_dealer'))
	EndTextCommandSetBlipName(blip)
end)