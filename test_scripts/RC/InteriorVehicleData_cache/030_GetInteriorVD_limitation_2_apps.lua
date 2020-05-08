---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. In .ini file GetInteriorVehicleDataRequest = 10, 20
-- 2. Mobile app1 sends 5 GetInteriorVD(module_1, without subscribe parameter) requests per 20 sec
-- 3. Mobile app2 sends 5 GetInteriorVD(module_1, without subscribe parameter) requests per 20 sec
-- 4. Mobile app1 sends 6th GetInteriorVD(module_1, without subscribe parameter) requests per 20 sec
-- 5. Mobile app2 sends 6th GetInteriorVD(module_1, without subscribe parameter) requests per 20 sec
-- SDL must
-- 1. reject 6th GetInteriorVD(module_1, without subscribe parameter) request with result code REJECTED from both apps
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update GetInteriorVehicleDataRequest=10,20", common.setGetInteriorVehicleDataRequestValue, {"10,20"})
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app1", common.registerAppWOPTU, { 1 })
runner.Step("Register app2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app1", common.activateApp, { 1 })
runner.Step("Activate app2", common.activateApp, { 2 })

runner.Title("Test")

for i=1,5 do
  runner.Step("App1 GetInteriorVehicleData without subscribe parameter CLIMATE" .. i, common.GetInteriorVehicleData,
    {"CLIMATE", nil, true, 1 })
  runner.Step("App2 GetInteriorVehicleData without subscribe parameter CLIMATE" .. i, common.GetInteriorVehicleData,
    {"CLIMATE", nil, true, 2 })
end
runner.Step("App1 GetInteriorVehicleData REJECTED CLIMATE", common.GetInteriorVehicleDataRejected,
  {"CLIMATE", nil, 1 })
runner.Step("App2 GetInteriorVehicleData REJECTED CLIMATE", common.GetInteriorVehicleDataRejected,
  {"CLIMATE", nil, 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
