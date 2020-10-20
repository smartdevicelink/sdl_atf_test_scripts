---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Processing of the OnExitApplication notification with reason RESOURCE_CONSTRAINT from HMI
--  (single application)
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App is registered on default mobile connection
-- 4. App is activated
--
-- Sequence:
-- 1. HMI sends BC.OnExitApplication with reason: "RESOURCE_CONSTRAINT" related to App to SDL
--  a. SDL unregisters App and send OnAppInterfaceUnregistered notification with reason: "RESOURCE_CONSTRAINT" to it
--  b. SDL sends BasicCommunication.OnAppUnregistered notification related to App with unexpectedDisconnect: false
--  c. SDL closes mobile connection
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("OnExitApplication", common.processResourceConstraintExit)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
