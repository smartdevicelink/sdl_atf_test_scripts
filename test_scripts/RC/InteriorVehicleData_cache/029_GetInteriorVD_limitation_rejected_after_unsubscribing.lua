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
-- 2. App is subscribed to module_1 (request 1)
-- 3. Mobile app sends GetInteriorVD(module_1, without subscribe parameter)
-- 4. App is unsubscribe from module_1(request 2)
-- 5. Mobile app sends 9 GetInteriorVD(module_1, without subscribe parameter) requests per 20 sec
-- SDL must
-- 1. reject 9th(request 11) GetInteriorVD(module_1, without subscribe parameter) request with result code REJECTED
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
runner.Step("GetInteriorVehicleData with subscribe=true", common.GetInteriorVehicleData,
  {"CLIMATE", true, true, 1 })
runner.Step("GetInteriorVehicleData without subscribe", common.GetInteriorVehicleData,
  {"CLIMATE", nil, false, 1 })
runner.Step("GetInteriorVehicleData with subscribe=false", common.GetInteriorVehicleData,
  {"CLIMATE", false, true, 1 })

runner.Title("Test")

for i=1,8 do
  runner.Step("GetInteriorVehicleData without subscribe parameter " .. i, common.GetInteriorVehicleData,
    {"CLIMATE", nil, true, 1 })
end
runner.Step("GetInteriorVehicleData REJECTED", common.GetInteriorVehicleDataRejected,
  {"CLIMATE", nil, 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
