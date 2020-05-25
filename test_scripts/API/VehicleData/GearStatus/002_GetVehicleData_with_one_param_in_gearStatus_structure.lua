-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL successfully processes GetVehicleData response if gearStatus structure contains one parameter.
--
-- In case:
-- 1) App sends GetVehicleData(gearStatus=true) request.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends the `gearStatus` structure with only one parameter in GetVehicleData response.
-- SDL does:
--  a) respond with resultCode:`SUCCESS` to app with only one parameter.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for parameter in common.spairs(common.getGearStatusParams()) do
  if parameter == "transmissionType" then
    for _, value in common.spairs(common.transmissionTypeValues) do
      common.Step("HMI sends response with transmissionType=" .. value, common.getVehicleData,
        { { [parameter] = value } })
    end
  else
    for _, value in common.spairs(common.prndlEnumValues) do
      common.Step("HMI sends response with " .. parameter .. "=" .. value, common.getVehicleData,
        { { [parameter] = value } })
    end
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
