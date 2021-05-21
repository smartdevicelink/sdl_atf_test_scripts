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
-- 3) HMI sends response with invalid types of parameters
-- SDL must:
-- 1) validate response and repond to mobile app with INVALID_DATA, success:false
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local intType = 10
local stringType = "string"
local LocationDetailsStringParams = {
  "locationName",
  "locationDescription",
  "phoneNumber"
}
local OASISAddressParams = {
  "countryName",
  "countryCode",
  "postalCode",
  "administrativeArea",
  "subAdministrativeArea",
  "locality",
  "subLocality",
  "thoroughfare",
  "subThoroughfare",
}

--[[ Local Functions ]]
local function GetWayPoints(parameter, value, self)
  local params = {
    wayPointType = "ALL"
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
        return false, "SDL sends wayPoints in error response to mobile application."
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
runner.Step("GetWayPoints_wayPoints_invalid_type_latitudeDegrees" , GetWayPoints,
    { "coordinate", { latitudeDegrees = stringType, longitudeDegrees = 0.1 }})
runner.Step("GetWayPoints_wayPoints_invalid_type_longitudeDegrees" , GetWayPoints,
    { "coordinate", { latitudeDegrees = 0.1, longitudeDegrees = stringType }})
for _, value in pairs(LocationDetailsStringParams) do
  runner.Step("GetWayPoints_wayPoints_invalid_type_" .. value , GetWayPoints, { value, intType })
end
for _, value in pairs(OASISAddressParams) do
  runner.Step("GetWayPoints_wayPoints_invalid_type_searchAddress_" .. value , GetWayPoints,
    { "searchAddress", { [value] = intType }})
end
runner.Step("GetWayPoints_wayPoints_invalid_type_value_addressLines" , GetWayPoints,
    { "addressLines", { intType }})
runner.Step("GetWayPoints_wayPoints_invalid_type_array_addressLines" , GetWayPoints,
    { "addressLines", intType })
runner.Step("GetWayPoints_wayPoints_invalid_type_locationImage_value", GetWayPoints,
    { "locationImage", { value = intType, imageType = "DYNAMIC" }})
runner.Step("GetWayPoints_wayPoints_invalid_type_locationImage_type", GetWayPoints,
    { "locationImage", { value = "image", imageType = intType }})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
