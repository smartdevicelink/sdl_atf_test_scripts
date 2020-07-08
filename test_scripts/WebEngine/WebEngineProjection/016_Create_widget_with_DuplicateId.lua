---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description: Processing the creation of widget which duplicates main window ( "duplicateUpdatesFromWindowID" = 0 )
--  when application has active WEB_VIEW template
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) WebEngine App with WEB_VIEW HMI type is registered
--
-- Sequence:
-- 1) App creates a new widget with "duplicateUpdatesFromWindowID" = 0
--  a. SDL sends UI.CreateWindow(params) request to HMI
-- 2) HMI sends valid UI.CreateWindow response to SDL
--  a. SDL sends CreateWindow response with success: true resultCode: "SUCCESS" to App
-- 3) HMI sends OnSystemCapabilityUpdated(params) notification to SDL
--  a. SDL sends OnSystemCapabilityUpdated(params) notification to App
--  b. SDL sends OnHMIStatus (hmiLevel, windowID) notification for widget window to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = { "WEB_VIEW" }
local createWindowParams = {
  windowID = 1,
  windowName = "Name",
  type = "WIDGET",
  duplicateUpdatesFromWindowID = 0
}

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update WS Server Certificate parameters in smartDeviceLink.ini file", common.commentAllCertInIniFile)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT, { appSessionId, appHMIType })
common.Step("Start SDL, HMI", common.startWOdeviceConnect)
common.Step("Connect WebEngine device", common.connectWebEngine, { appSessionId, "WS" })
common.Step("Register App without PTU", common.registerAppWOPTU, { appSessionId })
common.Step("Activate web app", common.activateApp, { appSessionId })

common.Title("Test")
common.Step("App sends CreateWindow RPC with duplicateUpdatesFromWindowID", common.createWindow, { createWindowParams })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
