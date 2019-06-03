---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. SubscribeWayPoints and AddSubMenu are added by app1
-- 2. SubscribeWayPoints is added by app2
-- 3. Unexpected disconnect and reconnect are performed
-- 4. App1 and app2 reregister with actual HashId
-- 5. Resumption for App1 and App2 is started:
--    UI.AddSubMenu is sent from SDL to HMI
--    Navigation.SubscribeWayPoints is sent from SDL to HMI
-- 6. HMI responds with success for Navigation.SubscribeWayPoints request
-- 7. SDL restores data for app2 and respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS)to mobile application app2
-- 8. HMI responds with error resultCode for UI.AddSubMenu request with some delay (2s.)
-- 9. SDL respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application app1
-- 10. SDL does not send Navigation.UnsubscribeWayPoints to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Function ]]
local function checkResumptionData()
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
      common.log("UI.AddSubMenu")
      local function sendResponse()
        common.log("GENERIC_ERROR: " .. data.method)
        common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
      end
      RUN_AFTER(sendResponse, 2000)
    end)

  common.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
  :Do(function(_, data)
      common.log(data.method)
      common.log("SUCCESS: " .. data.method)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(2)

  common.getHMIConnection():ExpectRequest("Navigation.UnsubscribeWayPoints")
  :Do(function(_, data) common.log(data.method) end)
  :Times(0)
end

local function onWayPointChange()
  local notificationParams = {
    wayPoints = {
      {
        coordinate = {
          latitudeDegrees = -90,
          longitudeDegrees = -180
        }
      }
    }
  }
  common.getHMIConnection():SendNotification("Navigation.OnWayPointChange", notificationParams)
  common.getMobileSession(1):ExpectNotification("OnWayPointChange")
  :Times(0)
  common.getMobileSession(2):ExpectNotification("OnWayPointChange", notificationParams)
end

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
runner.Step("Reregister Apps resumption", common.reRegisterApps, { checkResumptionData })
runner.Step("Check subscriptions for WayPoints", onWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
