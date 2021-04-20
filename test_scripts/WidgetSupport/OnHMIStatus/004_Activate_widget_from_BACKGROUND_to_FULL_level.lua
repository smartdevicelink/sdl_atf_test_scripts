---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL sends "OnHMIStatus" ("FULL", widget_window_id) to app in case widget
--  is activated on HMI (from "BACKGROUND" to "FULL")
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- 4) Widget is created and activated on the HMI
-- 5) Widget is deactivated in the HMI and it has BACKGROUND level
-- Step:
-- 1) HMI sends BC.OnAppActivated notification with the widget's window ID to SDL during
--    activation a widget from BACKGROUND level to FULL
-- SDL does:
--  - send one OnHMIStatus notification for widget window to app:
--    OnHMIStatus (hmiLevel: "FULL", windowID)
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
common.Step("Widget is deactivated in the HMI", common.deactivateWidgetFromFullToBackground, { params.windowID })

common.Title("Test")
common.Step("Widget is activated in the HMI", common.activateWidgetFromBackgroundToFULL, { params.windowID })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
