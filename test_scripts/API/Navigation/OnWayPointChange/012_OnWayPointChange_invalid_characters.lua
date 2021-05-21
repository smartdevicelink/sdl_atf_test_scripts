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
-- 1) HMI sends OnWayPointChange notification with invalid characters \n, \t, whitespace only

-- SDL must:
-- 1) not transfer notification to mobile application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local stringNewLine = "str\ning"
local stringTab = "str\ting"
local stringOnlyWhiteSpace = " "
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
for _, value in pairs(LocationDetailsStringParams) do
  runner.Step("OnWayPointChange_wayPoints_newLine_" .. value , onWayPointChange, { value, stringNewLine })
  runner.Step("OnWayPointChange_wayPoints_tab_" .. value , onWayPointChange, { value, stringTab })
  runner.Step("OnWayPointChange_wayPoints_whitespace_" .. value , onWayPointChange, { value, stringOnlyWhiteSpace })
end
for _, value in pairs(OASISAddressParams) do
  runner.Step("OnWayPointChange_wayPoints_newLine_searchAddress_" .. value , onWayPointChange,
    { "searchAddress", { [value] = stringNewLine }})
  runner.Step("OnWayPointChange_wayPoints_tab_searchAddress_" .. value , onWayPointChange,
    { "searchAddress", { [value] = stringTab }})
  runner.Step("OnWayPointChange_wayPoints_whitespace_searchAddress_" .. value , onWayPointChange,
    { "searchAddress", { [value] = stringOnlyWhiteSpace }})
end
runner.Step("OnWayPointChange_wayPoints_newLine_value_addressLines" , onWayPointChange,
    { "addressLines", { stringNewLine }})
runner.Step("OnWayPointChange_wayPoints_tab_value_addressLines" , onWayPointChange,
    { "addressLines", { stringTab }})
runner.Step("OnWayPointChange_wayPoints_whitespace_value_addressLines" , onWayPointChange,
    { "addressLines", { stringOnlyWhiteSpace }})
for _, value in pairs(imageTypes) do
  runner.Step("OnWayPointChange_wayPoints_newLine_locationImage_value_" .. value , onWayPointChange,
    { "locationImage", { value = stringNewLine, imageType = value }})
  runner.Step("OnWayPointChange_wayPoints_tab_locationImage_value_" .. value , onWayPointChange,
    { "locationImage", { value = stringTab, imageType = value }})
  runner.Step("OnWayPointChange_wayPoints_whitespace_locationImage_value_" .. value , onWayPointChange,
    { "locationImage", { value = stringOnlyWhiteSpace, imageType = value }})
end

runner.Title("Postconditions")
runner.Step("Subscribe OnWayPointChange", common.unsubscribeWayPoints)
runner.Step("Stop SDL", common.postconditions)
