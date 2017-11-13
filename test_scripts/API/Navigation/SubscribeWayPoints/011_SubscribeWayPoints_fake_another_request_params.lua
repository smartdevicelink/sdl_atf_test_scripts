---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sent valid and allowed by Policies SubscribeWayPoints_request with fake, from another request parameters to SDL
--
-- SDL must:
-- 1) transfer SubscribeWayPoints_request to HMI without fake, from another request parameters
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
local function subscribeWayPoints(params, self)
  local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", params)
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
  end)
  :ValidIf(function(_,data)
    if data.params then
      return false, "SDL sends SubscribeWayPoints request to HMI with fake parameters"
    else
      return true
    end
  end)
  self.mobileSession1:ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
end

local function onWayPointChange(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  self.mobileSession1:ExpectNotification("OnWayPointChange", notification)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("SubscribeWayPoints_with_fake_parameters", subscribeWayPoints, {{ fake = "string_name" }})
runner.Step("OnWayPointChange to check apps subscription_1", onWayPointChange)
runner.Step("Postcond_UnsubscribeWayPoints", common.unsubscribeWayPoints)
runner.Step("SubscribeWayPoints_with_parameters_from_another_request", subscribeWayPoints, {{ gps = true }})
runner.Step("OnWayPointChange to check apps subscription_2", onWayPointChange)

runner.Title("Postconditions")
runner.Step("UnsubscribeWayPoints", common.unsubscribeWayPoints)
runner.Step("Stop SDL", common.postconditions)
