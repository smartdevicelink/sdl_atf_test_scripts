---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL does not transfer OnVehicleData notification to subscribed app if HMI sends notification
-- with invalid values of `windowStatus` structure params:
--    location: { col, row, level, colspan, rowspan, levelspan }
--    state: { approximatePosition, deviation }
--
-- In case:
-- 1) App is subscribed to `windowStatus` data.
-- 2) HMI sends the `windowStatus` structure with boundary values for one of the parameters in OnVehicleData notification:
-- SDL does:
--  a) process this notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local windowStatusDataMinValues = {
  location = { col = -1, row = -1, level = -1, colspan = 1, rowspan = 1, levelspan = 1 },
  stateMinvalue = 0
}
local maxValue = 100
local maxArraySize = {}
for i = 1, maxValue do
  maxArraySize[i] = common.getWindowStatusParams()[1]
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
for k in common.spairs(common.getWindowStatusParams()[1].state) do
  common.Step("OnVehicleData maxValue " .. k .. "=" .. maxValue, common.sendOnVehicleData,
    { common.getCustomData(k, "state", maxValue) })
  common.Step("OnVehicleData minValue " .. k .. "=" .. windowStatusDataMinValues.stateMinvalue, common.sendOnVehicleData,
    { common.getCustomData(k, "state", windowStatusDataMinValues.stateMinvalue) })
end

for k in common.spairs(common.getWindowStatusParams()[1].location) do
  common.Step("OnVehicleData maxValue " .. k .. "=" .. maxValue, common.sendOnVehicleData,
    { common.getCustomData(k, "location", maxValue) })
  common.Step("OnVehicleData minValue " .. k .. "=" .. windowStatusDataMinValues.location[k], common.sendOnVehicleData,
    { common.getCustomData(k, "location", windowStatusDataMinValues.location[k]) })
end
common.Step("OnVehicleData max windowStatus array size", common.sendOnVehicleData, { maxArraySize })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
