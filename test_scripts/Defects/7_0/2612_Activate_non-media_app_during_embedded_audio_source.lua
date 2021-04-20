---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/2612
---------------------------------------------------------------------------------------------------
-- Steps:
-- 1. Send from HMI OnEventChanged(AUDIO_SOURCE:true)
-- 2. Register non-Media app
-- 3. Activate app
--
-- Expected:
-- SDL activates App: sends OnHMIStatus(FULL)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function onEventChanged()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "AUDIO_SOURCE",
    isActive = true })
end

local function activateApp()
  local cid = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  common.getHMIConnection():ExpectResponse(cid)
  common.getMobileSession():ExpectNotification("OnHMIStatus", {
    hmiLevel = "FULL",
    systemContext = "MAIN",
    audioStreamingState = "NOT_AUDIBLE",
    videoStreamingState = "NOT_STREAMABLE"
  })
end

local function onEventChanged_false()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "AUDIO_SOURCE",
    isActive = false })
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)

runner.Title("Test")
runner.Step("OnEventChanged AUDIO_SOURCE true", onEventChanged)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", activateApp)
runner.Step("OnEventChanged AUDIO_SOURCE false", onEventChanged_false)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)