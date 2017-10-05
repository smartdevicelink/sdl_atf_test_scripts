---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/27
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Unsubscribe_from_Destination_and_Waypoints.md
-- Item: Use Case 1: Alternative flow 1
--
-- Requirement summary:
-- [UnsubscribeWayPoints] As a mobile app I want to be able to unsubscribes from getting notifications
-- about any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sent valid UnsubscribeWayPoints_request to SDL
-- 2) and this request is allowed by Policies
-- 3) and there are other applications still subscribed on waypoints change npotifications
--
-- SDL must:
-- 1) unsubscribe requesting application from waypoints change notifications
-- 2) not send UnsubscribeWayPoints_request to HMI

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function unsubscribeWayPointsSecondApp(self)
  local mobSession = commonNavigation.getMobileSession(2, self)
  local cid = mobSession:SendRPC("UnsubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints"):Times(0)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  mobSession:ExpectNotification("OnHashChange")
  commonTestCases:DelayedExp(commonNavigation.timeout)
end

local function unsubscribeWayPointsFirstApp(self)
  local mobSession = commonNavigation.getMobileSession(1, self)
  local cid = mobSession:SendRPC("UnsubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.UnsubscribeWayPoints")
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  mobSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  mobSession:ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)

for i = 1, 2 do
  runner.Step("RAI, PTU " .. i, commonNavigation.registerAppWithPTU, { i })
  runner.Step("Activate App" .. i, commonNavigation.activateApp, { i })
end

for i = 1, 2 do
  runner.Step("SubscribeWayPoints, App " .. i, commonNavigation.subscribeWayPoints, { i })
  runner.Step("Is Subscribed, App " .. i, commonNavigation.isSubscribed, { i })
end

runner.Title("Test")
runner.Step("UnsubscribeWayPoints App2", unsubscribeWayPointsSecondApp)
runner.Step("Is Unsubscribed App2", commonNavigation.isUnsubscribed, { 2 })
runner.Step("Is still Subscribed App1", commonNavigation.isSubscribed, { 1 })
runner.Step("UnsubscribeWayPoints App1", unsubscribeWayPointsFirstApp)
runner.Step("Is Unsubscribed App1", commonNavigation.isUnsubscribed, { 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
