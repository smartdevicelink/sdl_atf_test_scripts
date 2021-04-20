---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL rejects request "INVALID_ID" CreateWindow if app tries create the second a primary widget
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- 4) App creates a primary widget
-- Step:
-- 1) App sends CreateWindow request for the second a primary widget
-- SDL does:
--  - not send UI.CreateWindow(params) request to HMI
--  - send CreateWindow response with success:false, resultCode: "INVALID_ID" to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  [1] = {
    windowID = 1,
    windowName = config.application1.registerAppInterfaceParams.appName,
    type = "WIDGET"
  },
  [2] = {
    windowID = 1,
    windowName = "Name of the second primary widget",
    type = "WIDGET"
  }
}

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("App creates a primary widget", common.createWindow, { params[1] })

common.Title("Test")
common.Step("App creates the second primary widget",
  common.createWindowUnsuccess, { params[2], "INVALID_ID" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
