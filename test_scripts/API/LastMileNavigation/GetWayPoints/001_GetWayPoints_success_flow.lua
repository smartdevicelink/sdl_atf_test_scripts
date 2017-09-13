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
-- SDL must:
-- 1) Transfer GetWayPoints_request to HMI
-- 2) Respond with <resultCode> received from HMI to mobile application
-- 3) Provide the requested parameters at the same order as received from HMI 
--    to mobile application (in case of successfull response)

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonLastMileNavigation = require('test_scripts/API/LastMileNavigation/commonLastMileNavigation')

local response = {}
response.wayPoints = {
  { 
    coordinate =
    {
      latitudeDegrees = 1.1,
      longitudeDegrees = 1.1
    },
    locationName = "Hotel",
    addressLines =
    {
      "Hotel Bora",
      "Hotel 5 stars"
    },
    locationDescription = "VIP Hotel",
    phoneNumber = "Phone39300434",
    locationImage =
    {
      value ="icon.png",
      imageType ="DYNAMIC",
    },
    searchAddress =
    {
      countryName = "countryName",
      countryCode = "countryCode",
      postalCode = "postalCode",
      administrativeArea = "administrativeArea",
      subAdministrativeArea = "subAdministrativeArea",
      locality = "locality",
      subLocality = "subLocality",
      thoroughfare = "thoroughfare",
      subThoroughfare = "subThoroughfare"
    }
  },
  {
    coordinate =
    {
      latitudeDegrees = 88,
      longitudeDegrees = 176
    },
    locationName = "Home",
    addressLines =
    {
      "Street, 36"
    },
    locationDescription = "Home",
    phoneNumber = "46788974",
    locationImage =
    {
      value ="icon.png",
      imageType ="DYNAMIC",
    },
    searchAddress =
    {
      countryName = "countryname",
      countryCode = "countrycode",
      postalCode = "postalcode",
      administrativeArea = "administrativearea",
      subAdministrativeArea = "subAdministrativearea",
      locality = "locality",
      subLocality = "sublocality",
      thoroughfare = "thoroughfare",
      subThoroughfare = "subthoroughfare"
    }
} }


--[[ Local Functions ]]
local function GetWayPoints(self)
  local params = { 
    wayPointType = "ALL"
  }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)

  response.appID = commonLastMileNavigation.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", params):ValidIf(function(_, data)
    return data.params.appID == commonLastMileNavigation.getHMIAppId()
  end)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
  end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" }):ValidIf(function (_, data)
    for k, v in pairs(data.payload.wayPoints) do  -- checking the order of the wayPoints
      return ((data.payload.wayPoints[k].coordinate.latitudeDegrees == response.wayPoints[k].coordinate.latitudeDegrees) and 
        (data.payload.wayPoints[k].coordinate.longitudeDegrees == response.wayPoints[k].coordinate.longitudeDegrees))
    end
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonLastMileNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonLastMileNavigation.start)
runner.Step("RAI, PTU", commonLastMileNavigation.registerAppWithPTU)
runner.Step("Activate App", commonLastMileNavigation.activateApp)

runner.Title("Test")
runner.Step("GetWayPoints, wayPointType\"ALL\"", GetWayPoints)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonLastMileNavigation.postconditions)
