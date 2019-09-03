---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL sends 2 "OnHMIStatus" notifications to app ("BACKGROUND", "FULL") in case
--  widget is selected from available ones on HMI
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- 4) App creates a widget and it has NONE level
-- Step:
-- 1) HMI sends two BC.OnAppActivated notifications with the widget's window ID to SDL during
--    activation a widget from NONE level to FULL
-- SDL does:
--  - send two OnHMIStatus notifications for widget window to app:
--    the first OnHMIStatus (hmiLevel: BACKGROUND, windowID)
--    the second OnHMIStatus (hmiLevel: FULL, windowID)
--  - not send OnHMIStatus notifications for main window to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 2,
  windowName = "Name",
  type = "WIDGET"
}

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("App create a widget", common.createWindow, { params })

common.Title("Test")
common.Step("Widget is activated in the HMI", common.activateWidgetFromNoneToFULL, { params.windowID })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
