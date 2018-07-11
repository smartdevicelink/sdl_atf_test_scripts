---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. Mobile app is unsubscribed from module_1
-- 2. HMI sends OnInteriorVD with params changing for module_1
-- SDL must not sends OnInteriorVD to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerAppWOPTU, { 1 })
runner.Step("Activate app", common.activateApp, { 1 })

runner.Title("Test")

for _, mod in pairs(common.modules) do
  runner.Step("GetInteriorVehicleData with subscribe=true " .. mod, common.GetInteriorVehicleData,
    { mod, true, true, 1 })
  runner.Step("GetInteriorVehicleData with subscribe=false " .. mod, common.GetInteriorVehicleData,
    { mod, false, true, 1 })
  runner.Step("OnInteriorVehicleData for " .. mod, common.OnInteriorVD,
    { mod, false, 1 })
  runner.Step("GetInteriorVehicleData without subscribe parameter " .. mod, common.GetInteriorVehicleData,
    { mod, nil, true, 1 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
