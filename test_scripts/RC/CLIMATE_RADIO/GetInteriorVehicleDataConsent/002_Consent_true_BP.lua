---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/RC/resource_allocation.md
-- Item: Use Case 1: Alternative flow 2
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #5; TRS: GetInteriorVehicleDataConsent, #1
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with "ASK_DRIVER" access mode
-- 2) and RC application (in HMILevel FULL) requested access to remote control module
-- that is already allocated to another RC application
-- 3) and SDL requested user consent from HMI via GetInteriorVehicleDataConsent
-- 4) and user allowed access to RC module for requested application
-- SDL must:
-- 1) allocate access to RC module to requested application
-- 2) process control request from this application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1", commonRC.registerAppWOPTU)
runner.Step("Activate App1", commonRC.activateApp)
runner.Step("RAI2", commonRC.registerAppWOPTU, { 2 })
runner.Step("Activate App2", commonRC.activateApp, { 2 })

runner.Title("Test")
runner.Step("Set RA mode: ASK_DRIVER", commonRC.defineRAMode, { true, "ASK_DRIVER" })

for _, mod in pairs(commonRC.modules) do
  runner.Title("Module: " .. mod)
  -- set control for App1
  runner.Step("App1 ButtonPress", commonRC.rpcAllowed, { mod, 1, "ButtonPress" })
  -- set control for App2 --> Ask driver --> HMI: allowed:true
  runner.Step("App2 SetInteriorVehicleData 1st SUCCESS", commonRC.rpcAllowedWithConsent, { mod, 2, "SetInteriorVehicleData" })
  runner.Step("App2 SetInteriorVehicleData 2nd SUCCESS", commonRC.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
