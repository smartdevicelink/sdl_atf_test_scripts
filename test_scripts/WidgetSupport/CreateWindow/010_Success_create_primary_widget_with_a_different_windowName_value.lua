---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL ignores value of windowName for primary widget
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- Step:
-- 1) App creates a primary widget with type: "WIDGET" and different value of windowName via new RPC "CreateWindow"
-- SDL does:
--  - send UI.CreateWindow(params) request to HMI
-- 2) HMI sends valid UI.CreateWindow response to SDL
-- SDL does:
--  - send CreateWindow response with success: true resultCode: "SUCCESS" to app
-- 3) HMI sends OnSystemCapabilityUpdated(params) notification to SDL
-- SDL does:
--  - send OnSystemCapabilityUpdated(params) notification to app
--  - send OnHMIStatus (hmiLevel, windowID) notification for widget window to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 1,
  windowName = "Name of the primary widget",
  type = "WIDGET"
}

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("App creation a primary widget", common.createWindow, { params })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
