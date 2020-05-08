---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Exception 1.1
--
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Exception 2.2
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- RC_functionality is disabled on HMI and HMI sends notification OnRemoteControlSettings (allowed:true, <any_accessMode>)
--
-- SDL must:
-- 1) store RC state allowed:true and received from HMI internally
-- 2) allow RC functionality for applications with REMOTE_CONTROL appHMIType
--
-- Additional checks:
-- - Result code SUCCESS in AUTO_DENY access mode after unregister app which allocated resource on
-- - Result code SUCCESS in ASK_DRIVER access mode after unregister app which allocated resource on
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application3.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions, { true, 3 })
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI1", commonRC.registerAppWOPTU)
runner.Step("RAI2", commonRC.registerAppWOPTU, { 2 })
runner.Step("RAI3", commonRC.registerAppWOPTU, { 3 })

runner.Title("Test")
runner.Title("Default -> ASK_DRIVER")
runner.Step("Enable RC from HMI with ASK_DRIVER access mode", commonRC.defineRAMode, { true, "ASK_DRIVER"})
runner.Step("Activate App2", commonRC.activateApp, { 2 })
runner.Step("Module CLIMATE App2 SetInteriorVehicleData allowed", commonRC.rpcAllowed, { "CLIMATE", 2, "SetInteriorVehicleData" })
runner.Step("Activate App1", commonRC.activateApp)
runner.Step("Module RADIO App1 ButtonPress allowed", commonRC.rpcAllowed, { "RADIO", 1, "ButtonPress" })
runner.Step("Unregister App2", commonRC.unregisterApp, { 2 })
runner.Step("Module CLIMATE App1 ButtonPress allowed", commonRC.rpcAllowed, { "CLIMATE", 1, "ButtonPress" })
runner.Step("Activate App3", commonRC.activateApp, { 3 })
runner.Step("Activate App1", commonRC.activateApp, { 1 })
runner.Title("ASK_DRIVER -> AUTO_DENY")
runner.Step("Enable RC from HMI with AUTO_DENY access mode", commonRC.defineRAMode, { true, "AUTO_DENY"})
runner.Step("Unregister App1", commonRC.unregisterApp, { 1 })
runner.Step("Module CLIMATE App3 SetInteriorVehicleData allowed", commonRC.rpcAllowed, { "CLIMATE", 3, "SetInteriorVehicleData" })
runner.Title("AUTO_DENY -> AUTO_ALLOW")
runner.Step("Enable RC from HMI with AUTO_ALLOW access mode", commonRC.defineRAMode, { true, "AUTO_ALLOW"})
runner.Step("Module RADIO App3 ButtonPress allowed", commonRC.rpcAllowed, { "RADIO", 3, "ButtonPress" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
