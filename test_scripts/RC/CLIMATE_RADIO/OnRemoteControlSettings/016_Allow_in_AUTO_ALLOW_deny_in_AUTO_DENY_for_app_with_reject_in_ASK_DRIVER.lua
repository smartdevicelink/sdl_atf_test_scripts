---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/10
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/resource_allocation.md
-- Item: Use Case 1: Alternative flow 2.1
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
-- - Result code IN_USE in AUTO_DENY access mode for previously rejected apps in ASK_DRIVER access mode
-- - Result code SUCCESS in AUTO_ALLOW access mode for previously rejected apps in ASK_DRIVER access mode
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
runner.Step("RAI2", commonRC.registerAppWOPTU, { 2 })
runner.Title("Default -> ASK_DRIVER")
runner.Step("Enable RC from HMI with ASK_DRIVER access mode", commonRC.defineRAMode, { true, "ASK_DRIVER"})
runner.Step("Activate App2", commonRC.activateApp, { 2 })
runner.Step("Module CLIMATE App2 SetInteriorVehicleData allowed", commonRC.rpcAllowed, { "CLIMATE", 2, "SetInteriorVehicleData" })
runner.Step("Activate App1", commonRC.activateApp)
runner.Step("Module RADIO App1 SetInteriorVehicleData allowed", commonRC.rpcAllowed, { "RADIO", 1, "SetInteriorVehicleData" })
runner.Step("Check module CLIMATE App1 SetInteriorVehicleData rejected with driver consent", commonRC.rpcRejectWithConsent, { "CLIMATE", 1, "SetInteriorVehicleData" })
runner.Step("Activate App2", commonRC.activateApp, { 2 })
runner.Step("Check module RADIO App2 SetInteriorVehicleData rejected with driver consent", commonRC.rpcRejectWithConsent, { "RADIO", 2, "SetInteriorVehicleData" })

runner.Title("Test")
runner.Title("ASK_DRIVER -> AUTO_DENY")
runner.Step("Enable RC from HMI with AUTO_DENY access mode", commonRC.defineRAMode, { true, "AUTO_DENY"})
runner.Step("Check module RADIO App2 SetInteriorVehicleData denied", commonRC.rpcDenied, { "RADIO", 2, "SetInteriorVehicleData", "IN_USE" })
runner.Step("Activate App1", commonRC.activateApp)
runner.Step("Check module CLIMATE App1 SetInteriorVehicleData denied", commonRC.rpcDenied, { "CLIMATE", 1, "SetInteriorVehicleData", "IN_USE" })

runner.Title("AUTO_DENY -> AUTO_ALLOW")
runner.Step("Enable RC from HMI with AUTO_ALLOW access mode", commonRC.defineRAMode, { true, "AUTO_ALLOW"})
runner.Step("Check module CLIMATE App1 SetInteriorVehicleData allowed", commonRC.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" })
runner.Step("Activate App2", commonRC.activateApp, { 2 })
runner.Step("Check module RADIO App2 SetInteriorVehicleData allowed", commonRC.rpcAllowed, { "RADIO", 2, "SetInteriorVehicleData" })

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
