---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL processes GetVehicleData if HMI responds with boundary values for `windowStatus` structure:
--    location: { col, row, level, colspan, rowspan, levelspan }
--    state: { approximatePosition, deviation }
--    windowStatus array size
--
-- In case:
-- 1) App sends GetVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- 2) SDL transfers this request to HMI.
-- 3) HMI sends GetVehicleData response with `windowStatus` structure with boundary values for one of the parameters
-- from `Grid` and `WindowState` structures.
-- SDL does:
--  a)  process this response and transfer it to mobile app.
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

common.Title("Test")
for k in common.spairs(common.getWindowStatusParams()[1].state) do
  common.Step("GetVehicleData maxValue " .. k .. "=" .. maxValue, common.getVehicleData,
    { common.getCustomData(k, "state", maxValue) })
  common.Step("GetVehicleData minValue " .. k .. "=" .. windowStatusDataMinValues.stateMinvalue, common.getVehicleData,
    { common.getCustomData(k, "state", windowStatusDataMinValues.stateMinvalue) })
end

for k in common.spairs(common.getWindowStatusParams()[1].location) do
  common.Step("GetVehicleData maxValue " .. k .. "=" .. maxValue, common.getVehicleData,
    { common.getCustomData(k, "location", maxValue) })
  common.Step("GetVehicleData minValue " .. k .. "=" .. windowStatusDataMinValues.location[k], common.getVehicleData,
    { common.getCustomData(k, "location", windowStatusDataMinValues.location[k]) })
end
common.Step("GetVehicleData max windowStatus array size", common.getVehicleData, { maxArraySize })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
