---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/GetWayPoints/detailed_docs/TRS/embedded_navi/GetWayPoints_TRS.md
-- Item: Use Case 1: Exception 1: Request is invalid
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) mobile application sends invalid request to SDL
-- SDL must:
-- 1) SDL responds INVALID_DATA, success:false to mobile application and doesn't transfer request to HMI

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local paramsInvalidData = {
  { name = "Invalid Name", value = { wayPoinTType = "ALL" } },
  { name = "Invalid Value", value = { wayPointType = "AALL" } },
  { name = "Invalid Type", value = { wayPointType = 55 } },
  { name = "Whitespaces", value = { wayPointType = "    " } },
  { name = "Invalid json", value = { wayPointType = { "ALL" } } },
  { name = "Missing mandatory parameter", value = { wayPointType = nil } }
}

--[[ Local Functions ]]
local function invalidDataSequence(pParams, self)
  local cid = self.mobileSession1:SendRPC("GetWayPoints", pParams)
  EXPECT_HMICALL("Navigation.GetWayPoints"):Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  commonTestCases:DelayedExp(common.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")

for _, p in pairs(paramsInvalidData) do
  runner.Step("GetWayPoints " .. p.name, invalidDataSequence, { p.value })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
