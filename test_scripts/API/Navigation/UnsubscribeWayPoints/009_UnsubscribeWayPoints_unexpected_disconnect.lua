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
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Functions ]]
local function closeSession(self)
  self.mobileSession1:Stop()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = true, appID = common.getHMIAppId() })
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
runner.Step("Unexpected disconnect", closeSession)
runner.Step("RAI", common.registerAppWithTheSameHashId)
runner.Step("Activate App", common.activateApp)
runner.Step("Is still Unsubscribed", common.isUnsubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
