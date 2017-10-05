---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
-- Item: Use Case 2: Alternative flow 2
--
-- Requirement summary:
-- [UnsubscribeWayPoints] As a mobile app I want to be able to unsubscribes from getting notifications
-- about any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) Ignition OFF (ignition cycle is over)
-- 2) New ignitions cycle, mobile application registers with the same hashID as in previous ignition cycle
--
-- SDL must:
-- 1) restore the subscription status of mobile application (unsubscribed)

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

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
runner.Step("IGNITION_OFF", common.IGNITION_OFF)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerAppWithTheSameHashId)
runner.Step("Activate App", common.activateApp)
runner.Step("Is still Unsubscribed", common.isUnsubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
