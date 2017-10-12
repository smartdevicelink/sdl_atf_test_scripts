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
--    with boundary value of parameters.
-- SDL must:
-- 1) Transfer GetWayPoints_request to HMI
-- 2) Respond with <resultCode> received from HMI to mobile application
-- 3) Provide the requested parameters at the same order as received from HMI
--    to mobile application (in case of successfull response)

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local json = require('modules/json')

local response = {
  wayPoints = {
    {
      coordinate =
      {
        latitudeDegrees = 90,
        longitudeDegrees = 180
      },
      locationName = string.rep("a", 500),
      addressLines =
      {
        string.rep("b", 500),
        string.rep("c", 500),
        string.rep("d", 500),
        string.rep("e", 500)
      },
      locationDescription = string.rep("f", 500),
      phoneNumber = string.rep("j", 500),
      locationImage =
      {
        value = string.rep("a", 65531) .. ".png",
        imageType ="DYNAMIC",
      },
      searchAddress =
      {
        countryName = string.rep("a", 200),
        countryCode = string.rep("a", 50),
        postalCode = string.rep("a", 16),
        administrativeArea = string.rep("a", 200),
        subAdministrativeArea = string.rep("a", 200),
        locality = string.rep("a", 200),
        subLocality = string.rep("a", 200),
        thoroughfare = string.rep("a", 200),
        subThoroughfare = string.rep("a", 200)
      }
    },
    {
      coordinate =
      {
        latitudeDegrees = -90,
        longitudeDegrees = -180
      },
      locationName = "a",
      addressLines = json.EMPTY_ARRAY,
      locationDescription = "a",
      phoneNumber = "b",
      locationImage =
      {
        value = "a",
        imageType ="DYNAMIC",
      },
      searchAddress =
      {
        countryName = "",
        countryCode = "",
        postalCode = "",
        administrativeArea = "",
        subAdministrativeArea = "",
        locality = "",
        subLocality = "",
        thoroughfare = "",
        subThoroughfare = ""
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
  :ValidIf(function(_, data)
      return data.params.appID == common.getHMIAppId()
    end)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
    end)

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :ValidIf(function(_, data) -- checking order of wayPoints
      for k in pairs(data.payload.wayPoints) do
        local actualCoordinate = data.payload.wayPoints[k].coordinate
        local expectedCoordinate = response.wayPoints[k].coordinate
        if (actualCoordinate.latitudeDegrees ~= expectedCoordinate.latitudeDegrees) or
          (actualCoordinate.longitudeDegrees ~= expectedCoordinate.longitudeDegrees) then
          return false, "WayPoints order is not as expected"
        end
      end
      return true
    end)
  :ValidIf(function(_, data) -- checking data of wayPoints
      for k in pairs(data.payload.wayPoints) do
        if not commonFunctions:is_table_equal(data.payload.wayPoints[k], response.wayPoints[k]) then
          return false, "Waypoints data is not as expected"
        end
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
for _, wayPointType in pairs({ "ALL", "DESTINATION" }) do
  runner.Step("GetWayPoints wayPointType " .. wayPointType .. " boundary values", GetWayPoints, { wayPointType })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
