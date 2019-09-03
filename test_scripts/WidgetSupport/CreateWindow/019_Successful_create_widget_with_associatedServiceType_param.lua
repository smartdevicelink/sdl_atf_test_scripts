---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL successfully processed with CreateWindow request with associatedServiceType param
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) CreateWindow is allowed by policies
-- 3) App is registered and activated
-- Step:
-- 1) App creates a widget with associatedServiceType parameter via new RPC CreateWindow
-- SDL does:
--  - send UI.CreateWindow(params) request to HMI
-- 2) HMI sends valid UI.CreateWindow response to SDL
-- SDL does:
--  - send CreateWindow response with success: true resultCode: "SUCCESS" to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  windowID = 2,
  windowName = "Name",
  type = "WIDGET",
  associatedServiceType = "MEDIA"
}

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("App sends CreateWindow RPC", common.createWindow, { params })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
