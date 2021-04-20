---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that SDL doesn't close the connection with WebEngine
-- projection app if the app was closed (HMILevel NONE is assigned)
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
--
-- Sequence:
-- 1. Application registers with WEB_VIEW appHMIType
--  a. SDL successfully registers application (resultCode SUCCESS, success:"true")
--  b. SDL assigns HMILevel (NONE) to the WebEngine projection app and doesn't close the WebSocket connection
-- 2. Activate web application
--  a. WebEngine projection application successfully activated using remained connection to SDL
-- 3. Deactivate web application to NONE and check connection
--  a. Exit from application (reason = "USER_EXIT")
-- 4. Activate web application (Check WebSocket connection)
--  a. WebEngine projection application successfully activated using remained connection to SDL
---------------------------------------------------------------------------------------------------
-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = { "WEB_VIEW" }

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType

--[[ Local Functions ]]
local function deactivateAppToNoneAndCheckConnection()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
    { appID = common.getHMIAppId(), reason = "USER_EXIT" })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  common.getMobileSession():ExpectEvent(common.disconnectedEvent, "Disconnected")
  :Times(0)
  :Timeout(10000)
end

local function addWssCertificatesInIniFile()
  common.addAllCertInSDLbinFolder()
  common.addAllCertInIniFile()
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Add certificates for WS Server in smartDeviceLink.ini file", addWssCertificatesInIniFile)
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT, { appSessionId, appHMIType })
common.Step("Start SDL, HMI", common.startWOdeviceConnect)
common.Step("Connect WebEngine device", common.connectWebEngine, { appSessionId, "WSS" })

common.Title("Test")
common.Step("Register App without PTU", common.registerAppWOPTU, { appSessionId })
common.Step("Activate web app", common.activateApp, { appSessionId })
common.Step("Deactivate web app to NONE and check connection", deactivateAppToNoneAndCheckConnection)
common.Step("Check connection via successful activation", common.activateApp, { appSessionId })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
