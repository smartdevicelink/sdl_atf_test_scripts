---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0273-webengine-projection-mode.md
--
-- Description:
-- Check that SDL forwards OnSystemCapabilityUpdated notification
-- to the WebEngine projection app
--
-- Precondition:
-- 1. SDL and HMI are started
-- 2. WebEngine device is connected to SDL
--
-- Sequence:
-- 1. WebEngine projection application tries to register
--  a. SDL proceeds with `RAI` request successfully
--  b. SDL does not send `OnSystemCapabilityUpdated` to the WebEngine projection app
-- 2. HMI sends `OnSystemCapabilityUpdated` to SDL
--  a. SDL transfers `OnSystemCapabilityUpdated` notification to the WebEngine projection app
---------------------------------------------------------------------------------------------------
-- [[ Required Shared Libraries ]]
local common = require('test_scripts/WebEngine/commonWebEngine')

--[[ Local Variables ]]
local appSessionId = 1
local appHMIType = { "WEB_VIEW" }

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = appHMIType

--[[ Local Functions ]]
local function sendRegisterApp()
  common.getMobileSession():ExpectNotification("OnSystemCapabilityUpdated"):Times(0)
  common.registerAppWOPTU(appSessionId)
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
common.Step("Add AppHMIType to preloaded policy table", common.updatePreloadedPT, { appSessionId, appHMIType})
common.Step("Start SDL, HMI", common.startWOdeviceConnect)
common.Step("Connect WebEngine device", common.connectWebEngine, { appSessionId, "WS" })

common.Title("Test")
common.Step("App sends RAI RPC no OnSCU notification", sendRegisterApp)
common.Step("HMI sends OnSCU notification", sendOnSCU)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
