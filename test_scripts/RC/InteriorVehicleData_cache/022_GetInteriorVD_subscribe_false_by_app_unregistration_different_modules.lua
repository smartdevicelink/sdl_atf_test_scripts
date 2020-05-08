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
-- 2. Mobile app2 is subscribed to module_2
-- 3. Mobile app1 unregisters
-- 4. HMI sends OnInteriorVD for module_2
-- SDL must
-- 1. send GetInteriorVD(module_1, subscribe = false) request to HMI
-- 2. SDL sends OnInteriorVD to mobile app2
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

runner.Step("App1 GetInteriorVehicleData with subscribe=true " .. common.modules[1], common.GetInteriorVehicleData,
  { common.modules[1], true, true, 1 })
runner.Step("App2 GetInteriorVehicleData with subscribe=true " .. common.modules[2], common.GetInteriorVehicleData,
  { common.modules[2], true, true, 2 })
runner.Step("RC.GetInteriorVehicleData with subscribe=false by app1 unregistration " .. common.modules[1],
  common.unregistrationApp, { 1, true, common.modules[1] })
runner.Step("OnInteriorVehicleData for " .. common.modules[2], common.OnInteriorVD,
  { common.modules[2], true, 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
