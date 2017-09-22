---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
-- Item: Use Case 1: Subscribe to Destination & Waypoints
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) mobile application sends valid and allowed by Policies SubscribeWayPoints to SDL
--    and HMI respond with invalid data
-- SDL must:
-- 1) SDL responds GENERIC_ERROR, success:false to mobile application

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonLastMileNavigation = require('test_scripts/API/LastMileNavigation/commonLastMileNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function SubscribeWayPoints(self)
  local response = { "/   // "}
  local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", {})
  EXPECT_HMICALL("Navigation.SubscribeWayPoints"):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    end)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonLastMileNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonLastMileNavigation.start)
runner.Step("RAI, PTU", commonLastMileNavigation.registerAppWithPTU)
runner.Step("Activate App", commonLastMileNavigation.activateApp)

runner.Title("Test")
runner.Step("SubscribeWayPoints, HMI respond with invalid data", SubscribeWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonLastMileNavigation.postconditions)
