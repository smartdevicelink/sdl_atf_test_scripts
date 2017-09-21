---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/28
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/embedded_navi/Notification_about_changes_to_Destination_or_Waypoints.md
-- Item: Use Case 1: Exception 1: Notification about changes to destination or waypoints is not allowed by Policies for mobile application
--
-- Requirement summary:
-- [OnWayPointChange] As a mobile application I want to be able to be notified on changes 
-- to Destination or Waypoints based on my subscription
--
-- Description:
-- In case:
-- 1) SDL and HMI are started, Navi interface and embedded navigation source are available on HMI,
--    mobile applications are registered on SDL and subscribed on destination and waypoints changes notification
-- 2) Notification about changes to destination or waypoints is not allowed by Policies for mobile application

-- SDL must:
-- 1) SDL doesn't transfer the notification to such mobile application
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

local function allowSubscribeWayPoints(tbl, app_id)
  tbl.policy_table.functional_groupings["SubscribeWayPoints"] = {
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED", "NONE" }
      }
    }
  }
  tbl.policy_table.app_policies[commonLastMileNavigation.getMobileAppId(app_id)] = commonLastMileNavigation.getSubscribeWayPointsConfig()
end

local function OnWayPointChange(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)       
  self.mobileSession1:ExpectNotification("OnWayPointChange", notification):Times(0)
  commonTestCases:DelayedExp(commonLastMileNavigation.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonLastMileNavigation.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonLastMileNavigation.start)
runner.Step("RAI, PTU", commonLastMileNavigation.registerAppWithPTU, { 1 , allowSubscribeWayPoints })
runner.Step("Activate App", commonLastMileNavigation.activateApp)
runner.Step("Subscribe OnWayPointChange", commonLastMileNavigation.subscribeOnWayPointChange, { 1 })
runner.Title("Test")

runner.Step("OnWayPointChange", OnWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonLastMileNavigation.postconditions)
