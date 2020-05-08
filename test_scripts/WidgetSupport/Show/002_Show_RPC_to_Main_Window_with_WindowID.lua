---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check app is able to successfully send Show RPC to Main window with WindowID
--  ("templateConfiguration" param is not defined)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered and activated
-- 3) App successfully created a widget
-- 4) Widget is activated on the HMI and has FULL level
-- Steps:
-- 1) App send Show(with WindowID for Main window) request to SDL
-- SDL does:
--  - send request UI.Show(with WindowID for Main window) to HMI
-- 2) HMI sends UI.Show response "SUCCESS"
-- SDL does:
--  - send Show response with (success: true resultCode: "SUCCESS") to App
--  - not send OnSystemCapabilityUpdated notification to app
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
common.Step("Success create Widget window", common.createWindow, { params })
common.Step("Widget is activated", common.activateWidgetFromNoneToFULL, { params.windowID, 1 })

common.Title("Test")
common.Step("Success Show RPC to Main window with windowID", common.sendShowToWindow, { 0 })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
