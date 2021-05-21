---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/25
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Get%20Destination_and_Waypoints.md
--
-- Requirement summary:
-- [GetWayPoints] As a mobile app I want to send a request to get the details of the destination
-- and waypoints set on the system so that I can get last mile connectivity.
--
-- Description:
-- In case:
-- 1) mobile application sends valid and allowed by Policies GetWayPoints_request to SDL
-- 2) HMI responds with invalid characters \n,\t, " " values to SDL
-- SDL must:
-- 1) respond to mobile INVALID_DATA, success:false

---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local stringNewLine = "str\ning"
local stringTab = "str\ting"
local stringOnlyWhiteSpace = " "
local wayPointTypeDefault = "ALL"
local imageTypes = { "DYNAMIC", "STATIC" }
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
  "subThoroughfare"
}

--[[ Local Functions ]]
local function GetWayPoints(parameter, value, self)
  local params = {
    wayPointType = wayPointTypeDefault
  }

  local cid = self.mobileSession1:SendRPC("GetWayPoints", params)
  params.appID = common.getHMIAppId()
  local lResponse = {}
  lResponse.wayPoints = {{
    coordinate = {
      latitudeDegrees = 45.5,
      longitudeDegrees = 45.5
    }
  }}
  lResponse.wayPoints = {{ [parameter] = value }}
  lResponse.appID = common.getHMIAppId()

  EXPECT_HMICALL("Navigation.GetWayPoints", params)
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", lResponse)
  end)

  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
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
for _, value in pairs(LocationDetailsStringParams) do
  runner.Step("GetWayPoints_wayPoints_newLine_" .. value , GetWayPoints, { value, stringNewLine })
  runner.Step("GetWayPoints_wayPoints_tab_" .. value , GetWayPoints, { value, stringTab })
  runner.Step("GetWayPoints_wayPoints_whitespace_" .. value , GetWayPoints, { value, stringOnlyWhiteSpace })
end
for _, value in pairs(OASISAddressParams) do
  runner.Step("GetWayPoints_wayPoints_newLine_searchAddress_" .. value , GetWayPoints,
    { "searchAddress", { [value] = stringNewLine }})
  runner.Step("GetWayPoints_wayPoints_tab_searchAddress_" .. value , GetWayPoints,
    { "searchAddress", { [value] = stringTab }})
  runner.Step("GetWayPoints_wayPoints_whitespace_searchAddress_" .. value , GetWayPoints,
    { "searchAddress", { [value] = stringOnlyWhiteSpace }})
end
runner.Step("GetWayPoints_wayPoints_newLine_value_addressLines" , GetWayPoints,
    { "addressLines", { stringNewLine }})
runner.Step("GetWayPoints_wayPoints_tab_value_addressLines" , GetWayPoints,
    { "addressLines", { stringTab }})
runner.Step("GetWayPoints_wayPoints_whitespace_value_addressLines" , GetWayPoints,
    { "addressLines", { stringOnlyWhiteSpace }})
for _, value in pairs(imageTypes) do
  runner.Step("GetWayPoints_wayPoints_newLine_locationImage_value_" .. value , GetWayPoints,
    { "locationImage", { value = stringNewLine, imageType = value }})
  runner.Step("GetWayPoints_wayPoints_tab_locationImage_value_" .. value , GetWayPoints,
    { "locationImage", { value = stringTab, imageType = value }})
  runner.Step("GetWayPoints_wayPoints_whitespace_locationImage_value_" .. value , GetWayPoints,
    { "locationImage", { value = stringOnlyWhiteSpace, imageType = value }})
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
