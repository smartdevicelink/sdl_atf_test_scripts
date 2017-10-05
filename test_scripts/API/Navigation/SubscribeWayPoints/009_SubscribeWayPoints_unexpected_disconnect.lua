---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
-- Item: Use Case 2: Mobile application is already subscribed to Destination & Waypoints: Alternative flow 1: Mobile application unexpectedly disconnects
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) Mobile application unexpectedly disconnects
-- SDL must:
-- 1) SDL stores the subscription status internally
-- 2) SDL sends request to unsubscribe mobile application to HMI
-- 3) SDL restores the subscription status right after application reconnects with the same hashID
--    that was before disconnect

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')

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
local function onWayPointChange(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  self.mobileSession1:ExpectNotification("OnWayPointChange", notification)
end

local function closeSession(self)
  self.mobileSession1:Stop()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = true, appID = commonNavigation.getHMIAppId() })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI, PTU", commonNavigation.registerAppWithPTU)
runner.Step("Activate App", commonNavigation.activateApp)
runner.Step("SubscribeWayPoints", commonNavigation.subscribeWayPoints)

runner.Title("Test")
runner.Step("Unexpected disconnect", closeSession)
runner.Step("RAI", commonNavigation.registerAppWithTheSameHashId)
runner.Step("OnWayPointChange to check app subscription", onWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
