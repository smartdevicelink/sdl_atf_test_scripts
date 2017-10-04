---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
-- Item: Use Case 1: Exception 5
--
-- Requirement summary:
-- [UnsubscribeWayPoints] As a mobile app I want to be able to unsubscribes from getting notifications
-- about any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sent valid UnsubscribeWayPoints_request to SDL
-- 2) and HMI responds with UNSUPPORTED_RESOURCE
--
-- SDL must:
-- 1) transfer UNSUPPORTED_RESOURCE, success:false to mobile application and does not unsubscribe from destination
-- and waypoints change notifications

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function unsubscribeWayPoints(self)
  local cid = self.mobileSession1:SendRPC("UnsubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Do(function(_, data)
      self.hmiConnection:SendError(data.id, data.method, "UNSUPPORTED_RESOURCE", "Error")
    end)
  self.mobileSession1:ExpectResponse(cid,
    { success = false , resultCode = "UNSUPPORTED_RESOURCE", info = "Error" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI, PTU", commonNavigation.registerAppWithPTU)
runner.Step("Activate App", commonNavigation.activateApp)
runner.Step("SubscribeWayPoints", commonNavigation.subscribeOnWayPointChange, { 1 })
runner.Step("Is Subscribed", commonNavigation.isSubscribed)

runner.Title("Test")
runner.Step("UnsubscribeWayPoints", unsubscribeWayPoints)
runner.Step("Is still Subscribed", commonNavigation.isSubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
