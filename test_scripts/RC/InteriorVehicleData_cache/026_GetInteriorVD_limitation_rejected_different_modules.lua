---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:In case
-- In case
-- 1. In .ini file GetInteriorVehicleDataRequest = 10, 20
-- 2. Mobile app sends 11 GetInteriorVD(module_1, without subscribe parameter) requests per 20 sec
-- 3. Mobile app sends GetInteriorVD(module_2, without subscribe parameter) request
-- SDL must
-- 1. reject 11th GetInteriorVD(module_1, without subscribe parameter) request with result code REJECTED
-- 2. Process successful GetInteriorVD(module_2, without subscribe parameter) request
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
runner.Step("Activate app1", common.activateApp, { 1 })

runner.Title("Test")

for i=1,10 do
  runner.Step("App1 GetInteriorVehicleData without subscribe parameter CLIMATE" .. i, common.GetInteriorVehicleData,
    {"CLIMATE", nil, true, 1 })
end
runner.Step("App1 GetInteriorVehicleData REJECTED CLIMATE", common.GetInteriorVehicleDataRejected,
  {"CLIMATE", nil, 1 })
runner.Step("App1 GetInteriorVehicleData without subscribe parameter RADIO", common.GetInteriorVehicleData,
  { "RADIO", nil, true, 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
