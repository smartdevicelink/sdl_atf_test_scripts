---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Item: Use Case 1: Exception 2: request is NOT allowed by Policies
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) mobile application sends valid GetWayPoints_request to SDL and this request is NOT allowed by Policies
-- SDL must:
-- 1) SDL responds DISALLOWED, success:false to mobile application and doesn't transfer this request to HMI

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function getWayPoints(self)
  local params = {
    wayPointType = "ALL"
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  EXPECT_HMICALL("Navigation.GetWayPoints", params):Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED" })
  commonTestCases:DelayedExp(commonNavigation.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI", commonNavigation.raiN)
runner.Step("Activate App", commonNavigation.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints, DISALLOWED by policy", getWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
