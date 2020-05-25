-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL does not transfer a OnVehicleData notification to subscribed app if HMI sends the notification with
-- invalid `gearStatus` data
--
-- Preconditions:
-- 1) App is subscribed to `gearStatus` data.
-- In case:
-- 1) HMI sends the OnVehicleData notification with invalid `gearStatus` structure:
--  1) invalid parameter value
--  2) invalid parameter type
--  3) empty value
--  4) empty structure
-- SDL does:
--  a) ignore this notification.
--  b) not send OnVehicleData notification to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
local invalidValue = {
  emptyValue = "",
  invalidType = 12345,
  invalidParamValue = "Invalid parameter value"
}
local notExpected = 0
local emptyStructure = {}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { rpc })

common.Title("Test")
for parameter in common.spairs(common.getGearStatusParams()) do
  common.Title("Check for " .. parameter .. " parameter")
  for caseName, value in common.spairs(invalidValue) do
    common.Step("OnVehicleData notification with " .. caseName .. " for " .. parameter, common.sendOnVehicleData,
      { common.getCustomData(parameter,value), notExpected })
  end
end
common.Step("OnVehicleData with empty gearStatus structure", common.sendOnVehicleData, { emptyStructure, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
