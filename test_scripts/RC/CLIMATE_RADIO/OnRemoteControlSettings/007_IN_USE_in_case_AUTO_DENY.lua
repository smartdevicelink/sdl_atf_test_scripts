---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Alternative flow 1
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #4
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with allowed:true
-- 2) and parameter "accessMode" = "AUTO_DENY"
-- 3) and RC_module on HMI is alreay in control by RC-application
-- SDL must:
-- 1) deny access to RC_module for another RC_application in HMILevel FULL after it sends control RPC
-- (either SetInteriorVehicleData or ButtonPress) for the same RC_module without asking a driver
-- 2) respond with result code IN_USE, success:false
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
runner.Step("Set RA mode: AUTO_DENY", commonRC.defineRAMode, { true, "AUTO_DENY" })

for _, mod in pairs(commonRC.modules)  do
  runner.Title("Module: " .. mod)
  -- set control for App1
  runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  -- set control for App2 --> Denied
  runner.Step("App2 SetInteriorVehicleData", commonRC.rpcDenied, { mod, 2, "SetInteriorVehicleData", "IN_USE" })
  runner.Step("App2 ButtonPress", commonRC.rpcDenied, { mod, 2, "ButtonPress", "IN_USE" })
  -- set control for App1 --> Allowed
  runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })
  runner.Step("App1 ButtonPress", commonRC.rpcAllowed, { mod, 1, "ButtonPress" })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
