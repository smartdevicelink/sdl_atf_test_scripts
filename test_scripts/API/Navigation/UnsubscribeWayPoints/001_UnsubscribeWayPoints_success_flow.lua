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
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("SubscribeWayPoints", common.subscribeWayPoints)
runner.Step("Is Subscribed", common.isSubscribed)

runner.Title("Test")
runner.Step("UnsubscribeWayPoints", common.unsubscribeWayPoints)
runner.Step("Is Unsubscribed", common.isUnsubscribed)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
