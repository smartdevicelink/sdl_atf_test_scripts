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
--    arrived at destination point or crossed a waypoint) and HMI sends several fake params

-- SDL must:
-- 1) Transfer the notification about changes to destination or waypoints to mobile application without fake params
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Local Variables ]]
local NotificationWithFakeParams =
		{
			wayPoints=
			{
				{
					coordinate={
						longitudeDegrees = -180.0,
						latitudeDegrees = -90.0,
						fake="a"
					},
					locationName="Odessa",
					addressLines={"Bolshaya Arnautskaya 72/74"},
					locationDescription="Luxoft",
					phoneNumber="1231414",
					locationImage={
						value = "icon.png",
						imageType = "DYNAMIC",
						fake="a"
					},
					searchAddress={
						countryName="UA",
						countryCode="380",
						postalCode="65045",
						administrativeArea="aa",
						subAdministrativeArea="a",
						locality="a",
						subLocality="a",
						thoroughfare="a",
						subThoroughfare="a",
						fake="a"
					},
					fake="fakeparam"
				},
			},
			fake="fakeparam"
		}

		local NotificationWithoutFakeParams =
		{
			wayPoints=
			{
				{
					coordinate={
						longitudeDegrees = -180.0,
						latitudeDegrees = -90.0
					},
					locationName="Odessa",
					addressLines={"Bolshaya Arnautskaya 72/74"},
					locationDescription="Luxoft",
					phoneNumber="1231414",
					locationImage={
						value = "icon.png",
						imageType = "DYNAMIC"
					},
					searchAddress={
						countryName="UA",
						countryCode="380",
						postalCode="65045",
						administrativeArea="aa",
						subAdministrativeArea="a",
						locality="a",
						subLocality="a",
						thoroughfare="a",
						subThoroughfare="a"
					}
				}
			}
		}

--[[ Local Functions ]]
local function onWayPointChange(self)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", NotificationWithFakeParams)
  self.mobileSession1:ExpectNotification("OnWayPointChange", NotificationWithoutFakeParams)
  :ValidIf (function(_, data)
			 if data.payload.fake or
			    data.payload.wayPoints[1].fake or
				data.payload.wayPoints[1].coordinate.fake or
				data.payload.wayPoints[1].searchAddress.fake or
				data.payload.wayPoints[1].locationImage.fake
			 then
				commonFunctions:printError(" SDL resends fake parameter to mobile app ")
				return false
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
runner.Step("Subscribe OnWayPointChange", common.subscribeWayPoints)

runner.Title("Test")
runner.Step("OnWayPointChange with fake params", onWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
