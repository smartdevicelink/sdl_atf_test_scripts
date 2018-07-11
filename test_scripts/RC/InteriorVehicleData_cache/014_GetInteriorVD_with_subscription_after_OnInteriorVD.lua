---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. Mobile app is subscribed to module_1
-- 2. HMI sends OnInteriorVD with params changing for module_1
-- 3. Mobile app sends GetInteriorVD(module_1, without subscribe parameter) request
-- SDL must
-- 1. not send GetInteriorVD request to HMI
-- 2. send GetinteriorVD response to mobile app with actual data
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
  runner.Step("OnInteriorVehicleData for " .. mod, common.OnInteriorVD,
    { mod, true, 1 })
  runner.Step("GetInteriorVehicleData without subscribe " .. mod, common.GetInteriorVehicleData,
    { mod, nil, false, 1 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
