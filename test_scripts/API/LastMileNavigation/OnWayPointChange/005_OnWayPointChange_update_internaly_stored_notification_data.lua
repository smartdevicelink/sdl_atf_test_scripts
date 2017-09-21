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
-- 1) Update of internaly stored notification data in case new notification came from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonLastMileNavigation = require('test_scripts/API/LastMileNavigation/commonLastMileNavigation')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

local firstNotification ={}
  firstNotification.wayPoints =
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

  local secondNotification ={}
  secondNotification.wayPoints =
  {{
      coordinate =
      {
        latitudeDegrees = 2.1,
        longitudeDegrees = 2.1
      },
      locationName = "Home",
      addressLines =
      {
        "Street 36"
      },
      locationDescription = "MyHome",
      phoneNumber = "009300434",
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
local function FirstOnWayPointChangeAndSubscribeApp2(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", firstNotification)       
  self.mobileSession1:ExpectNotification("OnWayPointChange", firstNotification) 
  commonLastMileNavigation.subscribeOnWayPointChange(2, self) -- subscribe second app
  self.mobileSession2:ExpectNotification("OnWayPointChange", firstNotification)
end

local function SecondOnWayPointChange(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", secondNotification)       
  self.mobileSession1:ExpectNotification("OnWayPointChange", secondNotification) 
  self.mobileSession2:ExpectNotification("OnWayPointChange", secondNotification)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonLastMileNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonLastMileNavigation.start)
runner.Step("RAI1, PTU1", commonLastMileNavigation.registerAppWithPTU)
runner.Step("Activate 1st app", commonLastMileNavigation.activateApp)
runner.Step("RAI2, PTU2", commonLastMileNavigation.registerAppWithPTU, { 2 })
runner.Step("Activate 2nd app", commonLastMileNavigation.activateApp, { 2 })
runner.Step("First app subscribe OnWayPointChange", commonLastMileNavigation.subscribeOnWayPointChange, { 1 })

runner.Title("Test")
runner.Step("First OnWayPointChange and subscribe app2", FirstOnWayPointChangeAndSubscribeApp2)
runner.Step("Second OnWayPointChange to both apps", SecondOnWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonLastMileNavigation.postconditions)
