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
-- 2) GetWayPoints_request is transfered to HMI
-- 3) HMI sends several different responses to request
-- SDL must:
-- 1) Process first received response from HMI and responds with success to mobile app

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

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
local function GetWayPoints(pWayPointType, self)
  local params = {
    wayPointType = pWayPointType
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  response.appID = common.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    self.hmiConnection:SendError(data.id, data.method, "REJECTED", "Error result code")
    self.hmiConnection:SendError(data.id, data.method, "INVALID_DATA", "Error result code")
  end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints_several_responses", GetWayPoints, { "ALL" })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
