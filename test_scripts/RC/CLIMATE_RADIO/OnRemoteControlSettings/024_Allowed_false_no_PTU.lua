---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/11
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/rc_enabling_disabling.md
-- Item: Use Case 1: Main Flow (updates https://github.com/smartdevicelink/sdl_core/issues/2173)
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- SDL received OnRemoteControlSettings (allowed:false) from HMI
--
-- SDL must:
-- 1) store RC state allowed:false internally
-- 2) keep all applications with appHMIType REMOTE_CONTROL registered and in current HMI levels
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application3.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function disableRCFromHMI()
  commonRC.defineRAMode(false, nil)

 commonRC.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
  commonRC.getMobileSession(2):ExpectNotification("OnHMIStatus")
  :Times(0)
  commonRC.getMobileSession(3):ExpectNotification("OnHMIStatus")
  :Times(0)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(0)
  commonRC.wait(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)

for i = 1, 3 do
  runner.Step("RAI " .. i, commonRC.registerAppWOPTU, { i })
  runner.Step("Activate App " .. i, commonRC.activateApp, { i })
end

runner.Title("Test")
runner.Step("Disable RC from HMI", disableRCFromHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
