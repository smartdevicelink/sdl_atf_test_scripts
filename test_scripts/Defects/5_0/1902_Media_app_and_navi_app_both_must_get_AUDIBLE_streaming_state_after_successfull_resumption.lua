---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1902
--
-- Description:
-- Media app and navi app both must get AUDIBLE streaming state after successfull resumption
-- Precondition:
-- SDL and HMI are started.
-- In case:
-- 1) Media app registers and gets FULL/LIMITED and AUDIBLE
-- 2) Navigation app registers and satisfies all conditions for HMILevel resumption
-- Expected result:
-- 1) SDL must resume navi app to appropriate (according to existing req-s) and AUDIBLE audioStreamingState
-- (by sending OnHMIStatus notification to mobile app).
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local test = require("user_modules/dummy_connecttest")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application2.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function ignitionOff()
    common.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",
      { reason = "IGNITION_OFF" })
    common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
      { unexpectedDisconnect = true })
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnSDLClose")
    :Do(function()
      StopSDL()
    end)
end

local function cleanSessions()
    for i = 1, common.getAppsCount() do
      test.mobileSession[i] = nil
    end
    utils.wait()
end

local function checkResumingMediaApp(pAppId)
    if not pAppId then pAppId = 1 end
    common.getHMIConnection(pAppId):ExpectRequest("BasicCommunication.ActivateApp",
      { appID = common.getHMIAppId(pAppId) })
    :Do(function(_,data)
        common.getHMIConnection(pAppId):SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
    common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

local function checkResumingNaviApp(pAppId)
    if not pAppId then pAppId = 2 end
    common.getHMIConnection():ExpectRequest("BasicCommunication.OnResumeAudioSource",
      { appID = common.getHMIAppId(pAppId) })
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register media app", common.registerAppWOPTU)
runner.Step("Register navi app", common.registerAppWOPTU, {2})
runner.Step("Activate navi app", common.activateApp, {2})
runner.Step("Activate media app", common.activateApp)

runner.Title("Test")
runner.Step("IGNITION_OFF", ignitionOff)
runner.Step("Close mobile connection", cleanSessions)
runner.Step("Ignition On", common.start)
runner.Step("Register media app", common.registerAppWOPTU)
runner.Step("checkResuming media app to FULL", checkResumingMediaApp)
runner.Step("Register navi app", common.registerAppWOPTU, {2})
runner.Step("checkResuming navi app to LIMITED", checkResumingNaviApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
