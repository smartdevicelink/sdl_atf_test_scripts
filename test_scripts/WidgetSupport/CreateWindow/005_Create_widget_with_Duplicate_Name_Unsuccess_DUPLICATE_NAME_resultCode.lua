---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL rejects request with "DUPLICATE_NAME" if app tries to create a widget with
--  name that is already in use (by existing widget for the same app)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered
-- 4) App successfully create a widget
-- Step:
-- 1) App sends CreateWindow request for the second widget with name that is already in use
-- SDL does:
--  - not send UI.CreateWindow(params) request to HMI
--  - send CreateWindow response with success:false, resultCode: "DUPLICATE_NAME" to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  [1] = {
    windowID = 2, windowName = "Name1", type = "WIDGET"
  },
  [2] = {
    windowID = 3, windowName = "Name1", type = "WIDGET"
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App create a widget", common.createWindow, { params[1] })

common.Title("Test")
common.Step("App tries to create a widget with name that is already in use",
  common.createWindowUnsuccess, { params[2], "DUPLICATE_NAME" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
