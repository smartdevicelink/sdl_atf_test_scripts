---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description: Check that SDL transfers `OnSystemCapabilitiesUpdated` notification from HMI to the WEB_VIEW App
-- if App sent `Show` RPC with `templateConfiguration` parameter for widget window
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) WebEngine App with WEB_VIEW HMI type is registered
-- 3) App creates new widget
--
-- Sequence:
-- 1) App sends `Show` request with `templateConfiguration` for widget window
--  a. SDL proceeds with `Show` request successfully
--  b. SDL does not send `OnSystemCapabilityUpdated` to App
-- 2) HMI sends `OnSystemCapabilityUpdated` to SDL
--  a. SDL transfers `OnSystemCapabilityUpdated` notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local createWindowParams = {
  windowID = 1,
  windowName = "Name",
  type = "WIDGET"
}

local showParams = {
  mainField1 = "MainField1",
  windowID = createWindowParams.windowID,
  templateConfiguration = {
    template = "Template1"
  }
}

local appSessionId = 1
local appHMIType = { "WEB_VIEW" }

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType

--[[ Local Functions ]]
local function sendShow()
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

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update WS Server Certificate parameters in smartDeviceLink.ini file", common.commentAllCertInIniFile)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT, { appSessionId, appHMIType })
common.Step("Start SDL, HMI", common.startWOdeviceConnect)
common.Step("Connect WebEngine device", common.connectWebEngine, { appSessionId, "WS" })
common.Step("Register App without PTU", common.registerAppWOPTU, { appSessionId })
common.Step("Activate web app", common.activateApp, { appSessionId })
common.Step("Create widget", common.createWindow, { createWindowParams })
common.Step("Activate widget", common.activateWidgetFromNoneToFULL, { createWindowParams.windowID })

common.Title("Test")
common.Step("App sends Show RPC no OnSystemCapabilitiesUpdated notification", sendShow)
common.Step("HMI sends OnSystemCapabilitiesUpdated notification", sendOnSCU)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
