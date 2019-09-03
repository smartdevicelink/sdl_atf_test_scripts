---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL rejects request with "GENERIC_ERROR" result code if HMI doesn't respond during default timeout
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" and "DeleteWindow" are allowed by policies
-- 3) App is registered and activated
-- 4) App successfully created a widget
-- Steps:
-- 1) App send DeleteWindow(WindowID) request to SDL
-- SDL does:
--  - send request UI.DeleteWindow(WindowID) to HMI
-- 2) HMI doesn't send UI.DeleteWindow response
-- SDL does:
--  - send DeleteWindow response with (success = false, resultCode = GENERIC_ERROR") to App
--  - not send OnSystemCapabilityUpdated notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 3,
  windowName = "Widget",
  type = "WIDGET"
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("Success create Window", common.createWindow, { params })

common.Title("Test")
common.Step("Delete Window HMI without response",  common.deleteWindowHMIwithoutResponse,
  { params.windowID, "GENERIC_ERROR" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
