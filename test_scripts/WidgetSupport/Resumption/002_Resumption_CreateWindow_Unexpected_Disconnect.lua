---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL restored Widget window to NONE level after unexpected disconnect
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) "CreateWindow" is allowed by policies
-- 3) App is registered and activated (FULL level)
-- 4) App successfully created a widget
-- 5) Widget is activated on the HMI and has FULL level
-- 6) Widget is moved to BACKGROUND
-- Steps:
-- 1) Unexpected disconnect and reconnect are performed
-- 2) App re-register with actual HashId
-- SDL does:
--  - send UI.CreateWindow(params) request to HMI
-- 3) HMI sends valid UI.CreateWindow response to SDL
-- SDL does:
--  - does not send CreateWindow response to app
-- 4) HMI sends OnSystemCapabilityUpdated(params) notification to SDL for Main and Widget windows
-- SDL does:
--  - send single OnSystemCapabilityUpdated(params) notification to app with info for Main and Widget windows
--  - send OnHMIStatus (FULL level) notification for Main window to app
--  - send OnHMIStatus (NONE level) notification for Widget window to app
-- 5) Widget is activated on the HMI and has FULL level
-- 6) App send Show(with WindowID for Widget window) request to SDL
-- SDL does:
--  - send request UI.Show(with WindowID for Widget window) to HMI
-- 7) HMI sends UI.Show response "SUCCESS"
-- SDL does:
--  - send Show response with (success: true resultCode: "SUCCESS") to App
--  - not send OnSystemCapabilityUpdated notification to app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local Variables ]]
local widgetParams = {
  windowID = 4,
  windowName = "Name",
  type = "WIDGET",
  associatedServiceType = "MEDIA"
}

--[[ Local Function ]]
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
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("App sends CreateWindow RPC", createWindow, { widgetParams })
common.Step("Widget is activated", common.activateWidgetFromNoneToFULL, { widgetParams.windowID })
common.Step("Widget to Background", common.deactivateWidgetFromFullToBackground, { widgetParams.windowID })

common.Title("Test")
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App resumption data", common.reRegisterAppSuccess,
  { widgetParams, 1, common.checkResumption_FULL })
common.Step("Widget is activated after restore", common.activateWidgetFromNoneToFULL, { widgetParams.windowID })
common.Step("Show RPC to Widget window",  common.sendShowToWindow, { widgetParams.windowID })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
