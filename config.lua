Config                            = {}
Config.Locale                     = 'en'
-- Markers
Config.DrawDistance               = 20.0
Config.MarkerColor                = { r = 0, g = 255, b = 0 }
Config.allign                     = 'top-right'     
Config.job                        = 'cardealer'

-- Basics
Config.EnablePlayerManagement     = false 
Config.EnableOwnedVehicles        = true
Config.EnableSocietyOwnedVehicles = true 
Config.ResellPercentage           = 35
Config.LicenseEnable              = false 

-- ESX
Config.ESXlimit = true 
--[[ 
True = limit
false = weight ]]
Config.UseESXNotify = false
--[[ 
True = ESX Notify
false = Mythic Notify ]]

-- Plates
Config.PlateLetters  = 4
Config.PlateNumbers  = 4
Config.PlateUseSpace = false

-- Shops
Config.Zones = {

	ShopEntering = {
		Pos   = vector3(-33.7, -1102.0, 25.4),
		Size  = {x = 1.5, y = 1.5, z = 1.0},
		Type  = 1
	},

	testdrive = {
		Pos   = vector3(-1733.25, -2901.43, 13.94),
		Heading = 326
	},

	ShopInside = {
		Pos     = vector3(-47.5, -1097.2, 25.4),
		Size    = {x = 1.5, y = 1.5, z = 1.0},
		Heading = -20.0,
		Type    = -1
	},

	ShopOutside = {
		Pos     = vector3(-28.6, -1085.6, 25.5),
		Size    = {x = 1.5, y = 1.5, z = 1.0},
		Heading = 330.0,
		Type    = -1
	},

	BossActions = {
		Pos   = vector3(-32.0, -1114.2, 25.4),
		Size  = {x = 1.5, y = 1.5, z = 1.0},
		Type  = -1
	},

	GiveBackVehicle = {
		Pos   = vector3(-18.2, -1078.5, 25.6),
		Size  = {x = 3.0, y = 3.0, z = 1.0},
		Type  = (Config.EnablePlayerManagement and 1 or -1)
	},

	ResellVehicle = {
		Pos   = vector3(-44.6, -1080.7, 25.6),
		Size  = {x = 3.0, y = 3.0, z = 1.0},
		Type  = 1
	}

}