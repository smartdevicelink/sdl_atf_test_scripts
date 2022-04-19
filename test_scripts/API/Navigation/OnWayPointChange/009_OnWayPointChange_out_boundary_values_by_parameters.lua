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
-- 1) HMI sends OnWayPointChange notification with out bound values

-- SDL must:
-- 1) not transfer notification to mobile application
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
runner.Title("Out lower bound")
runner.Step("OnWayPointChange_wayPoints_lower_bound_latitudeDegrees" , onWayPointChange,
    { "coordinate", { latitudeDegrees = coordinateParams.latitudeDegrees.lower, longitudeDegrees = 0.1 }})
runner.Step("OnWayPointChange_wayPoints_lower_bound_longitudeDegrees" , onWayPointChange,
    { "coordinate", { latitudeDegrees = 0.1, longitudeDegrees = coordinateParams.longitudeDegrees.lower }})

runner.Title("Out upper bound")
for _, value in pairs(LocationDetailsStringParams) do
  runner.Step("OnWayPointChange_wayPoints_upper_bound_" .. value , onWayPointChange, { value, string501char })
end
for k, value in pairs(OASISAddressParams) do
  runner.Step("OnWayPointChange_wayPoints_upper_bound_searchAddress_" .. k , onWayPointChange,
    { "searchAddress", { [k] = value.upper }})
end
runner.Step("OnWayPointChange_wayPoints_upper_bound_value_addressLines" , onWayPointChange,
    { "addressLines", { string501char }})
runner.Step("OnWayPointChange_wayPoints_upper_bound_array_addressLines" , onWayPointChange,
    { "addressLines", maxAddressLinesArray })
runner.Step("OnWayPointChange_wayPoints_upper_bound_latitudeDegrees" , onWayPointChange,
    { "coordinate", { latitudeDegrees = coordinateParams.latitudeDegrees.upper, longitudeDegrees = 0.1 }})
runner.Step("OnWayPointChange_wayPoints_upper_bound_longitudeDegrees" , onWayPointChange,
    { "coordinate", { latitudeDegrees = 0.1, longitudeDegrees = coordinateParams.longitudeDegrees.upper }})
for _, value in pairs(imageTypes) do
  runner.Step("OnWayPointChange_wayPoints_upper_bound_locationImage_value_" .. value , onWayPointChange,
    { "locationImage", { value = string65536char, imageType = value }})
end

runner.Title("Postconditions")
runner.Step("Subscribe OnWayPointChange", common.unsubscribeWayPoints)
runner.Step("Stop SDL", common.postconditions)
