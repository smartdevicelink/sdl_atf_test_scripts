---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. Mobile app1 is subscribed to module_1
-- 2. Mobile app2 is subscribed to module_1
-- 3. Mobile app1 sends GetInteriorVD(module_1, subscribe = false) request
-- 4. Mobile app2 sends GetInteriorVD(module_1, subscribe = false) request
-- SDL must
-- 1. not send GetInteriorVD(module_1, subscribe = false) request to HMI by processing requst from app1
-- 2. send GetInteriorVD(module_1, subscribe = false) request to HMI by processing requst from app2
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
runner.Step("Register app1", common.registerAppWOPTU, { 1 })
runner.Step("Register app2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app1", common.activateApp, { 1 })
runner.Step("Activate app2", common.activateApp, { 2 })

runner.Title("Test")

for _, mod in pairs(common.modules) do
  runner.Step("App1 GetInteriorVehicleData with subscribe=true " .. mod, common.GetInteriorVehicleData,
    { mod, true, true, 1 })
  runner.Step("App2 GetInteriorVehicleData with subscribe=true " .. mod, common.GetInteriorVehicleData,
    { mod, true, false, 2 })
  runner.Step("App1 GetInteriorVehicleData with subscribe=false " .. mod, common.GetInteriorVehicleData,
    { mod, false, false, 1 })
  runner.Step("App2 GetInteriorVehicleData with subscribe=false " .. mod, common.GetInteriorVehicleData,
    { mod, false, true, 2 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
