---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check app is able to successfully delete a widget and primary widget windows via new RPC "DeleteWindow"
--
-- Precondition:
-- 1) SDL and HMI are started
-- 2) CreateWindow and DeleteWindow are allowed by policies
-- 3) App is registered and activated
-- 4) App successfully created a primary and not primary widget
-- Steps:
-- 1) App sends DeleteWindow requests for a primary and not primary widgets to SDL
-- SDL does:
--  - send requests UI.DeleteWindow for both widgets to HMI
-- 2) HMI sends UI.DeleteWindow responses "SUCCESS" to SDL
-- SDL does:
--  - send DeleteWindow responses with (success: true resultCode: "SUCCESS") for both widgets to App
--  - not send OnSystemCapabilityUpdated notifications to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local primaryParams = {
  windowID = 1,
  windowName = config.application1.registerAppInterfaceParams.appName,
  type = "WIDGET"
}

local notPrimaryParams = {
  windowID = 2,
  windowName = "Not_Primary_Widget",
  type = "WIDGET"
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, init HMI", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("Activate App", common.activateApp)
common.Step("Success create primary Window", common.createWindow, { primaryParams })
common.Step("Success create not primary Window", common.createWindow, { notPrimaryParams })

common.Title("Test")
common.Step("Success delete primary Window", common.deleteWindow, { primaryParams.windowID })
common.Step("Success delete not primary Window", common.deleteWindow, { notPrimaryParams.windowID })


common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
