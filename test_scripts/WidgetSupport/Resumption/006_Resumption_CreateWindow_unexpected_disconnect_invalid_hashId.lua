---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0216-widget-support.md
--
-- Description: Check that SDL restores Main window to FULL level and doesn't restore Widget window
-- in case if App re-registers with wrong hashId after unexpected disconnect
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered and activated (FULL level)
-- 3) App created a widget which is activated (FULL level)
-- Steps:
-- 1) Unexpected disconnect and reconnect are performed
-- 2) App re-register with wrong HashId
-- SDL does:
--  - does not send UI.CreateWindow(params) request to HMI
--  - does not send CreateWindow response to App
-- 3) HMI sends OnSystemCapabilityUpdated(params) notification to SDL for Main window
-- SDL does:
--  - send OnSystemCapabilityUpdated(params) notification to App for Main window
--  - send OnHMIStatus (FULL level) notification for Main window to app
-- 4) App send Show(with WindowID for Main window) request to SDL
-- SDL does:
--  - proceed with request successfully
-- 5) App send Show(with WindowID for Widget window) request to SDL
-- SDL does:
--  - respond to App with (success = false, resultCode = INVALID_ID")
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Test Configuration ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local Variables ]]
local widgetParams = {
  windowID = 2,
  windowName = "Name",
  type = "WIDGET",
  associatedServiceType = "MEDIA"
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

local function checkResumption_FULL()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { windowID = 0, hmiLevel = "NONE" },
    { windowID = 0, hmiLevel = "FULL" })
  :Times(2)
  common.getHMIConnection():ExpectRequest("UI.CreateWindow")
  :Times(0)
  common.expCreateWindowResponse()
  :Times(0)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", common.getOnSCUParams({ 0 }))
end

function common.getHashId()
  return "wrong_hashId"
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("App creates widget", createWindow, { widgetParams })
common.Step("Widget is activated", common.activateWidgetFromNoneToFULL, { widgetParams.windowID })

common.Title("Test")
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App resumption data RESUME_FAILED", common.reRegisterAppSuccess,
  { nil, 1, checkResumption_FULL, "RESUME_FAILED" })
common.Step("Show RPC to Main window", common.sendShowToWindow, { 0 })
common.Step("Show RPC to Widget window", common.sendShowToWindowUnsuccess, { widgetParams.windowID, "INVALID_ID" })

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
