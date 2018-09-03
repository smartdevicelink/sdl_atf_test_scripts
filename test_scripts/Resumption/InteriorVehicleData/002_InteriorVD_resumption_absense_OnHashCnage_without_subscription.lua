---------------------------------------------------------------------------------------------------
-- Proposal:
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. App is not subscribed to modules
-- 2. GetInteriorVD(Module_1) without subscribe parameter is requested
-- SDL does:
-- 1. Process successful response from HMI
-- 2. not send OnHashChange notification with updated hashId value to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/InteriorVehicleData/common_resumptionsInteriorVD')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
for _, moduleName in pairs(common.modules)do
  runner.Step("Absence of OnHashChange after GetInteriorVehicleData without subscription parameter for " .. moduleName,
    common.GetInteriorVehicleData, { moduleName, nil, 1, 0 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
