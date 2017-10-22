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
-- 2) HMI responds with out of bound values to SDL
-- SDL must:
-- 1) respond to mobile INVALID_DATA, success:false

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local string65536char = string.rep("a", 65536)
local string501char = string.rep("a", 501)
local string201char = string.rep("a", 201)
local string51char = string.rep("a", 51)
local string17char = string.rep("a", 17)
local wayPointTypeDefault = "ALL"
local imageTypes = { "DYNAMIC", "STATIC" }
local LocationDetailsStringParams = {
  "locationName",
  "locationDescription",
  "phoneNumber"
}
local coordinateParams = {
  latitudeDegrees = { lower = -90.1, upper = 90.1 },
  longitudeDegrees = { lower = -180.1, upper = 180.1 }
}
local OASISAddressParams = {
  countryName = { upper = string201char },
  countryCode = { upper = string51char },
  postalCode = { upper = string17char },
  administrativeArea = { upper = string201char },
  subAdministrativeArea = { upper = string201char },
  locality = { upper = string201char },
  subLocality = { upper = string201char },
  thoroughfare = { upper = string201char },
  subThoroughfare = { upper = string201char }
}
local addressLinesArraySize = 5
local maxAddressLinesArray = {}
for i=1,addressLinesArraySize do
  maxAddressLinesArray[i] = "string"
end

--[[ Local Functions ]]
local function GetWayPoints(parameter, value, self)
  local params = {
    wayPointType = wayPointTypeDefault
  }

  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  params.appID = common.getHMIAppId()
  local lResponse = { }
  lResponse.wayPoints = {{ [parameter] = value }}
  lResponse.appID = common.getHMIAppId()

  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", lResponse)
  end)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
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
runner.Title("Out lower bound")
runner.Step("GetWayPoints_wayPoints_lower_bound_latitudeDegrees" , GetWayPoints,
    { "coordinate", { latitudeDegrees = coordinateParams.latitudeDegrees.lower, longitudeDegrees = 0.1 }})
runner.Step("GetWayPoints_wayPoints_lower_bound_longitudeDegrees" , GetWayPoints,
    { "coordinate", { latitudeDegrees = 0.1, longitudeDegrees = coordinateParams.longitudeDegrees.lower }})

runner.Title("Out upper bound")
for _, value in pairs(LocationDetailsStringParams) do
  runner.Step("GetWayPoints_wayPoints_upper_bound_" .. value , GetWayPoints, { value, string501char })
end
for k, value in pairs(OASISAddressParams) do
  runner.Step("GetWayPoints_wayPoints_upper_bound_searchAddress_" .. k , GetWayPoints,
    { "searchAddress", { [k] = value.upper }})
end
runner.Step("GetWayPoints_wayPoints_upper_bound_value_addressLines" , GetWayPoints,
    { "addressLines", { string501char }})
runner.Step("GetWayPoints_wayPoints_upper_bound_array_addressLines" , GetWayPoints,
    { "addressLines", maxAddressLinesArray })
runner.Step("GetWayPoints_wayPoints_upper_bound_latitudeDegrees" , GetWayPoints,
    { "coordinate", { latitudeDegrees = coordinateParams.latitudeDegrees.upper, longitudeDegrees = 0.1 }})
runner.Step("GetWayPoints_wayPoints_upper_bound_longitudeDegrees" , GetWayPoints,
    { "coordinate", { latitudeDegrees = 0.1, longitudeDegrees = coordinateParams.longitudeDegrees.upper }})
for _, value in pairs(imageTypes) do
  runner.Step("GetWayPoints_wayPoints_upper_bound_locationImage_value_" .. value , GetWayPoints,
    { "locationImage", { value = string65536char, imageType = value }})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
