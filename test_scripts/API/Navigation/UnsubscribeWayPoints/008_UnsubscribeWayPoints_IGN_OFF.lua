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
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')

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
runner.Step("IGNITION_OFF", commonNavigation.IGNITION_OFF)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI", commonNavigation.registerAppWithTheSameHashId)
runner.Step("Activate App", commonNavigation.activateApp)
runner.Step("Is still Unsubscribed", commonNavigation.isUnsubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
