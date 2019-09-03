---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check app is able to successfully create Primary widget with
-- "duplicateUpdatesFromWindowID" parameter and send Show RPC to Main window
--  ("templateConfiguration" param is not defined)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered and activated
-- 3) App successfully created a widget with "duplicateUpdatesFromWindowID" parameter for Main window
-- 4) Widget is activated on the HMI and has FULL level
-- Steps:
-- 1) App sends Show(without WindowID) request to SDL
-- SDL does:
--  - send request UI.Show(Main window) to HMI
--  - not send request UI.Show(Widget window) to HMI
-- 2) HMI sends UI.Show response "SUCCESS"
-- SDL does:
--  - send Show response with (success: true resultCode: "SUCCESS") to App
--  - not send OnSystemCapabilityUpdated notification to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  [1] = {
    windowID = 1,
    windowName = config.application1.registerAppInterfaceParams.appName,
    type = "WIDGET",
    duplicateUpdatesFromWindowID = 0
  },
  [2] = {
    windowID = 2,
    windowName = "Name2",
    type = "WIDGET",
    duplicateUpdatesFromWindowID = 0
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("Success create first widget with duplicate ID", common.createWindow, { params[1] })
common.Step("Success create second widget with duplicate ID", common.createWindow, { params[2] })
common.Step("First widget is activated", common.activateWidgetFromNoneToFULL, { params[1].windowID})
common.Step("Second widget is activated", common.activateWidgetFromNoneToFULL, { params[2].windowID})

common.Title("Test")
common.Step("Success Show RPC to Main window", common.sendShowToWindow, { nil })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
