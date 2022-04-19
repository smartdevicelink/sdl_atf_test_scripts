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
-- 1) HMI sends valid OnWayPointChange notification
-- 2) notification allowed by policies in FULL, BACKGROUND,LIMITED levels
-- 3) and not allowed in NONE HMI level
-- SDL must:
-- 1) transfer notification to mobile application in allowed HMI levels
-- 2) not transfer notification to mobile application in not alloewed HMI levels
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')

--[[ Local Variables ]]
--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application1.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application2.registerAppInterfaceParams.appHMIType = {"NAVIGATION"}

--[[ Local Variables ]]
local notificationParams = {
  wayPoints = {
    {
      coordinate =
      {
        latitudeDegrees = 1.1,
        longitudeDegrees = 1.1
      },
      locationName = "Hotel"
    }
  }
}

--[[ Local Functions ]]
local function onWayPointChangeDisallowed(notification, self)
  notification.appID = common.getHMIAppId(2)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  self.mobileSession2:ExpectNotification("OnWayPointChange")
  :Times(0)
  common.DelayedExp()
end

local function onWayPointChangeSuccess(notification, self)
  notification.appID = common.getHMIAppId(1)
  self.hmiConnection:SendNotification("Navigation.OnWayPointChange", notification)
  self.mobileSession1:ExpectNotification("OnWayPointChange")
end

local function BringAppToLimitedLevel(self)
  local appIDval = common.getHMIAppId(1)
  self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated",
   { appID = appIDval })
  self.mobileSession1:ExpectNotification("OnHMIStatus", { hmiLevel = "LIMITED" })
end

local function BringAppToBackgroundLevel(self)
  common.activateApp(2, self)
  self.mobileSession1:ExpectNotification("OnHMIStatus",{ hmiLevel = "BACKGROUND" })
end

local function ptuUpdateFunc(pTbl)
    pTbl.policy_table.functional_groupings["WayPoints"].rpcs.OnWayPointChange =
    { hmi_levels = {"BACKGROUND","FULL","LIMITED" }}
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU first app", common.registerAppWithPTU, {1, ptuUpdateFunc})
runner.Step("RAI, PTU second app", common.registerAppWithPTU, {2, ptuUpdateFunc})
runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe OnWayPointChange", common.subscribeWayPoints)

runner.Title("Test")
runner.Step("OnWayPointChange_in_NONE", onWayPointChangeDisallowed, { notificationParams })
runner.Step("OnWayPointChange_in_FULL", onWayPointChangeSuccess, { notificationParams })
runner.Step("Bring_app_to_limited", BringAppToLimitedLevel)
runner.Step("OnWayPointChange_in_LIMITED", onWayPointChangeSuccess, { notificationParams })
runner.Step("Bring_app_to_background", BringAppToBackgroundLevel)
runner.Step("OnWayPointChange_in_BACKGROUND", onWayPointChangeSuccess, { notificationParams })

runner.Title("Postconditions")
runner.Step("Unsubscribe OnWayPointChange", common.unsubscribeWayPoints)
runner.Step("Stop SDL", common.postconditions)
