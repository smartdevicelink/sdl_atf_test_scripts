---------------------------------------------------------------------------------------------------
-- Proposal:
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1. App1 is subscribed to module_1
-- 2. App2 is subscribed to module_2
-- 3. Transport disconnect and reconnect are performed
-- 4. Apps start registration with actual hashId after unexpected disconnect
-- SDL does:
-- 1. send RC.GetInteriorVD(subscribe=true, modules_1) to HMI during resumption data for app1
-- 2. send RC.GetInteriorVD(subscribe=true, modules_2) to HMI during resumption data for app2
-- 3. respond RAI(SUCCESS) to mobile apps
-- 4. update hashId after successful resumption
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/InteriorVehicleData/common_resumptionsInteriorVD')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function checkResumptionData()
  EXPECT_HMICALL("RC.GetInteriorVehicleData",
   { moduleType = common.modules[1], subscribe = true },
   { moduleType = common.modules[2], subscribe = true })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
        { moduleData = common.getModuleControlData(data.params.moduleData.moduleType), subscribe = true })
    end)
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App1 registration", common.registerAppWOPTU)
runner.Step("App2 registration", common.registerAppWOPTU, { 2 })
runner.Step("App1 activation", common.activateApp, { 1 })
runner.Step("App2 activation", common.activateApp, { 2, "NOT_AUDIBLE" })
runner.Step("Add interiorVD subscription for " .. common.modules[1] .. " for app1",
  common.GetInteriorVehicleData, { common.modules[1], true, 1, 1 })
runner.Step("Add interiorVD subscription for " .. common.modules[2] .. " for app2",
  common.GetInteriorVehicleData, { common.modules[2], true, 1, 1, 2 })

runner.Title("Test")
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Open service for app1", common.openRPCservice, { 1 })
runner.Step("Open service for app2", common.openRPCservice, { 2 })
runner.Step("Reregister App resumption data", common.reRegisterApps,
  { checkResumptionData })
runner.Step("Check subscription for app1", common.GetInteriorVehicleData, { common.modules[1], false, 0, 0 })
runner.Step("Check subscription for app2", common.GetInteriorVehicleData, { common.modules[2], false, 0, 0, 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

