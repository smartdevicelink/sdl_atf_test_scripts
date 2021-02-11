---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/2379
---------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to ignore notification from HMI after cut off of fake parameters
-- and notification becomes invalid
-- Scenario: notification that SDL should use internally
--
-- Steps:
-- 1. HMI sends notification with fake parameter
-- SDL does:
--  - cut off fake parameters
--  - check whether notification is valid
--  - ignore notification in case if it's invalid
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function activateApp()
  local params = {
    appID = "123", --invalid data type
    fakeParam = "123"
  }
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppActivated", params)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect regular mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)

runner.Title("Test")
runner.Step("HMI sends OnAppActivated", activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL, restore SDL settings and PPT", common.postconditions)
