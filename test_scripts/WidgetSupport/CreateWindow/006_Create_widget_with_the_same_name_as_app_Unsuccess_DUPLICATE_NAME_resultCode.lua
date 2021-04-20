---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL rejects request with "DUPLICATE_NAME" if app tries to create a widget
--  with the same name as app (existing or any other app registered)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered
-- Step:
-- 1) App sends CreateWindow request for a widget with the same name as the app
-- SDL does:
--  - not send UI.CreateWindow(params) request to HMI
--  - send CreateWindow response with success:false, resultCode: "DUPLICATE_NAME" to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 2,
  windowName = config.application1.registerAppInterfaceParams.appName,
  type = "WIDGET"
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)

common.Title("Test")
common.Step("App tries to create a widget with the same name as app",
  common.createWindowUnsuccess, { params, "DUPLICATE_NAME" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
