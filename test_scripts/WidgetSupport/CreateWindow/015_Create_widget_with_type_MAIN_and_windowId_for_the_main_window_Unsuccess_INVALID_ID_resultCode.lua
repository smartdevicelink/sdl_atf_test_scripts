---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL rejects request with INVALID_ID if app sends CreateWindow with type MAIN
-- with an ID for the main window
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) CreateWindow is allowed by policies
-- 3) App is registered
-- Step:
-- 1) App sends CreateWindow request with type MAIN and with windowID the main window
-- SDL does:
--  - not send UI.CreateWindow(params) request to HMI
--  - send CreateWindow response with success: false, resultCode: INVALID_ID to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 0,
  windowName = "Name of the widget",
  type = "MAIN"
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)

common.Title("Test")
common.Step("App creates a widget with type MAIN and with windowID for the main window",
  common.createWindowUnsuccess, { params, "INVALID_ID" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
