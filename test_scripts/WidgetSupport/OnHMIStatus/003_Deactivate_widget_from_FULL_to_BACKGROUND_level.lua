---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL sends "OnHMIStatus" ("BACKGROUND", widget_window_id) to app in case widget
--  is deactivated on HMI (from "FULL" to "BACKGROUND")
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- 4) App creates a widget
-- 5) Widget is activated on the HMI and it has FULL level
-- Step:
-- 1) HMI sends one BC.OnAppDeactivated notifications with the widget's window ID to SDL during
--    deactivation a widget from FULL level to BACKGROUND
-- SDL does:
--  - send one OnHMIStatus notification for widget window to app:
--    the first OnHMIStatus (hmiLevel: BACKGROUND, windowID)
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
common.Step("Widget is activated in the HMI", common.activateWidgetFromNoneToFULL, { params.windowID })

common.Title("Test")
common.Step("Widget is deactivated in the HMI", common.deactivateWidgetFromFullToBackground, { params.windowID })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
