---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0190-resumption-data-error-handling.md
--
-- Requirement summary:TBD
--
-- Description:
-- In case:
-- 1. SubscribeWayPoints is added by app1
-- 2. SubscribeWayPoints is added by app2
-- 3. Unexpected disconnect and reconnect are performed
-- 4. App1 and app2 reregister with actual HashId
-- 5. Resumption for App1 and App2 is started:
--    Navigation.SubscribeWayPoints related to App1 is sent from SDL to HMI
-- 6. HMI responds with error resultCode Navigation.SubscribeWayPoints request with some delay (2s.)
-- 7. SDL doesn't send Navigation.UnsubscribeWayPoints to HMI
-- 8. SDL respond RegisterAppInterfaceResponse(success=true,result_code=RESUME_FAILED) to mobile application app1
-- 9. SDL continue resumption for App2:
--    Navigation.SubscribeWayPoints is sent from SDL to HMI
-- 10. HMI responds with success to Navigation.SubscribeWayPoints request
-- 11. SDL restores data for app2 and respond RegisterAppInterfaceResponse(success=true,result_code=SUCCESS)to mobile application app2
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Resumption/Handling_errors_from_HMI/commonResumptionErrorHandling')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local Function ]]
local function checkResumptionData()
  local isResponseSent = false
  common.getHMIConnection():ExpectRequest("Navigation.SubscribeWayPoints")
  :Do(function(exp, data)
      common.log(data.method)
      if exp.occurences == 1 then
        local function sendResp()
          common.log("GENERIC_ERROR: " .. data.method)
          common.getHMIConnection():SendError(data.id, data.method, "GENERIC_ERROR", "info message")
          isResponseSent = true
        end
        RUN_AFTER(sendResp, 2000)
      else
        common.log("SUCCESS: " .. data.method)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
    end)
   :ValidIf(function(exp)
      if exp.occurences == 2 and isResponseSent == false then
        return false, "VehicleInfo.SubscribeVehicleData request for app2 is received earlier then response for app1 is sent"
      end
      return true
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
runner.Step("Add for app2 subscribeWayPoints", common.subscribeWayPoints, { 2, 0 })
runner.Step("Unexpected disconnect", common.unexpectedDisconnect)
runner.Step("Connect mobile", common.connectMobile)
runner.Step("openRPCserviceForApp1", common.openRPCservice, { 1 })
runner.Step("openRPCserviceForApp2", common.openRPCservice, { 2 })
runner.Step("Reregister Apps resumption", common.reRegisterApps, { checkResumptionData })
runner.Step("Check subscriptions for WayPoints", onWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
