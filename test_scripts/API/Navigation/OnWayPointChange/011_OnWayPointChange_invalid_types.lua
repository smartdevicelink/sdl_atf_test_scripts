---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/28
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Notification_about_changes_to_Destination_or_Waypoints.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [OnWayPointChange] As a mobile application I want to be able to be notified on changes
-- to Destination or Waypoints based on my subscription
--
-- Description:
-- In case:
-- 1) HMI sends OnWayPointChange notification with invalid type of parameters

-- SDL must:
-- 1) not transfer notification to mobile application
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
local function onWayPointChange(parameter, value, self)
   local notification = { }
  notification.wayPoints = {{ [parameter] = value }}
  notification.appID = common.getHMIAppId()
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  self.mobileSession1:ExpectNotification("OnWayPointChange")
  :Times(0)
  common.DelayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe OnWayPointChange", common.subscribeWayPoints)

runner.Title("Test")
runner.Step("OnWayPointChange_wayPoints_invalid_type_latitudeDegrees" , onWayPointChange,
    { "coordinate", { latitudeDegrees = stringType, longitudeDegrees = 0.1 }})
runner.Step("OnWayPointChange_wayPoints_invalid_type_longitudeDegrees" , onWayPointChange,
    { "coordinate", { latitudeDegrees = 0.1, longitudeDegrees = stringType }})
for _, value in pairs(LocationDetailsStringParams) do
  runner.Step("OnWayPointChange_wayPoints_invalid_type_" .. value , onWayPointChange, { value, intType })
end
for _, value in pairs(OASISAddressParams) do
  runner.Step("OnWayPointChange_wayPoints_invalid_type_searchAddress_" .. value , onWayPointChange,
    { "searchAddress", { [value] = intType }})
end
runner.Step("OnWayPointChange_wayPoints_invalid_type_value_addressLines" , onWayPointChange,
    { "addressLines", { intType }})
runner.Step("OnWayPointChange_wayPoints_invalid_type_array_addressLines" , onWayPointChange,
    { "addressLines", intType })
runner.Step("OnWayPointChange_wayPoints_invalid_type_locationImage_value", onWayPointChange,
    { "locationImage", { value = intType, imageType = "DYNAMIC" }})
runner.Step("OnWayPointChange_wayPoints_invalid_type_locationImage_type", onWayPointChange,
    { "locationImage", { value = "image", imageType = intType }})

runner.Title("Postconditions")
runner.Step("Subscribe OnWayPointChange", common.unsubscribeWayPoints)
runner.Step("Stop SDL", common.postconditions)
