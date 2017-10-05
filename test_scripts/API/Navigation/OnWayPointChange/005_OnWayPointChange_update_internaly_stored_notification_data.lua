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
-- 1) One application requested to unsubscribe from receiving notifications on destination & waypoints changes
--    (other mobile applications remain subscribed)
--    Any change in destination or waypoints is registered on HMI (user set new route, canselled the route,
--    arrived at destination point or crossed a waypoint)
-- 2) HMI sends the notification about changes to SDL

-- SDL must:
-- 1) Update of internaly stored notification data in case new notification came from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonNavigation = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
local firstNotification = {
  wayPoints = {
    {
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
    }
  }
}

local secondNotification = {
  wayPoints = {
    {
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
    }
  }
}

--[[ Local Functions ]]
local function firstOnWayPointChange(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", firstNotification)
  self.mobileSession1:ExpectNotification("OnWayPointChange", firstNotification)
end

local function subscribeApp2(self)
  commonNavigation.subscribeWayPoints(2, self)
  self.mobileSession2:ExpectNotification("OnWayPointChange", firstNotification)
end

local function secondOnWayPointChange(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", secondNotification)
  self.mobileSession1:ExpectNotification("OnWayPointChange", secondNotification)
  self.mobileSession2:ExpectNotification("OnWayPointChange", secondNotification)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonNavigation.start)

for i = 1, 2 do
  runner.Step("RAI, PTU " .. i, commonNavigation.registerAppWithPTU, { i })
  runner.Step("Activate App " .. i, commonNavigation.activateApp, { i })
end

runner.Title("Test")
runner.Step("First app subscribe OnWayPointChange", commonNavigation.subscribeWayPoints)
runner.Step("First OnWayPointChange", firstOnWayPointChange)
runner.Step("Second app subscribe OnWayPointChange", subscribeApp2)
runner.Step("Second OnWayPointChange to both apps", secondOnWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonNavigation.postconditions)
