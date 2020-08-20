---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0188-get-interior-data-resumption.md
--
-- Description:
-- In case:
-- 1. AddSubMenu related to resumption is sent by App1
-- 2. App1 and App2 are subscribed to the same Interior Vehicle Data (IVD)
-- 3. Unexpected disconnect and reconnect are performed
-- 4. App1 and App2 re-register with actual HashId
-- SDL does:
--  - start resumption process for App1 and App2
--  - send UI.AddSubMenu and RC.GetInteriorVehicleData(subscribe=true) requests related to App1 to HMI
-- 5. HMI responds with <erroneous> resultCode to UI.AddSubMenu and <successful> to
--     RC.GetInteriorVehicleData(subscribe=true) to requests related to App1
-- SDL does:
--  - not send revert RC.GetInteriorVehicleData(subscribe=false) related to App1 request to HMI
--  - not restore subscription to IVD for App1 and responds RAI_Response(success=true,resultCode=RESUME_FAILED) to App1
--  - restore subscription to IVD for App2 and responds RAI_Response(success=true,resultCode=SUCCESS) to App2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("Register app1", common.registerAppWOPTU)
runner.Step("Register app2", common.registerAppWOPTU, { 2 })
runner.Step("Activate app1", common.activateApp)
runner.Step("Activate app2", common.activateApp, { 2 })
runner.Step("Add for app1 getInteriorVehicleData subscription", common.getInteriorVehicleData, { 1, false })
runner.Step("Add for app1 addSubMenu", common.addSubMenu)
runner.Step("Add for app2 getInteriorVehicleData subscription", common.getInteriorVehicleData, { 2, true })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
runner.Step("Reregister Apps resumption", common.reRegisterAppsCustom_AnotherRPC,
  { common.timeToRegApp2.BEFORE_REQUEST, "getInteriorVehicleData" })
runner.Step("Check subscriptions for getInteriorVehicleData", common.isSubscribed, { false, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
