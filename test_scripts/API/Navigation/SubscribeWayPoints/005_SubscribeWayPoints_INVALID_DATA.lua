---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/26
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Subscribe_to_Destination_and_Waypoints.md
-- Item: Use Case 1: Subscribe to Destination & Waypoints: Alternative flow 1: Request is invalid
--
-- Requirement summary:
-- [SubscribeWayPoints] As a mobile app I want to be able to subscribe on notifications about
-- any changes to the destination or waypoints.
--
-- Description:
-- In case:
-- 1) Request is invalid
--
-- SDL must:
-- 1) SDL responds INVALID_DATA, success:false to mobile application and doesn't subscribe on destination and waypoints change notifications

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Functions ]]
local function invalidJson(self)
  local params = { "/   // "}
  local cid = self.mobileSession1:SendRPC("SubscribeWayPoints", params)
  EXPECT_HMICALL("Navigation.SubscribeWayPoints"):Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  commonTestCases:DelayedExp(commonNavigation.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI, PTU", commonNavigation.registerAppWithPTU)
runner.Step("Activate App", commonNavigation.activateApp)

runner.Title("Test")
runner.Step("SubscribeWayPoints invalid json", invalidJson)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
