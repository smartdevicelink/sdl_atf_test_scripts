---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [UnsubscribeWayPoints] As a mobile app I want to be able to unsubscribe from getting notifications
-- about any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sent valid UnsubscribeWayPoints_request to SDL
-- 2) and this request is allowed by Policies
-- 3) and there are no other applications subscribed on waypoints change notifications
--
-- SDL must:
-- 1) transfer UnsubscribeWayPoints_request to HMI
-- 2) respond with <"resultCode"> received from HMI to mobile application

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

runner.Title("Test")
runner.Step("UnsubscribeWayPoints", commonNavigation.unsubscribeOnWayPointChange, { 1 })
runner.Step("Is Unsubscribed", commonNavigation.isUnsubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
