---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1901
--
-- Description:
-- Navigation app must be resumed to FULL or LIMITED and AUDIBLE in case of active embedded audio source.
-- Precondition:
-- SDL and HMI are started.
-- In case:
-- 1) Navigation app registers during active embedded audio source (e.g. active radio, CD)
--    and satisfies all conditions for HMILevel resumption.
-- Expected result:
-- 1) SDL must resume navi app to appropriate HMILevel
--    and AUDIBLE audioStreamingState (by sending OnHMIStatus notification to mobile app)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local test = require("user_modules/dummy_connecttest")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application1.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function cleanSessions()
    for i = 1, common.getAppsCount() do
      test.mobileSession[i] = nil
    end
    utils.wait()
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

local function embeddedAudioSource()
    common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
      { eventName = "AUDIO_SOURCE", isActive = true })
end

local function checkResumingNaviApp()
    common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp",
    {appID = common.getHMIAppId()})
    :Do(function(_,data)
        common.getHMIConnection():SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
    common.getMobileSession():ExpectNotification("OnHMIStatus",
        { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("Unexpected disconnect app", unexpectedDisconnect)
runner.Step("Active embedded audio source", embeddedAudioSource)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("checkResumingActivationApp", checkResumingNaviApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
