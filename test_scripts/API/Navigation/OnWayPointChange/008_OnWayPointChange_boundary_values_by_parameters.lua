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
-- 1) SDL and HMI are started, Navi interface and embedded navigation source are available on HMI,
--    mobile applications are registered on SDL and subscribed on destination and waypoints changes notification
-- 2) Any change in destination or waypoints is registered on HMI (user set new route, canselled the route,
--    arrived at destination point or crossed a waypoint)

-- SDL must:
-- 1) Transfer the notification about changes to destination or waypoints to mobile application
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
local minLen = ""
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
local function onWayPointChange(parameter, value, self)
   local notification = { }
  notification.wayPoints = {{ [parameter] = value }}
  notification.appID = common.getHMIAppId()
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  self.mobileSession1:ExpectNotification("OnWayPointChange", {wayPoints = notification.wayPoints})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe OnWayPointChange", common.subscribeWayPoints)

runner.Title("Test")
runner.Title("Lower bound")
for _, value in pairs(LocationDetailsStringParams) do
  runner.Step("OnWayPointChange_wayPoints_lower_bound_" .. value , onWayPointChange, { value, minLen })
end
for k, value in pairs(OASISAddressParams) do
  runner.Step("OnWayPointChange_wayPoints_lower_bound_searchAddress_" .. k , onWayPointChange,
    { "searchAddress", { [k] = value.lower }})
end
runner.Step("OnWayPointChange_wayPoints_lower_bound_value_array_addressLines" , onWayPointChange,
    { "addressLines", { minLen }})
runner.Step("OnWayPointChange_wayPoints_lower_bound_latitudeDegrees" , onWayPointChange,
    { "coordinate", { latitudeDegrees = coordinateParams.latitudeDegrees.lower, longitudeDegrees = 0.1 }})
runner.Step("OnWayPointChange_wayPoints_lower_bound_longitudeDegrees" , onWayPointChange,
    { "coordinate", { latitudeDegrees = 0.1, longitudeDegrees = coordinateParams.longitudeDegrees.lower }})
for _, value in pairs(imageTypes) do
  runner.Step("OnWayPointChange_wayPoints_lower_bound_locationImage_value_" .. value , onWayPointChange,
    { "locationImage", { value = "", imageType = value }})
end

runner.Title("Upper bound")
for _, value in pairs(LocationDetailsStringParams) do
  runner.Step("OnWayPointChange_wayPoints_upper_bound_" .. value , onWayPointChange, { value, string500char })
end
for k, value in pairs(OASISAddressParams) do
  runner.Step("OnWayPointChange_wayPoints_upper_bound_searchAddress_" .. k , onWayPointChange,
    { "searchAddress", { [k] = value.upper }})
end
runner.Step("OnWayPointChange_wayPoints_upper_bound_value_addressLines" , onWayPointChange,
    { "addressLines", { string500char }})
runner.Step("OnWayPointChange_wayPoints_upper_bound_array_addressLines" , onWayPointChange,
    { "addressLines", maxAddressLinesArray })
runner.Step("OnWayPointChange_wayPoints_upper_bound_value_array_addressLines" , onWayPointChange,
    { "addressLines", maxAddressLinesArrayValue })
runner.Step("OnWayPointChange_wayPoints_upper_bound_latitudeDegrees" , onWayPointChange,
    { "coordinate", { latitudeDegrees = coordinateParams.latitudeDegrees.upper, longitudeDegrees = 0.1 }})
runner.Step("OnWayPointChange_wayPoints_upper_bound_longitudeDegrees" , onWayPointChange,
    { "coordinate", { latitudeDegrees = 0.1, longitudeDegrees = coordinateParams.longitudeDegrees.upper }})
for _, value in pairs(imageTypes) do
  runner.Step("OnWayPointChange_wayPoints_upper_bound_locationImage_value_" .. value , onWayPointChange,
    { "locationImage", { value = string65535char, imageType = value }})
end

runner.Title("Postconditions")
runner.Step("Subscribe OnWayPointChange", common.unsubscribeWayPoints)
runner.Step("Stop SDL", common.postconditions)
