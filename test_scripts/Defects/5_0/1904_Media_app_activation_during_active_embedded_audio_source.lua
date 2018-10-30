---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1904
--
-- Description:
-- Media app activation during active embedded audio source
-- In case:
-- 1) Media app is registered.
-- 2) Media app in BACKGROUND and NOT_AUDIBLE due to active embedded audio source.
-- 3) User activates this media app and SDL receives from HMI:
-- a) OnEventChanged (AUDIO_SOURCE, isActive=false)
-- b) SDL.ActivateApp (<appID_of_media_app>)
-- Expected result:
-- 1) SDL must respond SDL.ActivateApp (SUCCESS) to HMI send OnHMIStatus (FULL, AUDIBLE) to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true

--[[ Local Functions ]]
local function deactivateApp()
    common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId() })
    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
end

local function embeddedAudioSource()
    common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
      { eventName = "AUDIO_SOURCE", isActive = true })

    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

local function activateMediaApp()
    common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
      { eventName = "AUDIO_SOURCE", isActive = false })
    local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
    EXPECT_HMIRESPONSE(requestId)

    common.getMobileSession():ExpectNotification("OnHMIStatus",
      { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" },
      { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
    :Times(2)
end


--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Deactivate App LIMITED", deactivateApp)
runner.Step("Media app during active embedded audio source", embeddedAudioSource)
runner.Step("Activate media app", activateMediaApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
