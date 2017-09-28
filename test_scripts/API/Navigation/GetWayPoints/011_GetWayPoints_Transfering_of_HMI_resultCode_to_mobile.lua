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
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local successResultCodes = {
  "SUCCESS",
}

local failureResultCodes = {
  "INVALID_DATA",
  "TIMED_OUT",
  "GENERIC_ERROR",
  "REJECTED",
  "UNSUPPORTED_RESOURCE",
  "IGNORED",
  "IN_USE",
  "DISALLOWED"
}

local unexpectedResultCodes = {
  "UNSUPPORTED_REQUEST",
  "ABORTED",
  "RETRY",
  "VEHICLE_DATA_NOT_AVAILABLE",
  "CHAR_LIMIT_EXCEEDED",
  "INVALID_ID",
  "DUPLICATE_NAME",
  "APPLICATION_NOT_REGISTERED",
  "WRONG_LANGUAGE",
  "OUT_OF_MEMORY",
  "TOO_MANY_PENDING_REQUESTS",
  "TOO_MANY_APPLICATIONS",
  "APPLICATION_REGISTERED_ALREADY",
  "WARNINGS",
  "USER_DISALLOWED",
  "TRUNCATED_DATA",
  "UNSUPPORTED_VERSION",
  "VEHICLE_DATA_NOT_ALLOWED",
  "FILE_NOT_FOUND",
  "CANCEL_ROUTE",
  "SAVED",
  "INVALID_CERT",
  "EXPIRED_CERT",
  "RESUME_FAILED",
  "DATA_NOT_AVAILABLE",
  "READ_ONLY"
}

local params = {
  wayPointType = "ALL"
}

local validResponse = {
  wayPoints = {
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
}

--[[ Local Functions ]]
local function getWayPointsSuccess(pResultCode, self)
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)

  validResponse.appID = commonNavigation.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :ValidIf(function(_, data)
      return data.params.appID == commonNavigation.getHMIAppId()
    end)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, pResultCode, validResponse)
    end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = pResultCode })
end

local function getWayPointsUnsuccess(pResultCode, isUnsupported, self)
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)

  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :ValidIf(function(_, data)
      return data.params.appID == commonNavigation.getHMIAppId()
    end)
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, pResultCode, "Error error")
    end)

  local appSuccess = false
  local appResultCode = pResultCode
  if isUnsupported then
    appResultCode = "GENERIC_ERROR"
  end
  self.mobileSession1:ExpectResponse(cid, { success = appSuccess, resultCode = appResultCode })
  :ValidIf(function(_,data)
      if not data.payload.info then
        return false, "SDL doesn't resend info parameter to mobile App"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)
runner.Step("RAI, PTU", commonNavigation.registerAppWithPTU)
runner.Step("Activate App", commonNavigation.activateApp)

runner.Title("Test")

runner.Title("Successful codes")
for _, code in pairs(successResultCodes) do
  runner.Step("GetWayPoints with " .. code .. " resultCode", getWayPointsSuccess, { code })
end

runner.Title("Erroneous codes")
for _, code in pairs(failureResultCodes) do
  runner.Step("GetWayPoints with " .. code .. " resultCode", getWayPointsUnsuccess, { code, false })
end

runner.Title("Unexpected codes")
for _, code in pairs(unexpectedResultCodes) do
  runner.Step("GetWayPoints with " .. code .. " resultCode", getWayPointsUnsuccess, { code, true })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
