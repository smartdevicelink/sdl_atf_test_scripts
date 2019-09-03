---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check SDL rejects request with "INVALID_ID" result code if app tries to send Show RPC to Widget window
-- with not exist WindowID ("templateConfiguration" param is not defined)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered and activated
-- 3) App successfully created a widget
-- 4) Widget is activated on the HMI and has FULL level
-- Steps:
-- 1) App send Show with Not exist WindowID to SDL
-- SDL does:
--  - send Show response with (success = false, resultCode = INVALID_ID") to App
--  - not send request UI.Show to HMI
--  - not send OnSystemCapabilityUpdated notification to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 2,
  windowName = "Widget",
  type = "WIDGET"
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("Success create Widget window", common.createWindow, { params })
common.Step("Widget is activated", common.activateWidgetFromNoneToFULL, { params.windowID})

common.Title("Test")
common.Step("Show RPC to Widget with Not exist WindowID", common.sendShowToWindowUnsuccess, { 10, "INVALID_ID" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
