---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
-- Item: Use Case 1: Subscribe to Destination & Waypoints: Alternative flow 3: Navigation interface is not available on HMI
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) Navigation interface is not available on HMI
--
-- SDL must:
-- 1) SDL responds UNSUPPORTED_RESOURCE, success:false to mobile app and doesn't subscribe on destination
--    and waypoints change notifications
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')
local hmi_values = require('user_modules/hmi_values')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

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
local function disableNavigationInterface()
  local params = hmi_values.getDefaultHMITable()
  params.Navigation.IsReady.params.available = false
  return params
end

local function subscribeWayPoints(self)
  local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints"):Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "UNSUPPORTED_RESOURCE" })
  commonTestCases:DelayedExp(commonNavigation.timeout)
end

local function onWayPointChange(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  self.mobileSession1:ExpectNotification("OnWayPointChange"):Times(0)
  commonTestCases:DelayedExp(commonNavigation.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start, { disableNavigationInterface() })
runner.Step("RAI", commonNavigation.registerAppWithPTU)
runner.Step("Activate App", commonNavigation.activateApp)

runner.Title("Test")
runner.Step("SubscribeWayPoints, navigation interface is not available on HMI", subscribeWayPoints)
runner.Step("OnWayPointChange to check that app is not subscribed", onWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
