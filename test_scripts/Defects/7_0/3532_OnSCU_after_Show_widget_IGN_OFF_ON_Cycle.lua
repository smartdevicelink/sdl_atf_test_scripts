---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3532
--
-- Description: Check that SDL transfers `OnSystemCapabilitiesUpdated` notification from HMI to an App
-- in next ignition cycle in case App sent Show RPC with templateConfiguration parameter for widget window
-- after Show response
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered and activated (FULL level)
-- 3) App successfully created a widget
-- 4) Widget is activated on the HMI and has FULL level
-- 5) IGN_OFF/IGN_ON cycle is performed
-- 6) App is re-registered with actual HashId
-- 7) Widget is activated on the HMI and has FULL level
-- Steps:
-- 1) App sends `Show` request with `templateConfiguration` for widget window
-- SDL does:
--  - proceed with `Show` request successfully
--  - not send `OnSystemCapabilityUpdated` to App
-- 2) HMI sends `OnSystemCapabilityUpdated` to SDL
-- SDL does:
--  - transfer `OnSystemCapabilityUpdated` notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WidgetSupport/common')

--[[ Local Variables ]]
local appSessionId = 1
local createWindowParams = {
  windowID = 1,
  windowName = "Name",
  type = "WIDGET"
}

--[[ Local Functions ]]
local function sendShow()
  local showParams = {
    mainField1 = "MainField1",
    windowID = createWindowParams.windowID,
    templateConfiguration = {
      template = "Template1"
    }
  }
  local cid = common.getMobileSession():SendRPC("Show", showParams)
  common.getHMIConnection():ExpectRequest("UI.Show")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated")
  :Times(0)
end

local function sendOnSCU()
  local paramsToSDL = common.getOnSystemCapabilityParams()
  paramsToSDL.appID = common.getHMIAppId()
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", paramsToSDL)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", common.getOnSystemCapabilityParams())
end

local function createWindow(pParams)
  common.getMobileSession(appSessionId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.setHashId(data.payload.hashID, appSessionId)
    end)
  common.createWindow(pParams, appSessionId)
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("Create widget", createWindow, { createWindowParams })
common.Step("Activate widget", common.activateWidgetFromNoneToFULL, { createWindowParams.windowID })
common.Step("Ignition_off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Re-register App resumption data", common.reRegisterAppSuccess,
  { createWindowParams, appSessionId, common.checkResumption_FULL })
common.Step("Widget is activated after restore", common.activateWidgetFromNoneToFULL, { createWindowParams.windowID })

common.Title("Test")
common.Step("App sends Show RPC no OnSCU notification", sendShow)
common.Step("HMI sends OnSCU notification", sendOnSCU)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
