---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that is able to successfully create more than one widget via new RPC CreateWindow with type WIDGET
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) CreateWindow is allowed by policies
-- 3) App is registered
-- Step:
-- 1) App sends five CreateWindow requests one by one to SDL
-- SDL does:
--  - send one by one UI.CreateWindow(params) requests to HMI
-- 2) HMI sends one by one valid UI.CreateWindow responses to SDL
-- SDL does:
--  - send one by one CreateWindow responses with success: true resultCode: SUCCESS to app
-- 3) HMI sends one by one OnSystemCapabilityUpdated(params) notifications to SDL after each created widgets
-- SDL does:
--  - send OnSystemCapabilityUpdated(params) notifications to app for each widgets
--  - send OnHMIStatus (hmiLevel, windowID) notifications to app for each widgets
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local params = {
  first = {
    windowID = 1, windowName = "Name1", type = "WIDGET"
  },
  second = {
    windowID = 2, windowName = "Name2", type = "WIDGET"
  },
  third = {
    windowID = 3, windowName = "Name3", type = "WIDGET"
  },
  fourth = {
    windowID = 4, windowName = "Name4", type = "WIDGET"
  },
  fifth = {
    windowID = 5, windowName = "Name5", type = "WIDGET"
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)

common.Title("Test")
for k, v in pairs(params) do
  common.Step("App creates the " .. k .. " widget", common.createWindow, { v })
end

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
