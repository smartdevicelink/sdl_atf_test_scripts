---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check "OnHMIStatus" notifications for 1 app in case of changes of widget's level
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered
-- 4) App creates 2 widgets
-- 5) Both widgets are activated on the HMI and has FULL level
-- Step:
-- 1) 1st widget became invisible on HMI (FULL->BACKGROUND)
-- SDL does:
--  - send one OnHMIStatus notification for 1st widget window to app
--  - not send OnHMIStatus notifications for the main and 2nd widget windows to app
-- 2) 2nd widget removed from a list on HMI (FULL->NONE)
-- SDL does:
--  - send two OnHMIStatus notifications for the 2nd widget window to app
--  - not send OnHMIStatus notifications for the main and 1st widget windows to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  [1] = {
    windowID = 1, windowName = "Name1", type = "WIDGET"
  },
  [2] = {
    windowID = 2, windowName = "Name2", type = "WIDGET"
  }
}

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App create the 1st widget", common.createWindow, { params[1] })
common.Step("App create the 2nd widget", common.createWindow, { params[2] })
common.Step("1st widget is activated in the HMI", common.activateWidgetFromNoneToFULL, { params[1].windowID })
common.Step("2nd widget is activated in the HMI", common.activateWidgetFromNoneToFULL, { params[2].windowID })

common.Title("Test")
common.Step("1st widget is deactivated from FULL to BACKGROUND",
  common.deactivateWidgetFromFullToBackground, { params[1].windowID })
common.Step("2nd widget is deactivated from FULL to NONE",
  common.deactivateWidgetFromFullToNone, { params[2].windowID })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
