---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
-- Item: Use Case 2: Alternative flow 3
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) Another application requests to sunbscribe on destination and waypoints change notification
--
-- SDL must:
-- 1) SDL subscribes new mobile application internally
-- 2) SDL responds SUCCESS, success:true on subscription request of the second application
-- 3) SDL doesn't transfer new subscription request to HMI
-- 4) SDL transfers stored waypoints change notification to newly subscribed application

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local notification = {
  wayPoints = {
    {
      coordinate = {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      }
    }
  }
}

--[[ Local Functions ]]
local function subscribeWayPointsFirstApp(self)
  local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  self.mobileSession1:ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
  self.mobileSession1:ExpectNotification("OnHashChange")
end

local function subscribeWayPointsSecondApp(self)
  local cid = self.mobileSession2:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints"):Times(0)
  self.mobileSession2:ExpectResponse(cid, { success = true , resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnHashChange")
  commonTestCases:DelayedExp(common.timeout)
end

local function onWayPointChangeToBothApps(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  self.mobileSession1:ExpectNotification("OnWayPointChange", notification)
  self.mobileSession2:ExpectNotification("OnWayPointChange", notification)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

for i = 1, 2 do
  runner.Step("RAI, PTU " .. i, common.registerAppWithPTU, { i })
  runner.Step("Activate App " .. i, common.activateApp, { i })
end

runner.Title("Test")
runner.Step("SubscribeWayPoints 1st app", subscribeWayPointsFirstApp)
runner.Step("SubscribeWayPoints 2nd app", subscribeWayPointsSecondApp)
runner.Step("OnWayPointChange to check apps subscription", onWayPointChangeToBothApps)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
