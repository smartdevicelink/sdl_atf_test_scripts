---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL rejects request with "INVALID_DATA" result code if app tries to create Widget
-- window with "duplicateUpdatesFromWindowID" for non-exist WindowID in request
--  ("templateConfiguration" param is not defined)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- 4) App successfully created a widget with "duplicateUpdatesFromWindowID" parameter
-- Steps:
-- 1) App sends CreateWindow request with "duplicateUpdatesFromWindowID" for non-exist WindowID
-- to SDL
-- SDL does:
--  - send CreatedWindow response with (success = false, resultCode = "INVALID_DATA") to App
--  - not send UI.CreateWindow(params) request to HMI
--  - not send OnSystemCapabilityUpdated notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 2,
  windowName = "Widget_2",
  type = "WIDGET",
  duplicateUpdatesFromWindowID = 0
}

local notExistWindowIDParams = {
  windowID = 3,
  windowName = "Widget_3",
  type = "WIDGET",
  duplicateUpdatesFromWindowID = 10
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("Success create not Primary widget with DuplicateID", common.createWindow, { params })

common.Title("Test")
common.Step("App sends CreateWindow request with duplicate ID for non-exist window",
  common.createWindowUnsuccess, { notExistWindowIDParams, "INVALID_DATA" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
