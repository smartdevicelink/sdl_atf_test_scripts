---------------------------------------------------------------------------------------------------
-- Proposal:
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. App is subscribed to module_1, module_2
-- 2. App is unsubscribed from module_1
-- 3. App receives updated hashId after unsubscription
-- 4. Transport disconnect and reconnect are performed
-- 5. App starts registration with actual hashId after unexpected disconnect
-- SDL does:
-- 1. send RC.GetInteriorVD(subscribe=true, module_2) to HMI during resumption data
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
  common.wait(1000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("Add interiorVD subscription for " .. common.modules[1], common.GetInteriorVehicleData,
  { common.modules[1], true, 1, 1 })
runner.Step("Add interiorVD subscription for " .. common.modules[2], common.GetInteriorVehicleData,
  { common.modules[2], true, 1, 1 })
runner.Step("Unsubscribe from " .. common.modules[2], common.GetInteriorVehicleData,
  { common.modules[2], false, 1, 1 })

runner.Title("Test")
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption data", common.reRegisterApp,
  { 1, checkResumptionData, common.resumptionFullHMILevel})
runner.Step("Check subscription for " .. common.modules[1], common.GetInteriorVehicleData,
  { common.modules[1], false, 0, 0 })
runner.Step("Absence subscription for " .. common.modules[2], common.GetInteriorVehicleData,
  { common.modules[2], false, 1, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

