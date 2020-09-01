---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Processing of the OnExitApplication notification with reason RESOURCE_CONSTRAINT from HMI
--  (multiple applications on different connections)
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. App1 is registered on mobile connection 1
-- 3. App2 is registered on web engine connection 2
-- 4. App2 is activated
--
-- Sequence:
-- 1. HMI sends BC.OnExitApplication with reason: "RESOURCE_CONSTRAINT" related to App2 to SDL
--  a. SDL unregisters App2 and send OnAppInterfaceUnregistered notification with reason: "RESOURCE_CONSTRAINT" to it
--  b. SDL sends BasicCommunication.OnAppUnregistered notification related to App2 with unexpectedDisconnect: false
--  c. SDL closes web engine connection 2
--  d. SDL does not close mobile connection 1
--  e. SDL does not send OnAppInterfaceUnregistered notification with reason: "RESOURCE_CONSTRAINT" to App1
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId1 = 1
local appSessionId2 = 2
local devices = {
  default = 1,
  webEngine = 2
}

-- [[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect mobile", common.start)
common.Step("Connect web engine device", common.connectWebEngine, { devices.webEngine, "WS" })
common.Step("Register App1", common.registerAppWOPTU, { appSessionId1, devices.default })
common.Step("Register App2", common.registerAppWOPTU, { appSessionId2, devices.webEngine })
common.Step("Activate App1", common.activateApp, { appSessionId1 })
common.Step("Activate App2", common.activateApp, { appSessionId2 })

common.Title("Test")
common.Step("App2 receives OnExitApplication", common.processResourceConstraintExit,
  { appSessionId2, devices.webEngine, { devices.default }})

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
