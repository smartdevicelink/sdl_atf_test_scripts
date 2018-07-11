---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. In .ini file GetInteriorVehicleDataRequest = 10,20
-- 2. Mobile app sends 11 GetInteriorVD(module_1, without subscribe parameter) requests per 20 sec
-- SDL must
-- 1. reject 11th GetInteriorVD(module_1, without subscribe parameter) request with result code REJECTED
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
runner.Step("Register app", common.registerAppWOPTU, { 1 })
runner.Step("Activate app", common.activateApp, { 1 })

runner.Title("Test")

for i=1,10 do
  runner.Step("GetInteriorVehicleData without subscribe parameter " .. i, common.GetInteriorVehicleData,
    {"CLIMATE", nil, true, 1 })
end
runner.Step("GetInteriorVehicleData REJECTED", common.GetInteriorVehicleDataRejected,
  {"CLIMATE", nil, 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
