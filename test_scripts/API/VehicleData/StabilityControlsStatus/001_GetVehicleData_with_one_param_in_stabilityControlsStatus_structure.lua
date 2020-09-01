---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/edit/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: SDL successfully processes GetVehicleData response if 'stabilityControlsStatus' structure contains one parameter.
--
-- In case:
-- 1) App sends GetVehicleData(stabilityControlsStatus=true) request.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends the 'stabilityControlsStatus' structure with only one parameter in GetVehicleData response.
-- SDL does:
--  a) respond with resultCode:'SUCCESS' to app with only one parameter.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local param = "stabilityControlsStatus"

local vehicleDataStatusEnumValues = {
  "NO_DATA_EXISTS",
  "OFF",
  "ON"
}

local stabilityControlsStatusData = {
  escSystem = vehicleDataStatusEnumValues,
  trailerSwayControl = vehicleDataStatusEnumValues
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Title("VD parameter: " .. param)
for sub_param, data in common.spairs(stabilityControlsStatusData) do
  for _, value in common.spairs(data) do
    common.Step("RPC " .. common.rpc.get .. " param " .. sub_param .. "=" .. value,
      common.getVehicleData, { param, { [sub_param] = value } })
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
