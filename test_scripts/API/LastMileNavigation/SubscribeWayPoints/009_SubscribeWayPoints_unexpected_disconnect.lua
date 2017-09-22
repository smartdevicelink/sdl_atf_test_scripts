---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
-- Item: Use Case 2: Mobile application is already subscribed to Destination & Waypoints: Alternative flow 1: Mobile application unexpectedly disconnects
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) Mobile application unexpectedly disconnects
-- SDL must:
-- 1) SDL stores the subscription status internally
-- 2) SDL sends request to unsubscribe mobile application to HMI
-- 3) SDL restores the subscription status right after application reconnects with the same hashID that was before disconnect
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonLastMileNavigation = require('test_scripts/API/LastMileNavigation/commonLastMileNavigation')

local notification = {}
notification.wayPoints = {{
  coordinate = {
    latitudeDegrees = 1.1,
    longitudeDegrees = 1.1
  }
}}

--[[ Local Functions ]]
local function OnWayPointChange(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)       
  self.mobileSession1:ExpectNotification("OnWayPointChange", notification)  
end

local function closeSession(self)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true,
    appID = commonLastMileNavigation.getHMIAppId()})
  self.mobileSession1:Stop()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonLastMileNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonLastMileNavigation.start)
runner.Step("RAI, PTU", commonLastMileNavigation.registerAppWithPTU)
runner.Step("Activate App", commonLastMileNavigation.activateApp)
runner.Step("SubscribeWayPoints", commonLastMileNavigation.subscribeOnWayPointChange, { 1 })

runner.Title("Test")
runner.Step("Unexpected disconnect", closeSession)
runner.Step("RAI", commonLastMileNavigation.registerAppWithTheSameHashId)
runner.Step("OnWayPointChange to check app subscription", OnWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonLastMileNavigation.postconditions)
