---------------------------------------------------------------------------------------------------
-- Proposal:
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. App is subscribed to module_1
-- 2. IGN_OFF and IGN_ON are  performed
-- 3. App starts registration with actual hashId after unexpected disconnect
-- SDL does:
-- 1. send RC.GetInteriorVD(subscribe=true, module_1) to HMI during resumption data
-- 2. respond RAI(SUCCESS) to mobile app
-- 3. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/InteriorVehicleData/common_resumptionsInteriorVD')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function checkResumptionData()
  common.checkModuleResumptionData(common.modules[1])
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("Add interiorVD subscription", common.GetInteriorVehicleData, { common.modules[1], true, 1, 1 })

runner.Title("Test")
runner.Step("IGNITION_OFF", common.ignitionOff)
runner.Step("IGNITION_ON", common.start)
runner.Step("Reregister App resumption data", common.reRegisterApp,
  { 1, checkResumptionData, common.resumptionFullHMILevel})
runner.Step("Check subscription", common.GetInteriorVehicleData, { common.modules[1], false, 0, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

