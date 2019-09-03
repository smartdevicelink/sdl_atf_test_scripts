---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check there is no dependency between Main and Widget windows
-- in case of setting `templateConfiguration` (Widget-Main)
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) App is registered and activated
-- 3) App successfully created a widget
-- 4) Widget is activated on the HMI and has FULL level
-- Steps:
-- 1) App sends Show request with `templateConfiguration` param to Widget window
-- SDL does:
--  - proceed with request successfully
-- 2) App sends Show request with the same template and different colors
--    in `templateConfiguration` param to Main window
-- SDL does:
--  - proceed with request successfully (such request for Widget window will be rejected)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local widgetParams = {
  windowID = 3,
  windowName = "Widget",
  type = "WIDGET"
}

--[[ Local Functions ]]
local function setShowParams(pId)
  local templateConfig = {
    template = "Template",
    dayColorScheme = {
      primaryColor = { red = pId, green = 255, blue = 100 }
    }
  }
  function common.getShowParams()
    return {
      requestShowParams = {
        templateConfiguration = templateConfig
      },
      requestShowUiParams = {
        templateConfiguration = templateConfig
      }
    }
  end
end

local function sendShowToWindow(pId, pWindowId)
  setShowParams(pId)
  common.sendShowToWindow(pWindowId)
end

local function sendShowToWindowUnsuccess(pId, pWindowId, pResultCode)
  setShowParams(pId)
  common.sendShowToWindowUnsuccess(pWindowId, pResultCode)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("Success create Widget window", common.createWindow, { widgetParams })
common.Step("Widget is activated", common.activateWidgetFromNoneToFULL, { widgetParams.windowID, 1 })

common.Title("Test")
common.Step("Show RPC to Widget window SUCCESS", sendShowToWindow, { 2, widgetParams.windowID })
common.Step("Show RPC to Main window SUCCESS", sendShowToWindow, { 1, 0 })
common.Step("Show RPC to Widget window REJECTED", sendShowToWindowUnsuccess, { 1, widgetParams.windowID, "REJECTED" })
common.Step("Show RPC to Main window REJECTED", sendShowToWindowUnsuccess, { 2, 0, "REJECTED" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
