---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1899
--
-- Description:
-- SDl does not resume media app after unexpectedDisconnect and re-registration during active embedded audio source.
-- Precondition:
-- SDL and HMI are started.
-- Media app is registered.
-- In case:
-- 1) Media app being in FULL or LIMITED and AUDIBLE unexpectedly disconnects
-- and re-registers during active embedded audio source within the same ignition cycle
-- and SDL receives OnEventChanged (AUDIO_SOURCE, isActive=false)
-- from HMI during ApplicationResumingTimeout (the value defined at .ini file)
-- Expected result:
-- 1) SDL must resume HMILevel
-- and audioStreamingState of this media app being before unexpected disconnect
-- (by sending OnHMIStatus notification to this media app).
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local connect = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Local Functions ]]
local function embeddedAudioSource()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "AUDIO_SOURCE", isActive = true })
end

local function cleanSessions()
  for i = 1, common.getAppsCount() do
    connect.mobileSession[i] = nil
  end
end

local function unexpectedDisconnect()
  common.getMobileSession():Stop()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = true })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    cleanSessions()
  end)
end

local function checkResumingMediaApp()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp",
    { appID = common.getHMIAppId() })
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "AUDIO_SOURCE", isActive = false })
  common.getMobileSession():ExpectNotification("OnHMIStatus", { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)
runner.Step("Unexpected disconnect app", unexpectedDisconnect)
runner.Step("Active audio navigation", embeddedAudioSource)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("checkResumingActivationApp", checkResumingMediaApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
