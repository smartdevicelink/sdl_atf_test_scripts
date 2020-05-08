---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL restored Widget window to NONE level after unexpected disconnect
-- in case of 2 applications
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App_1, App_2 are registered and activated
-- 3) App_1 and App_2 successfully created widgets
-- 4) Widgets are activated on the HMI and have FULL level
-- Steps:
-- 1) Unexpected disconnect and reconnect are performed
-- 2) Each app re-registers with actual HashId
-- SDL does:
--  - send UI.CreateWindow(params) request to HMI
-- 3) HMI sends valid UI.CreateWindow response to SDL
-- SDL does:
--  - not send CreateWindow response to Apps
--  - restore HMI level of 1st app to LIMITED
--  - not restore HMI level of 2nd app to FULL (since there is an app in LIMITED)
--  - transfer OnSystemCapabilityUpdated notification from HMI to each app
-- 4) Widgets for App_1 and App_2 are activated on the HMI and has FULL level
-- 5) App_1 and App_2 send Show(with WindowID for Widget window) request to SDL
-- SDL does:
--  - proceed with request as normal (SUCCESS or not depending on HMI response)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }

--[[ Local Variables ]]
local widgetParamsApp_1 = {
  windowID = 2,
  windowName = "Widget App1",
  type = "WIDGET",
  associatedServiceType = "MEDIA"
}

local widgetParamsApp_2 = {
  windowID = 3,
  windowName = "Widget App2",
  type = "WIDGET",
  associatedServiceType = "NAVIGATION",
  duplicateUpdatesFromWindowID = 0
}

--[[ Local Functions ]]
local function createWindow(pParams, pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.setHashId(data.payload.hashID, pAppId)
    end)
  common.createWindow(pParams, pAppId)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App_1 registration", common.registerAppWOPTU, { 1 })
common.Step("App_2 registration", common.registerAppWOPTU, { 2 })
common.Step("App_1 activation", common.activateApp, { 1 })
common.Step("App_1 sends CreateWindow RPC", createWindow, { widgetParamsApp_1, 1 })
common.Step("Widget for App_1 is activated", common.activateWidgetFromNoneToFULL, { widgetParamsApp_1.windowID, 1 })
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("App_2 sends CreateWindow RPC", createWindow, { widgetParamsApp_2, 2 })
common.Step("Widget for App_2 is activated", common.activateWidgetFromNoneToFULL, { widgetParamsApp_2.windowID, 2 })

common.Title("Test")
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App_1 resumption data", common.reRegisterAppSuccess,
  { widgetParamsApp_1, 1,  common.checkResumption_LIMITED })
common.Step("Re-register App_2 resumption data", common.reRegisterAppSuccess,
  { widgetParamsApp_2, 2, common.checkResumption_NONE })
common.Step("Widget for App_1 is activated after restore",
  common.activateWidgetFromNoneToFULL, { widgetParamsApp_1.windowID, 1 })
common.Step("Show RPC to Widget window for App_1",
  common.sendShowToWindow, { widgetParamsApp_1.windowID, 1 })
common.Step("Widget for App_2 is activated after restore",
  common.activateWidgetFromNoneToFULL, { widgetParamsApp_2.windowID, 2 })
common.Step("Show RPC to Widget window for App_2 with duplicate ID unsuccess",
  common.sendShowToWindowUnsuccessHMIREJECTED, { widgetParamsApp_2.windowID, 2 })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
