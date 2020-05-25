-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL sends response with `GENERIC_ERROR` resultCode to mobile app if HMI sends response with
--  invalid `gearStatus` structure
--
-- In case:
-- 1) App sends GetVehicleData(gearStatus=true) request.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends the invalid `gearStatus` structure in GetVehicleData response:
--  1) invalid parameter value
--  2) invalid parameter type
--  3) empty value
--  4) empty structure
-- SDL does:
--  a) respond `GENERIC_ERROR` to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "GetVehicleData"
local invalidValue = {
  emptyValue = "",
  invalidType = 12345,
  invalidParamValue = "Invalid parameter value"
}
local emptyStructure = {}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for parameter in common.spairs(common.getGearStatusParams()) do
  common.Title("Check for " .. parameter .. " parameter")
  for caseName, value in common.spairs(invalidValue) do
    common.Step("HMI sends response with " ..caseName .. " for ".. parameter, common.invalidDataFromHMI,
      { rpc, common.getCustomData(parameter, value) } )
  end
end
common.Step("HMI sends response with empty gearStatus structure", common.invalidDataFromHMI, { rpc, emptyStructure })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
