---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL transfers OnVehicleData notification to app if HMI sends it with only one parameter
--  in `gearStatus` structure.
--
-- Preconditions:
-- 1) App is subscribed to `gearStatus` data.
-- In case:
-- 1) HMI sends valid OnVehicleData notification with only one parameter in `gearStatus` structure.
-- SDL does:
--  a) process this notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { rpc })

common.Title("Test")
for parameter in common.spairs(common.getGearStatusParams()) do
  if parameter == "transmissionType" then
    for _, value in common.spairs(common.transmissionTypeValues) do
      common.Step("OnVehicleData with transmissionType=" .. value, common.sendOnVehicleData,
        { { [parameter] = value } })
    end
  else
    for _, value in common.spairs(common.prndlEnumValues) do
      common.Step("OnVehicleData with " .. parameter .. "=" .. value, common.sendOnVehicleData,
        { { [parameter] = value } })
    end
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
