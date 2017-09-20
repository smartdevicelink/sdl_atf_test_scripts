---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Item: Use Case 1: Main flow
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination 
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) Mobile application requests to get details of the destination and waypoints set on the system
--    so that it can provide last mile connectivity.
-- SDL must:
-- 1) SDL transfers the request with valid and allowed parameters to HMI
-- 2) SDL receives response from HMI
-- 3) SDL transfers response to mobile application

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonLastMileNavigation = require('test_scripts/API/LastMileNavigation/commonLastMileNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

local error_codes = { "GENERIC_ERROR", "INVALID_DATA", "OUT_OF_MEMORY", "REJECTED" }

local validResponse = {}
validResponse.wayPoints = {
  { 
    coordinate =
    {
      latitudeDegrees =  0,
      longitudeDegrees =  0 
    },
    locationName = "Home",
    addressLines = { "Odessa", "Street" }
  } 
}

--[[ Local Functions ]]
local function GetWayPointsSuccess(self)
  local params = { 
    wayPointType = "ALL"
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)

  validResponse.appID = commonLastMileNavigation.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", params):ValidIf(function(_, data)
    return data.params.appID == commonLastMileNavigation.getHMIAppId()
  end):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", validResponse)
    end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

local function GetWayPointsUnsuccess(pResultCode, self)
  local params = { 
    wayPointType = "ALL"
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)

  EXPECT_HMICALL("Navigation.GetWayPoints", params):ValidIf(function(_, data)
    return data.params.appID == commonLastMileNavigation.getHMIAppId()
  end):Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, pResultCode, "Error error")
    end)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = pResultCode})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonLastMileNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonLastMileNavigation.start)
runner.Step("RAI, PTU", commonLastMileNavigation.registerAppWithPTU)
runner.Step("Activate App", commonLastMileNavigation.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints succes result", GetWayPointsSuccess)
for _, code in pairs(error_codes) do
    runner.Step("GetWayPoints with " .. code .. " resultCode", GetWayPointsUnsuccess, { code })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonLastMileNavigation.postconditions)
