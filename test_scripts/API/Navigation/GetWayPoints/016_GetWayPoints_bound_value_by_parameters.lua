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
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local string65535char = string.rep("a", 65535)
local string500char = string.rep("a", 500)
local string200char = string.rep("a", 200)
local string50char = string.rep("a", 50)
local string16char = string.rep("a", 16)
local minLen = "a"
local wayPointTypeDefault = "ALL"
local imageTypes = { "DYNAMIC", "STATIC" }
local LocationDetailsStringParams = {
  "locationName",
  "locationDescription",
  "phoneNumber"
}
local coordinateParams = {
  latitudeDegrees = { lower = -90, upper = 90 },
  longitudeDegrees = { lower = -180, upper = 180 }
}
local OASISAddressParams = {
  countryName = { lower = minLen, upper = string200char },
  countryCode = { lower = minLen, upper = string50char },
  postalCode = { lower = minLen, upper = string16char },
  administrativeArea = { lower = minLen, upper = string200char },
  subAdministrativeArea = { lower = minLen, upper = string200char },
  locality = { lower = minLen, upper = string200char },
  subLocality = { lower = minLen, upper = string200char },
  thoroughfare = { lower = minLen, upper = string200char },
  subThoroughfare = { lower = minLen, upper = string200char }
}
local addressLinesArraySize = 4
local maxAddressLinesArray = {}
for i=1,addressLinesArraySize do
  maxAddressLinesArray[i] = "string"
end
local maxAddressLinesArrayValue = {}
for i=1,addressLinesArraySize do
  maxAddressLinesArrayValue[i] = string500char
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

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS", wayPoints = lResponse.wayPoints })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Title("Lower bound")
for _, value in pairs(LocationDetailsStringParams) do
  runner.Step("GetWayPoints_wayPoints_lower_bound_" .. value , GetWayPoints, { value, minLen })
end
for k, value in pairs(OASISAddressParams) do
  runner.Step("GetWayPoints_wayPoints_lower_bound_searchAddress_" .. k , GetWayPoints,
    { "searchAddress", { [k] = value.lower }})
end
runner.Step("GetWayPoints_wayPoints_lower_bound_value_array_addressLines" , GetWayPoints,
    { "addressLines", { minLen }})
runner.Step("GetWayPoints_wayPoints_lower_bound_latitudeDegrees" , GetWayPoints,
    { "coordinate", { latitudeDegrees = coordinateParams.latitudeDegrees.lower, longitudeDegrees = 0.1 }})
runner.Step("GetWayPoints_wayPoints_lower_bound_longitudeDegrees" , GetWayPoints,
    { "coordinate", { latitudeDegrees = 0.1, longitudeDegrees = coordinateParams.longitudeDegrees.lower }})
for _, value in pairs(imageTypes) do
  runner.Step("GetWayPoints_wayPoints_lower_bound_locationImage_value_" .. value , GetWayPoints,
    { "locationImage", { value = "a", imageType = value }})
end

runner.Title("Upper bound")
for _, value in pairs(LocationDetailsStringParams) do
  runner.Step("GetWayPoints_wayPoints_upper_bound_" .. value , GetWayPoints, { value, string500char })
end
for k, value in pairs(OASISAddressParams) do
  runner.Step("GetWayPoints_wayPoints_upper_bound_searchAddress_" .. k , GetWayPoints,
    { "searchAddress", { [k] = value.upper }})
end
runner.Step("GetWayPoints_wayPoints_upper_bound_value_addressLines" , GetWayPoints,
    { "addressLines", { string500char }})
runner.Step("GetWayPoints_wayPoints_upper_bound_array_addressLines" , GetWayPoints,
    { "addressLines", maxAddressLinesArray })
runner.Step("GetWayPoints_wayPoints_upper_bound_value_array_addressLines" , GetWayPoints,
    { "addressLines", maxAddressLinesArrayValue })
runner.Step("GetWayPoints_wayPoints_upper_bound_latitudeDegrees" , GetWayPoints,
    { "coordinate", { latitudeDegrees = coordinateParams.latitudeDegrees.upper, longitudeDegrees = 0.1 }})
runner.Step("GetWayPoints_wayPoints_upper_bound_longitudeDegrees" , GetWayPoints,
    { "coordinate", { latitudeDegrees = 0.1, longitudeDegrees = coordinateParams.longitudeDegrees.upper }})
for _, value in pairs(imageTypes) do
  runner.Step("GetWayPoints_wayPoints_upper_bound_locationImage_value_" .. value , GetWayPoints,
    { "locationImage", { value = string65535char, imageType = value }})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
