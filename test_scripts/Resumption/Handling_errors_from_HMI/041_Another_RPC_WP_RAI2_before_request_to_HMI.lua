---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Description:
-- In case:
-- 1. App1 is subscribed to <RPC1> and <RPC2>, App2 is subscribed to <RPC2>
-- 2. Unexpected disconnect and reconnect are performed
-- 3. App1 and App2 re-register with actual HashId
-- 4. SDL starts resumption for App1 and App2:
--    <RPC1> and <RPC2> requests related to App1 are sent from SDL to HMI
-- 5. HMI responds with error resultCode to <RPC1> and success to <RPC2>
-- 6. SDL doesn't send revert <RPC2> request to HMI
-- 7. SDL doesn't restore subscription to <RPC2> for App1 and responds RAI_Response(success=true,resultCode=RESUME_FAILED)
-- 8. SDL restores subscription to <RPC2> for App2 and responds RAI_Response(success=true,resultCode=SUCCESS) to App2
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
runner.Step("Add for app1 subscribeWayPoints", common.subscribeWayPoints)
runner.Step("Add for app1 addSubMenu", common.addSubMenu)
runner.Step("Add for app2 subscribeWayPoints", common.subscribeWayPoints, { 2, 0 })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
runner.Step("Reregister Apps resumption", common.reRegisterAppsCustom_AnotherRPC,
  { common.timeToRegApp2.BEFORE_REQUEST, "subscribeWayPoints" })
runner.Step("Check subscriptions for WayPoints", common.sendOnWayPointChange, { false, true })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
