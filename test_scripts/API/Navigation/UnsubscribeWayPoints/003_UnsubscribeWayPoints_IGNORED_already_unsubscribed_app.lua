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
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function unsubscribeWayPoints(self)
  local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints"):Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "IGNORED" })
  common:DelayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("SubscribeWayPoints", common.subscribeWayPoints)
runner.Step("Is Subscribed", common.isSubscribed)
runner.Step("UnsubscribeWayPoints", common.unsubscribeWayPoints)
runner.Step("Is Unsubscribed", common.isUnsubscribed)

runner.Title("Test")
runner.Step("UnsubscribeWayPoints for the same app IGNORED", unsubscribeWayPoints)
runner.Step("Is still Unsubscribed", common.isUnsubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
