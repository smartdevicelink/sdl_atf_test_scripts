-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL sends response with `GENERIC_ERROR` resultCode to a mobile app
--  if HMI sends a response with invalid data in `gearStatus` structure.
--
-- In case:
-- 1) App sends SubscribeVehicleData(gearStatus=true) request
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends the invalid `gearStatus` structure in SubscribeVehicleData response:
--  1) invalid parameter value
--  2) invalid parameter type
--  3) empty value
-- SDL does:
--  a) respond `GENERIC_ERROR` to mobile app
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

--[[ Local Functions ]]
local function getData(pValue)
  local params = common.getGearStatusSubscriptionResData()
  params.dataType = pValue
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for caseName, value in common.spairs(invalidValue) do
  common.Step("HMI sends response with " .. caseName, common.invalidDataFromHMI, { rpc, getData(value) })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
