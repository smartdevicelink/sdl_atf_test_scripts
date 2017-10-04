---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
-- Item: Use Case 2: Alternative flow 1
--
-- Requirement summary:
-- [UnsubscribeWayPoints] As a mobile app I want to be able to unsubscribes from getting notifications
-- about any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application unexpectedly disconnects
--
-- SDL must:
-- 1) store the subscription status internally (application remains unsubscribed)
-- 2) restore the subscription status right after application reconnects with the same hashID that was before disconnect

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function closeSession(self)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = true, appID = commonNavigation.getHMIAppId() })
  self.mobileSession1:Stop()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI, PTU", commonNavigation.registerAppWithPTU)
runner.Step("Activate App", commonNavigation.activateApp)
runner.Step("SubscribeWayPoints", commonNavigation.subscribeOnWayPointChange, { 1 })
runner.Step("Is Subscribed", commonNavigation.isSubscribed)
runner.Step("UnsubscribeWayPoints", commonNavigation.unsubscribeOnWayPointChange, { 1 })
runner.Step("Is Unsubscribed", commonNavigation.isUnsubscribed)

runner.Title("Test")
runner.Step("Unexpected disconnect", closeSession)
runner.Step("RAI", commonNavigation.registerAppWithTheSameHashId)
runner.Step("Activate App", commonNavigation.activateApp)
runner.Step("Is still Unsubscribed", commonNavigation.isUnsubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
