---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/edit/master/proposals/0253-New-vehicle-data-StabilityControlsStatus.md
--
-- Description: SDL transfers OnVehicleData notification to app if HMI sends it with only one parameter
--  in 'stabilityControlsStatus' structure.
--
-- In case:
-- 1) App is subscribed to 'stabilityControlsStatus' data.
-- 2) HMI sends valid OnVehicleData notification with only one parameter in 'stabilityControlsStatus' structure.
-- SDL does:
--  a) process this notification and transfer it to mobile app.
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
common.Step("RPC " .. common.rpc.sub, common.processSubscriptionRPC, { common.rpc.sub, param })

common.Title("Test")
common.Title("VD parameter: " .. param)
for sub_param, data in common.spairs(stabilityControlsStatusData) do
  for _, value in common.spairs(data) do
    common.Step("RPC " .. common.rpc.on .. " param " .. sub_param .. "=" .. value,
      common.sendOnVehicleData, { param, common.isExpected, { [sub_param] = value } })
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
