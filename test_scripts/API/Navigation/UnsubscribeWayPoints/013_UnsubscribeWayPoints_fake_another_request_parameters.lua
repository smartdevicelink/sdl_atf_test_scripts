---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
--
-- Requirement summary:
-- [UnsubscribeWayPoints] As a mobile app I want to be able to unsubscribes from getting notifications
-- about any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sent valid and allowed by Policies UnsubscribeWayPoints_request with fake,
-- from another request parameters to SDL
--
-- SDL must:
-- 1) transfer UnsubscribeWayPoints_request to HMI without fake, from another request parameters
-- 2) respond with <resultCode> received from HMI to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local notification = {
  wayPoints = {
    {
      coordinate = {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      }
    }
  }
}

--[[ Local Functions ]]
local function UnsubscribeWayPoints(params, self)
  local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", params)
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
  end)
  :ValidIf(function(_,data)
    if data.params then
      return false, "SDL sends UnsubscribeWayPoints request to HMI with fake parameters"
    else
      return true
    end
  end)
  self.mobileSession1:ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
end

local function onWayPointChange(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  self.mobileSession1:ExpectNotification("OnWayPointChange", notification)
  :Times(0)
  common:DelayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("SubscribeWayPoints", common.subscribeWayPoints)

runner.Title("Test")
runner.Step("UnsubscribeWayPoints_with_fake_parameters", UnsubscribeWayPoints, {{ fake = "string_name" }})
runner.Step("OnWayPointChange to check app is not subscribed", onWayPointChange)
runner.Step("Precond_SubscribeWayPoints", common.subscribeWayPoints)
runner.Step("UnsubscribeWayPoints_with_parameters_from_another_request", UnsubscribeWayPoints, {{ gps = true }})
runner.Step("OnWayPointChange to check app is not subscribed", onWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
