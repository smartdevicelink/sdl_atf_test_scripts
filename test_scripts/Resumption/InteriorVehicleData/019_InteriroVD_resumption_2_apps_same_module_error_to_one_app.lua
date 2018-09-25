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
-- 2. App2 is subscribed to module_1
-- 3. Transport disconnect and reconnect are performed
-- 4. Apps reregister with actual HashId
-- 5. RC.GetInteriorVD(subscribe=true, module_1) is sent from SDL to HMI during resumption for app1
-- 6. HMI responds with error resultCode to RC.GetInteriorVD(subscribe=true, module_1) request
-- 7. RC.GetInteriorVD(subscribe=true, module_1) is sent from SDL to HMI during resumption for app2
-- 8. HMI responds with success to remaining requests
-- SDL does:
-- 1. process unsuccess response from HMI
-- 2. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to app1
-- 3. respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS) to app2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/InteriorVehicleData/common_resumptionsInteriorVD')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function checkResumptionData()
  EXPECT_HMICALL("RC.GetInteriorVehicleData",
   { moduleType = common.modules[1], subscribe = true })
  :Do(function(exp, data)
      if exp.occurences == 1 then
        common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "Error message")
      else
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS",
          { moduleData = common.getModuleControlData(data.params.moduleType), subscribe = true })
      end
    end)
  :Times(2)
  common.wait()
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
runner.Step("Add interiorVD subscription for " .. common.modules[1] .. " for app2",
  common.GetInteriorVehicleData, { common.modules[1], true, 0, 1, 2 })

runner.Title("Test")
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Open service for app1", common.openRPCservice, { 1 })
runner.Step("Open service for app2", common.openRPCservice, { 2 })
runner.Step("Reregister App resumption data", common.reRegisterApps,
  { checkResumptionData, "RESUME_FAILED" })
runner.Step("Check subscription for app1", common.GetInteriorVehicleData, { common.modules[1], false, 1, 0 })
runner.Step("Check subscription for app2", common.GetInteriorVehicleData, { common.modules[2], false, 1, 1, 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

