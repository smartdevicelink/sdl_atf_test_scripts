---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL transfer "REJECTED" Show response from HMI to app
-- if app has sent Show RPC to Widget window with "duplicateUpdatesFromWindowID" parameter defined
--  ("templateConfiguration" param is not defined)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered and activated
-- 3) App successfully created a widget with "duplicateUpdatesFromWindowID" parameter for Main window
-- 4) Widget is activated on the HMI and has FULL level
-- Steps:
-- 1) App sends Show(with WindowID for Widget window) requests to SDL
-- SDL does:
--  - transfer request to HMI
-- 2) HMI responds with "REJECTED" code
-- SDL does:
--  - transfer response (success = false, resultCode = "REJECTED") to App
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
    windowName = "Widget",
    type = "WIDGET",
    duplicateUpdatesFromWindowID = 0
  }
}

function common.getShowParams()
  local templateConfiguration = {
    template = "Template2",
    dayColorScheme = {
      primaryColor = {
        red = 11,
        green = 11,
        blue = 11
      }
    }
  }
  return { requestShowParams = {
      templateConfiguration = templateConfiguration
    },
    requestShowUiParams = {
      templateConfiguration = templateConfiguration
    }
  }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("Success create First widget", common.createWindow, { params[1] })
common.Step("Success create Second widget", common.createWindow, { params[2] })
common.Step("First Widget is activated", common.activateWidgetFromNoneToFULL, { params[1].windowID})
common.Step("Second Widget is activated", common.activateWidgetFromNoneToFULL, { params[2].windowID})
common.Step("Success Show RPC to Main window", common.sendShowToWindow, { 0 })

common.Title("Test")
common.Step("Show RPC to First Widget with duplicate ID", common.sendShowToWindowUnsuccessHMIREJECTED,
  { params[1].windowID })
common.Step("Show RPC to Second Widget with duplicate ID", common.sendShowToWindowUnsuccessHMIREJECTED,
  { params[2].windowID })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
