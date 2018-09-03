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
-- 2. Transport disconnect and reconnect are performed
-- 3. App reregisters with actual HashId
-- 4. RC.GetInteriorVD(subscribe=true, module_1) is sent from SDL to HMI during resumption
-- 5. HMI responds with error resultCode to RC.GetInteriorVD request
-- SDL does:
-- 1. process unsuccess response from HMI
-- 2. respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application
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
  :Do(function(_, data)
      common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "Error message")
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("Add interiorVD subscription", common.GetInteriorVehicleData, { common.modules[1], true, 1, 1 })

runner.Title("Test")
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("Reregister App resumption data", common.reRegisterApp,
  { 1, checkResumptionData, common.resumptionFullHMILevel, "RESUME_FAILED"})
runner.Step("Check subscription", common.GetInteriorVehicleData, { common.modules[1], false, 1, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)

