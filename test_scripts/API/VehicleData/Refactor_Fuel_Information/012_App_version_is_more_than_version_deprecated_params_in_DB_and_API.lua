---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0256-Refactor-Fuel-Information-Related-Vehicle-Data.md
-- Description: SDL successfully process GetVehicleData with deprecated fuelLevel and fuelLevel_State
-- In case:
-- 1) App is registered with syncMsgVersion=7.0
-- 2) fuelLevel and fuelLevel_State params are deprecated since=6.2 in API and DB
-- 3) App requests GetVehicleData(fuelLevel and fuelLevel_State)
-- SDL does:
--  a) process the requests successful
--  b) resend GetVehicleData response from HMI to mobile app as is
-- 4) App sends SubscribeVehicleData with fuelLevel and fuelLevel_State request
-- 5) HMI responds with SUCCESS result to SubscribeVehicleData request
-- SDL does:
--  a) transfer this requests to HMI
--  b) respond with resultCode:"SUCCESS" to mobile application for fuelLevel and fuelLevel_State
-- 6) HMI sends valid OnVehicleData notification for `fuelLevel` and fuelLevel_State params
-- SDL does:
--  a) process this notification and transfer it to mobile
-- 7) App sends UnsubscribeVehicleData with fuelLevel and fuelLevel_State request
-- 8) HMI responds with SUCCESS result to UnsubscribeVehicleData request
-- SDL does:
--  a) transfer this requests to HMI
--  b) respond with resultCode:"SUCCESS" to mobile application for fuelLevel and fuelLevel_State
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/Refactor_Fuel_Information/common')

-- [[ Test Configuration ]]
config.application1.registerAppInterfaceParams.syncMsgVersion.majorVersion = 7
config.application1.registerAppInterfaceParams.syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local expected = 1

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("PTU", common.policyTableUpdate, { common.pTUpdateFunc })
common.Step("Activate App", common.activateApp)

for k, v in pairs(common.respForDeprecatedParam) do
  common.Title("Deprecated parameter: " .. k)
  common.Step("GetVehicleData successfully processed for " .. k, common.getVehicleData, { v, k })
  common.Step("App subscribes to deprecated " .. k, common.subUnScribeVD,
    { "SubscribeVehicleData", common.subVDdeprecatedParams[k] ,k } )
  common.Step("HMI sends OnVehicleData for " .. k, common.sendOnVehicleData, { v, expected, k })
  common.Step("App unsubscribes from the deprecated " .. k, common.subUnScribeVD,
    {"UnsubscribeVehicleData", common.subVDdeprecatedParams[k], k })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
