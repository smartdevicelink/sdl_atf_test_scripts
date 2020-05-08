---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0178-GetInteriorVehicleData.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case
-- 1. In .ini file GetInteriorVehicleDataRequest = 5, 10
-- 2. App is subscribed to module_1
-- 3. Mobile app sends 7 GetInteriorVD(module_1, without subscribe parameter) requests per 10 sec
-- SDL must
-- 1. process successful all requests and does not sends GetInteriorVD requests to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/InteriorVehicleData_cache/common_interiorVDcache')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update GetInteriorVehicleDataRequest=5,10", common.setGetInteriorVehicleDataRequestValue, {"5,10"})
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register app", common.registerAppWOPTU, { 1 })
runner.Step("Activate app", common.activateApp, { 1 })
runner.Step("GetInteriorVehicleData with subscribe=true", common.GetInteriorVehicleData,
  {"CLIMATE", true, true, 1 })

runner.Title("Test")

for i=1,7 do
  runner.Step("GetInteriorVehicleData without subscribe parameter " .. i, common.GetInteriorVehicleData,
    {"CLIMATE", nil, false, 1 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
