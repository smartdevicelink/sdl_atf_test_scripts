---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Main Flow
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description: TRS: OnRemoteControlSettings, #1
-- In case:
-- 1) SDL received OnRemoteControlSettings notification from HMI with allowed:true
-- 2) and "accessMode" = "AUTO_ALLOW" or without "accessMode" parameter at all
-- 3) and RC_module on HMI is alreay in control by RC-application
-- SDL must:
-- 1) provide access to RC_module for the second RC_application in HMILevel FULL after it sends control RPC
-- (either SetInteriorVehicleData or ButtonPress) for the same RC_module without asking a driver
-- 2) process the request from the second RC_application
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local access_modes = { nil, "AUTO_ALLOW" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1", commonRC.registerAppWOPTU)
runner.Step("RAI2", commonRC.registerAppWOPTU, { 2 })

runner.Title("Test")

for _, mod in pairs(commonRC.modules)  do
  runner.Title("Module: " .. mod)
  for i = 1, #access_modes do
    runner.Title("Access mode: " .. tostring(access_modes[i]))
    -- set control for App1
    runner.Step("Activate App1", commonRC.activateApp)
    runner.Step("App1 ButtonPress", commonRC.rpcAllowed, { mod, 1, "ButtonPress" })
    -- set RA mode
    runner.Step("Set RA mode", commonRC.defineRAMode, { true, access_modes[i] })
    -- set control for App2 --> Allowed
    runner.Step("Activate App2", commonRC.activateApp, { 2 })
    runner.Step("App2 SetInteriorVehicleData", commonRC.rpcAllowed, { mod, 2, "SetInteriorVehicleData" })
    runner.Step("App2 ButtonPress", commonRC.rpcAllowed, { mod, 2, "ButtonPress" })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
