---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
-- Item: Use Case 1: Exception 1
--
-- Requirement summary:
-- [UnsubscribeWayPoints] As a mobile app I want to be able to unsubscribes from getting notifications
-- about any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) request is invalid
--
-- SDL must:
-- 1) respond INVALID_DATA, success:false to mobile application
-- 2) do not transfer UnsubscribeWayPoints_request to HMI
-- 3) keep this application subscribed to waypoints change notification

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function invalidJson(self)
  local params = { "/   // "}
  local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", params)
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints"):Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
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

runner.Title("Test")
runner.Step("UnsubscribeWayPoints", invalidJson)
runner.Step("Is still Subscribed", common.isSubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
