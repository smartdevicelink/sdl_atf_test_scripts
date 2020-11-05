---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3532
--
-- Description: Check that SDL transfers `OnSystemCapabilitiesUpdated` notification from HMI to an App
-- in next ignition cycle in case App sent Show RPC with templateConfiguration parameter for main window
-- after `Show` response
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) App is registered and activated (FULL level)
-- 3) IGN_OFF/IGN_ON cycle is performed
-- 4) App is re-registered with actual HashId
-- Steps:
-- 1) App sends `Show` request with `templateConfiguration` for main window (windowID is not defined)
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
local widgetParams = nil

--[[ Local Functions ]]
local function sendShow()
  local showParams = {
    mainField1 = "MainField1",
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
  local paramsToSDL = common.getOnSCUParams({ 0 })
  paramsToSDL.appID = common.getHMIAppId()
  common.getHMIConnection():SendNotification("BasicCommunication.OnSystemCapabilityUpdated", paramsToSDL)
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated",  common.getOnSCUParams({ 0 }))
end

local function checkResumption()
  local winCaps = common.getOnSCUParams({ 0 })
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated", winCaps)
  common.getHMIConnection():ExpectRequest("UI.CreateWindow")
  :Times(0)
  common.expCreateWindowResponse()
  :Times(0)
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
  checkResumption()
end

--[[ Scenario ]]
common.Title("Precondition")
common.Step("Clean environment and Back-up/update PPT", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)
common.Step("Ignition off", common.ignitionOff)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Re-register App resumption data", common.reRegisterAppSuccess,
  { widgetParams, appSessionId, checkResumption_FULL })

common.Title("Test")
common.Step("App sends Show RPC no OnSCU notification", sendShow)
common.Step("HMI sends OnSCU notification", sendOnSCU)

common.Title("Postconditions")
common.Step("Stop SDL, restore SDL settings and PPT", common.postcondition)
