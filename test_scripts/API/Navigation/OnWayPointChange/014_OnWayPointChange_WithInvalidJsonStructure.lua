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
-- 2) HMI sends notification with invalid json struct

-- SDL must:
-- 1) SDL validates notification and ignore it
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Navigation/commonNavigation')


--[[ Local Functions ]]
local function onWayPointChange(self)
  self.hmiConnection:Send('{"params":{"wayPoints":{ "locationName":"test"},"method":"Navigation.OnWayPointChange"},"jsonrpc":"2.0"}')
  self.mobileSession1:ExpectNotification("OnWayPointChange", {}):Times(0)
  common:DelayedExp()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.registerAppWithPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Subscribe OnWayPointChange", common.subscribeWayPoints)

runner.Title("Test")
runner.Step("OnWayPointChange", onWayPointChange)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
