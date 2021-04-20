-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1898
--
-- Precondition:
-- 1) SDL and HMI are started.
-- 2) Media app is registered.
-- 3) Media app in FULL.
-- Description:
-- Media HMI Level resumption is not canceled after unexpected disconnect during active embedded audio source.
-- Steps to reproduce:
-- 1) Media app is disconnected unexpectedly
-- 2) Embeded audio is active (OnEventChanged(AUDIO_SOURCE, isActive=true))
-- 3) Media app is re-registered and SDL does not receive OnEventChanged(AUDIO_SOURCE, isActive=true during ApplicationResumingTimeout.
-- Expected result:
-- SDL must cancel HMILevel resumption for this media app (meaning: media app must be in NONE)
-- Actual result:
-- SDL does not cancel HMILevel resumption.
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local commonDefects = require('test_scripts/Defects/commonDefects')

runner.testSettings.isSelfIncluded = false

--[[ Configuration Modifications ]]
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Local Functions ]]
local function activateAudioSource(self)
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {eventName = "AUDIO_SOURCE", isActive = true})
end

local function unexpectedDisconnect()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
  { appID = common.getHMIAppId(), unexpectedDisconnect = true })
  common.mobile.disconnect()
  common.run.wait(1000)
  :Do(function()
      common.mobile.connect()
    end)
end

local function reRegisterApp()
  local mobSession = common.getMobileSession(1)
  mobSession:StartService(7)
  :Do(function()
    local params = common.getConfigAppParams(1)
    params.hashID = commonDefects.hashId
    local corId = mobSession:SendRPC("RegisterAppInterface", common.getConfigAppParams(1))
    mobSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
      common.getMobileSession():ExpectNotification("OnHMIStatus",
        { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      :Do(function()
        common.getHMIConnection():ExpectNotification("BasicCommunication.ActivateApp")
        :Times(0)
        commonDefects.delayedExp(5000)
      end)
    end)
  end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App1", common.registerAppWOPTU)
runner.Step("Activate App1", common.activateApp)

runner.Title("Test")
runner.Step("unexpected disconnect app1", unexpectedDisconnect)
runner.Step("Activate audio source", activateAudioSource)
runner.Step("Re register App1", reRegisterApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
