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
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local resultCodes = {
  success = common.getSuccessResultCodes("GetWayPoints"),
  failure = common.getFailureResultCodes("GetWayPoints"),
  unexpected = common.getUnexpectedResultCodes("GetWayPoints")
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
local function getWayPointsSuccess(pResultCodeMap, self)
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)

  validResponse.appID = common.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :ValidIf(function(_, data)
      return data.params.appID == common.getHMIAppId()
    end)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, pResultCodeMap.hmi, validResponse)
    end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = pResultCodeMap.mobile })
end

local function getWayPointsUnsuccess(pResultCodeMap, isUnsupported, self)
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)

  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :ValidIf(function(_, data)
      return data.params.appID == common.getHMIAppId()
    end)
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, pResultCodeMap.hmi, "Error error")
    end)

  local appSuccess = false
  local appResultCode = pResultCodeMap.mobile
  if isUnsupported then
    appResultCode = "GENERIC_ERROR"
  end
  self.mobileSession1:ExpectResponse(cid, { success = appSuccess, resultCode = appResultCode })
  :ValidIf(function(_,data)
      if not isUnsupported and not data.payload.info then
        return false, "SDL doesn't resend info parameter to mobile App"
      end
      return true
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Result Codes", common.printResultCodes, { resultCodes })

runner.Title("Successful codes")
for _, item in pairs(resultCodes.success) do
  runner.Step("GetWayPoints with " .. item.hmi .. " resultCode", getWayPointsSuccess, { item })
end

runner.Title("Erroneous codes")
for _, item in pairs(resultCodes.failure) do
  runner.Step("GetWayPoints with " .. item.hmi .. " resultCode", getWayPointsUnsuccess, { item, false })
end

runner.Title("Unexpected codes")
for _, item in pairs(resultCodes.unexpected) do
  runner.Step("GetWayPoints with " .. item.hmi .. " resultCode", getWayPointsUnsuccess, { item, true })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
