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
-- 2. GetInteriorVD(subscribe=false,module_1) is requested
-- 3. GetInteriorVD(subscribe=true, module_1) is requested
-- 4. GetInteriorVD(subscribe=false, module_1) is requested
-- SDL does:
-- 1. process successful responses from HMI
-- 2. not send OnHashChange notification to mobile app by receiving first GetInteriorVD(subscribe=false,module_1) without subscription
-- 3. send OnHashChange notification to mobile app by receiving GetInteriorVD(subscribe=true,module_1)
-- 4. not send OnHashChange notification to mobile app by receiving first GetInteriorVD(subscribe=false,module_1) with subscription
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
  runner.Step("Absence of OnHashChange without subscription after GetInteriorVehicleData(false) for " .. moduleName,
    common.GetInteriorVehicleData, { moduleName, false, 1, 0 })
  runner.Step("OnHashChange after adding subscription for " .. moduleName, common.GetInteriorVehicleData,
    { moduleName, true, 1, 1 })
  runner.Step("OnHashChange with subscription after GetInteriorVehicleData(false) for " .. moduleName,
    common.GetInteriorVehicleData, { moduleName, false, 1, 1 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

