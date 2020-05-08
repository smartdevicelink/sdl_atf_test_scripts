---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check app is able to successfully create a primary widget (windowID:1) with type: WIDGET
-- and name as appName via new RPC CreateWindow
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated
-- Step:
-- 1) App creates a primary widget with type: "WIDGET" and windowName as appName via new RPC "CreateWindow"
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
  windowName = config.application1.registerAppInterfaceParams.appName,
  type = "WIDGET"
}

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("App creates a primary widget", common.createWindow, { params })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
