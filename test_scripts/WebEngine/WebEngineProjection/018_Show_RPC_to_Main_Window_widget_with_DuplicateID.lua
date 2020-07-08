---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description: Processing of RPCs for widget which duplicates main window ( "duplicateUpdatesFromWindowID" = 0 )
--  when application has active WEB_VIEW template
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) WebEngine App with WEB_VIEW HMI type is registered
-- 3) App successfully created a first primary widget with "duplicateUpdatesFromWindowID" parameter for Main window
-- 4) App successfully created a second widget with "duplicateUpdatesFromWindowID" parameter for Main window
-- 5) First primary widget is activated on the HMI and has FULL level
-- 6) Second widget is activated on the HMI and has FULL level
--
-- Sequence:
-- 1) App sends Show(without WindowID) request to SDL
--  a. SDL sends request UI.Show(Main window) to HMI
--  b. SDL does not send request UI.Show(Widget window) to HMI
-- 2) HMI sends UI.Show response "SUCCESS"
--  a. SDL sends Show response with (success: true resultCode: "SUCCESS") to App
--  b. SDL does not send OnSystemCapabilityUpdated notification to App
---------------------------------------------------------------------------------------------------
--[[ General test configuration ]]
config.defaultMobileAdapterType = "WS"

--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = { "WEB_VIEW" }
local createWindowsParams = {
  [1] = {
    windowID = 1,
    windowName = config.application1.registerAppInterfaceParams.appName,
    type = "WIDGET",
    duplicateUpdatesFromWindowID = 0
  },
  [2] = {
    windowID = 2,
    windowName = "Name2",
    type = "WIDGET",
    duplicateUpdatesFromWindowID = 0
  }
}

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update WS Server Certificate parameters in smartDeviceLink.ini file", common.commentAllCertInIniFile)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT, { appSessionId, appHMIType })
common.Step("Start SDL, HMI, connect WebEngine device", common.start)
common.Step("Register App without PTU", common.registerAppWOPTU, { appSessionId })
common.Step("Activate web app", common.activateApp, { appSessionId })
common.Step("Success create first widget with duplicate ID", common.createWindow, { createWindowsParams[1] })
common.Step("Success create second widget with duplicate ID", common.createWindow, { createWindowsParams[2] })
common.Step("First widget is activated", common.activateWidgetFromNoneToFULL, { createWindowsParams[1].windowID })
common.Step("Second widget is activated", common.activateWidgetFromNoneToFULL, { createWindowsParams[2].windowID })

common.Title("Test")
common.Step("Success Show RPC to Main window", common.sendShowToWindow, { nil })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
