---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md
-- Description: The app is able to retrieve the parameter in case app version is equal to parameter version
-- parameter is listed in DB and API
-- In case:
-- 1) App is registered with syncMsgVersion=6.2
-- 2) New params in `FuelRange` structure have since=6.2 in API and DB
-- 3) App is subscribed to `FuelRange` data
-- 4) App requests GetVehicleData(fuelRange)
-- 5) HMI sends GetVehicleData response with new parameters in `FuelRange` structure
-- SDL does:
--  a) process the response successful
--  b) resend GetVehicleData response from HMI to mobile app as is
-- 6) HMI sends valid OnVehicleData notification with all parameters of `FuelRange` structure
-- SDL does:
--  a) process this notification and transfer it to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/Refactor_Fuel_Information/common')

-- [[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 6
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 2

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to fuelRange data", common.subUnScribeVD, { "SubscribeVehicleData", common.subUnsubParams })

common.Title("Test")
common.Step("App sends GetVehicleData for fuelRange", common.getVehicleData, { { common.allVehicleData } })
common.Step("OnVehicleData with all new fuelRange parameters", common.sendOnVehicleData, { { common.allVehicleData } })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
