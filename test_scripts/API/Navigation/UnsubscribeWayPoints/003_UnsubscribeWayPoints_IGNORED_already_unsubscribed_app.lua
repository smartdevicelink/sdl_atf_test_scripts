---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
-- Item: Use Case 2: Main Flow
--
-- Requirement summary:
-- [UnsubscribeWayPoints] As a mobile app I want to be able to unsubscribes from getting notifications
-- about any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application is already unsubscribed from WayPoints-related parameters
-- 2) and the same mobile application sends UnsubscribeWayPoints_request to SDL
--
-- SDL must:
-- 1) respond "IGNORED, success:false" to mobile application
-- 2) keep this application unsubscribed from waypoints change notification

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function unsubscribeWayPoints(self)
  local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints"):Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "IGNORED" })
  commonTestCases:DelayedExp(commonNavigation.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI, PTU", commonNavigation.registerAppWithPTU)
runner.Step("Activate App", commonNavigation.activateApp)
runner.Step("SubscribeWayPoints", commonNavigation.subscribeWayPoints, { 1 })
runner.Step("Is Subscribed", commonNavigation.isSubscribed)
runner.Step("UnsubscribeWayPoints", commonNavigation.unsubscribeWayPoints, { 1 })
runner.Step("Is Unsubscribed", commonNavigation.isUnsubscribed)

runner.Title("Test")
runner.Step("UnsubscribeWayPoints for the same app IGNORED", unsubscribeWayPoints)
runner.Step("Is still Unsubscribed", commonNavigation.isUnsubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
