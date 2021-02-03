---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/SmartDeviceLink/sdl_core/issues/2354
---------------------------------------------------------------------------------------------------
-- Description: Check SDL is able to proceed with notification from HMI after cut off of fake parameters
-- Scenario: notification that SDL should use internally
--
-- Steps:
-- 1. HMI sends notification with fake parameter
-- SDL does:
--  - cut off fake parameters
--  - check whether notification is valid
--  - proceed with notification in case if it's valid
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function activateApp()
  local params = {
    appID = common.getHMIAppId(),
    fakeParam = "123"
  }
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppActivated", params)
  common.getMobileSession():ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" })
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
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
