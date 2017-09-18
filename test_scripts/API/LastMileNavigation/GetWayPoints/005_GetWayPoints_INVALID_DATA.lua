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
local commonLastMileNavigation = require('test_scripts/API/LastMileNavigation/commonLastMileNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')


--[[ Local Functions ]]
local function invalidParamName(self)
  local params = { 
    wayPoinTType = "ALL" -- invalidParamName
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  EXPECT_HMICALL("Navigation.GetWayPoints", params):Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  commonTestCases:DelayedExp(commonLastMileNavigation.timeout)
end

local function invalidParamType(self)
  local params = { 
    wayPointType = "AALL" -- invalidParamType
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  EXPECT_HMICALL("Navigation.GetWayPoints", params):Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  commonTestCases:DelayedExp(commonLastMileNavigation.timeout)
end

local function whitespacesParam(self)
  local params = { 
    wayPointType = "    " -- whitespacesParam
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  EXPECT_HMICALL("Navigation.GetWayPoints", params):Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  commonTestCases:DelayedExp(commonLastMileNavigation.timeout)
end

local function invalidJson(self)
  local params = { 
    wayPointType = { "ALL" } -- invalidJson
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  EXPECT_HMICALL("Navigation.GetWayPoints", params):Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  commonTestCases:DelayedExp(commonLastMileNavigation.timeout)
end

local function missingMandatoryParam(self)
  local params = { 
   -- missingMandatoryParam
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  EXPECT_HMICALL("Navigation.GetWayPoints", params):Times(0)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  commonTestCases:DelayedExp(commonLastMileNavigation.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonLastMileNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonLastMileNavigation.start)
runner.Step("RAI, PTU", commonLastMileNavigation.registerAppWithPTU)
runner.Step("Activate App", commonLastMileNavigation.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints invalid name of parameter", invalidParamName)
runner.Step("GetWayPoints invalid type of parameter", invalidParamType)
runner.Step("GetWayPoints whitespaces", whitespacesParam)
runner.Step("GetWayPoints invalid json", invalidJson)
runner.Step("GetWayPoints missing mandatory parameter", missingMandatoryParam)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonLastMileNavigation.postconditions)
