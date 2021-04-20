---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check "OnHMIStatus" notifications for 2 apps in case of changes of widget's level
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) Two apps are registered (app1 and app2)
-- 4) Each app creates a widget
-- 5) Both Widgets are activated on the HMI and has FULL level
-- Step:
-- 1) 1st app widget became invisible on HMI (FULL->BACKGROUND)
-- SDL does:
--  - send one OnHMIStatus notification for widget window to App1
--  - not send OnHMIStatus notification for main window to App1
--  - not send OnHMIStatus notification for main and widget windows to App2
-- 2) 2nd app widget removed from a list on HMI (FULL->NONE)
-- SDL does:
--  - send two OnHMIStatus notifications for widget window to App2
--  - not send OnHMIStatus notification for main window to App2
--  - not send OnHMIStatus notification for main and widget windows to App1
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  [1] = {
    windowID = 2, windowName = "Name1", type = "WIDGET"
  },
  [2] = {
    windowID = 3, windowName = "Name2", type = "WIDGET"
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("App1 registration", common.registerAppWOPTU, { 1 })
common.Step("App2 registration", common.registerAppWOPTU, { 2 })
common.Step("App1 create a widget", common.createWindow, { params[1], 1 })
common.Step("App2 create a widget", common.createWindow, { params[2], 2 })
common.Step("Widget is activated in the HMI from App1", common.activateWidgetFromNoneToFULL, { params[1].windowID, 1 })
common.Step("Widget is activated in the HMI from App2", common.activateWidgetFromNoneToFULL, { params[2].windowID, 2 })

common.Title("Test")
common.Step("Widget from App1 changes level FULL->BACKGROUND",
  common.deactivateWidgetFromFullToBackground, { params[1].windowID, 1 })
common.Step("Widget from App1 changes level FULL->NONE",
  common.deactivateWidgetFromFullToNone, { params[2].windowID, 2 })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
