---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/28
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Notification_about_changes_to_Destination_or_Waypoints.md
-- Item: Use Case 1: Alternative flow 1
--
-- Requirement summary:
-- [OnWayPointChange] As a mobile application I want to be able to be notified on changes 
-- to Destination or Waypoints based on my subscription
--
-- Description:
-- In case:
-- 1) One application requested to unsubscribe from receiving notifications on destination & waypoints changes (other mobile applications remain subscribed)
--    Any change in destination or waypoints is registered on HMI (user set new route, canselled the route, arrived at destination point or crossed a waypoint)
-- 2) HMI sends the notification about changes to SDL

-- SDL must:
-- 1) SDL does not transfer the notification to unsubscribed mobile application
--    SDL transfers the notification to subscribed mobile applications
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonLastMileNavigation = require('test_scripts/API/LastMileNavigation/commonLastMileNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

local notification ={}
  notification.wayPoints =
  {{
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
  } }


--[[ Local Functions ]]

local function OnWayPointChangeToBothApps(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)       
  self.mobileSession1:ExpectNotification("OnWayPointChange", notification)  
  self.mobileSession2:ExpectNotification("OnWayPointChange", notification)
end

local function OnWayPointChangeToOneApp(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)       
  self.mobileSession1:ExpectNotification("OnWayPointChange", notification)  
  self.mobileSession2:ExpectNotification("OnWayPointChange", notification):Times(0)
  commonTestCases:DelayedExp(5 * commonLastMileNavigation.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonLastMileNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonLastMileNavigation.start)
runner.Step("RAI1, PTU1", commonLastMileNavigation.registerAppWithPTU)
runner.Step("Activate 1st app", commonLastMileNavigation.activateApp)
runner.Step("First app subscribe OnWayPointChange", commonLastMileNavigation.subscribeOnWayPointChange, { 1 })
runner.Step("RAI2, PTU2", commonLastMileNavigation.registerAppWithPTU, { 2 })
runner.Step("Activate 2nd app", commonLastMileNavigation.activateApp, { 2 })
runner.Step("Second app subscribe OnWayPointChange", commonLastMileNavigation.subscribeOnWayPointChange, { 2 })

runner.Title("Test")
runner.Step("OnWayPointChange to both apps", OnWayPointChangeToBothApps)
runner.Step("Second app unsubscribe OnWayPointChange", commonLastMileNavigation.unsubscribeOnWayPointChange, { 2 })
runner.Step("OnWayPointChange to one app", OnWayPointChangeToOneApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonLastMileNavigation.postconditions)
