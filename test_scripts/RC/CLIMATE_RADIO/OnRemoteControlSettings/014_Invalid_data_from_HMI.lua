---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- 1) HMI sends OnRemoteControlSettings notification with invalid parameters
-- SDL must:
-- 1) Do not take into account this request
-- 2) Leave previously defined access mode
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function setRAMode()
  local rpc = "OnRemoteControlSettings"
  local params = {
    allowed = "aaa" -- invalid type of parameter
  }
  commonRC.getHMIConnection():SendNotification(commonRC.getHMIEventName(rpc), params)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1", commonRC.registerAppWOPTU)
runner.Step("Activate App1", commonRC.activateApp)
runner.Step("RAI2", commonRC.registerAppWOPTU, { 2 })

runner.Title("Test")

for _, mod in pairs(commonRC.modules)  do
  runner.Title("Module: " .. mod)
  runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })

  runner.Title("RA mode Default AUTO_ALLOW")
  runner.Step("Activate App2", commonRC.activateApp, { 2 })
  runner.Step("Send OnRemoteControlSettings with invalid data", setRAMode)
  runner.Step("App2 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })

  runner.Title("RA mode AUTO_DENY")
  runner.Step("Set RA mode", commonRC.defineRAMode, { true, "AUTO_DENY" })
  runner.Step("Activate App1", commonRC.activateApp, { 1 })
  runner.Step("Send OnRemoteControlSettings with invalid data", setRAMode)
  runner.Step("App2 SetInteriorVehicleData", commonRC.rpcDenied, { mod, 1, "SetInteriorVehicleData", "IN_USE" })

  runner.Title("RA mode ASK_DRIVER")
  runner.Step("Set RA mode", commonRC.defineRAMode, { true, "ASK_DRIVER" })
  runner.Step("Send OnRemoteControlSettings with invalid data", setRAMode)
  runner.Step("App2 ButtonPress 1st SUCCESS", commonRC.rpcAllowedWithConsent, { mod, 1, "SetInteriorVehicleData" })
  runner.Step("App2 ButtonPress 2nd SUCCESS", commonRC.rpcAllowed, { mod, 1, "SetInteriorVehicleData" })

  runner.Title("RA mode AUTO_ALLOW")
  runner.Step("Set RA mode", commonRC.defineRAMode, { true, "AUTO_ALLOW" })
  runner.Step("Activate App2", commonRC.activateApp, { 2 })
  runner.Step("Send OnRemoteControlSettings with invalid data", setRAMode)
  runner.Step("App2 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })
  runner.Step("Activate App1", commonRC.activateApp, { 1 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
