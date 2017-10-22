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
-- 1) mobile application sends valid and allowed by Policies GetWayPoints_request to SDL with fake params
-- SDL must:
-- 1) Transfer GetWayPoints_request to HMI without fake params
-- 2) Respond with <resultCode> received from HMI to mobile application
-- 3) Provide the requested parameters at the same order as received from HMI
--    to mobile application (in case of successfull response) and without fake parameters

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local requestFake = {
  wayPointType = "ALL",
  fakeParameter = 1
}

local requestAnotherReq = {
  wayPointType = "ALL",
  initialText = "initialText"
}

local responseFake = {
  wayPoints = {
    {
      coordinate =
      {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1,
        fakeParameter = "fakeParameter"
      },
      locationName = "Hotel",
      fakeParameter = "fakeParameter",
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
        fakeParameter = "fakeParameter"
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
        subThoroughfare = "subThoroughfare",
        fakeParameter = "fakeParameter"
      }
    }
  }
}

local responseAnotherReq = {
  wayPoints = {
    {
      coordinate =
      {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1,
        initialText = "initialText"
      },
      locationName = "Hotel",
      initialText = "initialText",
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
        initialText = "initialText"
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
        subThoroughfare = "subThoroughfare",
        initialText = "initialText"
      }
    }
  }
}

--[[ Local Functions ]]
local function cloneTableWithOmitting(original)
  local copy = { }
  for k, v in pairs(original) do
    if type(v) == 'table' then
        v = cloneTableWithOmitting(v)
    end
    if
      k ~= "fakeParameter" and
      k ~= "initialText" then
      copy[k] = v
    end
  end
  return copy
end

local function GetWayPointsReqCheck(request, self)
  local cid = self.mobileSession1:SendRPC("GetWayPoints", request)
  local lRequest = cloneTableWithOmitting(request)
  lRequest.appID = common.getHMIAppId()
  local lResponse = { }
  lResponse.wayPoints = {{ locationName = "Hotel" }}
  lResponse.appID = common.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", lRequest)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", lResponse)
  end)
  :ValidIf(function(_,data)
    if data.initialText then
      return false, "SDL resends to HMI fake parameters from mobile request"
    elseif data.fakeParameter then
      return false, "SDL resends to HMI parameters from another API from mobile request"
    else
      return true
    end
  end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", wayPoints = lResponse.wayPoints })
end

local function GetWayPointsResCheck(response, self)
  local requestParams = { wayPointType = "ALL" }
  local cid = self.mobileSession1:SendRPC("GetWayPoints", requestParams)
  requestParams.appID = common.getHMIAppId()
  response.appID = common.getHMIAppId()
  EXPECT_HMICALL("Navigation.GetWayPoints", requestParams)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", response)
  end)
  local lResponse = cloneTableWithOmitting(response)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", wayPoints = lResponse.wayPoints })
  :ValidIf(function(_,data)
    for _, value in pairs(data.payload.wayPoints) do
      if value.fakeParameter or
        value.coordinate.fakeParameter or
        value.locationImage.fakeParameter or
        value.searchAddress.fakeParameter then
        return false, "SDL resends fake parameters in HMI response to mobile app"
      elseif value.initialText or
        value.coordinate.initialText or
        value.locationImage.initialText or
        value.searchAddress.initialText then
        return false, "SDL resends parameters from another API in HMI response to mobile app"
      else
        return true
      end
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
runner.Step("GetWayPoints_fake_params_in_request", GetWayPointsReqCheck, { requestFake })
runner.Step("GetWayPoints_params_from_another_API_in_request", GetWayPointsReqCheck, { requestAnotherReq })
runner.Step("GetWayPoints_fake_params_in_response", GetWayPointsResCheck, { responseFake })
runner.Step("GetWayPoints_params_from_another_API_in_response", GetWayPointsResCheck, { responseAnotherReq })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
