---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check different apps be able to successfully create widgets with the same name
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) Two Apps are registered
-- 4) App1 successfully create a primary widget with type: "WIDGET" and windowName as the name App1
-- Steps:
-- 1) App2 creates a primary widget with type: "WIDGET" and windowName as the name App2
-- SDL does:
--  - send UI.CreateWindow(params) request to HMI
-- 2) HMI sends valid UI.CreateWindow response to SDL
-- SDL does:
--  - send CreateWindow response with success: true resultCode: "SUCCESS" to App2
-- 3) HMI sends OnSystemCapabilityUpdated(params) notification to SDL
-- SDL does:
--  - send OnSystemCapabilityUpdated(params) notification to App2
--  - send OnHMIStatus (hmiLevel, windowID) notification for widget window to App2
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
    windowName = config.application2.registerAppInterfaceParams.appName,
    type = "WIDGET"
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App1 registration", common.registerAppWOPTU, { 1 })
common.Step("App2 registration", common.registerAppWOPTU, { 2 })
common.Step("App1 creates a primary widget", common.createWindow, { params[1], 1 })

common.Title("Test")
common.Step("App2 creates a primary widget with the same name as the App2", common.createWindow, { params[2], 2 })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
