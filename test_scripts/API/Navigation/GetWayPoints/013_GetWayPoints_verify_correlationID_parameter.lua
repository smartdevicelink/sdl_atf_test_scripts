---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) mobile application sends valid and allowed by Policies GetWayPoints_request to SDL
--    Response from HMI contains wrong correlation id
-- SDL must:
-- 1) Respond with success = false, resultCode = "GENERIC_ERROR"
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Local Variables ]]
local response = {
  wayPoints = {
    {
      coordinate =
      {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      }
    }
  }
}

--[[ Local Functions ]]
local function CorrelationIDMissing(pWayPointType, self)
  local params = {
    wayPointType = pWayPointType
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :ValidIf(function(_, data)
    if data.params.appID == common.getHMIAppId() then
        return true
      else
        return false, "Wrong value of appID in HMI request"
      end
  end)
  :Do(function()
    self.hmiConnection:Send('{"jsonrpc":"2.0","result":{"method":"Navigation.GetWayPoints", "code":0}}')
  end)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(11000)
  :ValidIf(function(_,data)
    if data.payload.wayPoints then
      return false, "SDL sends wayPoints in error response"
    else
      return true
    end
  end)
end

local function CorrelationIDWrongType(pWayPointType, self)
  local params = {
    wayPointType = pWayPointType
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  local lResponse = commonFunctions:cloneTable(response)
  lResponse.appID = common.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :ValidIf(function(_, data)
    if data.params.appID == common.getHMIAppId() then
      return true
    else
      return false, "Wrong value of appID in HMI request"
    end
  end)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(tostring(data.id), data.method, "SUCCESS", lResponse)
  end)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(11000)
  :ValidIf(function(_,data)
    if data.payload.wayPoints then
      return false, "SDL sends wayPoints in error response"
    else
      return true
    end
  end)
end

local function CorrelationIDNotExisted(pWayPointType, self)
  local params = {
    wayPointType = pWayPointType
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  local lResponse = commonFunctions:cloneTable(response)
  lResponse.appID = common.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :ValidIf(function(_, data)
    if data.params.appID == common.getHMIAppId() then
      return true
    else
      return false, "Wrong value of appID in HMI request"
    end
  end)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(999, data.method, "SUCCESS", lResponse)
  end)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
  :Timeout(11000)
  :ValidIf(function(_,data)
    if data.payload.wayPoints then
      return false, "SDL sends wayPoints in error response"
    else
      return true
    end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
for _, wayPointType in pairs({ "ALL", "DESTINATION" }) do
  runner.Step("GetWayPoints CorrelationIDMissing wayPointType " .. wayPointType, CorrelationIDMissing,
    { wayPointType })
  runner.Step("GetWayPoints CorrelationIDWrongType wayPointType " .. wayPointType, CorrelationIDWrongType,
    { wayPointType })
  runner.Step("GetWayPoints CorrelationIDNotExisted wayPointType " .. wayPointType, CorrelationIDNotExisted,
    { wayPointType })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
