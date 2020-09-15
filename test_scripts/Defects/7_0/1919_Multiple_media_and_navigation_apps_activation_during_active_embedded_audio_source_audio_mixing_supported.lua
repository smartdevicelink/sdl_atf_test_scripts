---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1919
-- Description:
-- Multiple media and navigation apps activation during active embedded audio source+audio mixing supported
-- Precondition:
-- 1) "MixingAudioSupported" = true at .ini file.
-- 2) SDL and HMI are started.
-- 3) Three apps running on system:
--    a. media app_1 in FULL and AUDIBLE
--    b. navigation app_2 in LIMITED and AUDIBLE
--    c. non-media app_3 in BACKGROUND and NOT_AUDIBLE
-- 4) User activates embedded navigation and HMILevel of apps were changed to:
--    a. media app_1 in LIMITED and AUDIBLE
--    b. navigation app_2 in BACKGROUND and NOT_AUDIBLE
-- 5) User activates media app_1 -> FULL, AUDIBLE
--    a. navigation app_2 still in BACKGROUND and NOT_AUDIBLE
--    b. non-media app_3 still in BACKGROUND and NOT_AUDIBLE
-- 6) User activates navigation app_2 -> FULL, AUDIBLE
-- Steps to reproduce:
-- 1) User activates non-media app_3
--    HMI -> SDL: OnAppDeactivated ( <appID_2> )
--    HMI -> SDL: SDL.ActivateApp ( <appID_3 )
-- Expected result:
-- 1) SDL -> navigation app_2 : OnHMIStatus (LIMITED, AUDIBLE)
-- 2) SDL -> HMI: SDL.ActivateApp (SUCCESS)
-- 3) SDL -> non-media app_3 : OnHMIStatus (FULL, NOT_AUDIBLE)
-- Note: media app_1 still in LIMITED and AUDIBLE
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require("user_modules/sequences/actions")
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Applications Configuration ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application3.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application3.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Variables ]]
local appsOnHMIStatusExp = {
  navi = { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
  media = { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" },
  non_media = { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" }
}

--[[ Local Functions ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.BasicCommunication.MixingAudioSupported.attenuatedSupported = true
  return params
end

local function appActivation(pAppId, pExpTbl)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", pExpTbl)
end

local function deactivateApp(pAppId)
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated", { appID = common.getHMIAppId(pAppId) })
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
    if config["application"..pAppId].registerAppInterfaceParams.isMediaApplication == true or 
       config["application"..pAppId].registerAppInterfaceParams.appHMIType[1] == "NAVIGATION" then
      return data.payload.audioStreamingState == "AUDIBLE" and
        data.payload.videoStreamingState == "STREAMABLE" and
        data.payload.hmiLevel == "LIMITED" and
        data.payload.systemContext == "MAIN"
    else
      return data.payload.audioStreamingState == "NOT_AUDIBLE" and
        data.payload.videoStreamingState == "NOT_STREAMABLE" and
        data.payload.hmiLevel == "BACKGROUND" and
        data.payload.systemContext == "MAIN"
    end
  end)
end

local function embeddedNaviActivated()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "EMBEDDED_NAVI", isActive = true })
  common.getMobileSession(1):ExpectNotification("OnHMIStatus", {
    hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE", videoStreamingState = "NOT_STREAMABLE"
  })
end

local function activateMediaApp()
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(1) })
  EXPECT_HMIRESPONSE(requestId)
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",{ hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
end

local function activateNaviApp()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "EMBEDDED_NAVI", isActive = false })
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(2) })
  EXPECT_HMIRESPONSE(requestId)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
  { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" },
  { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)

  common.getMobileSession(1):ExpectNotification("OnHMIStatus", { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
end

local function activateNonMediaApp()
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(3) })
  EXPECT_HMIRESPONSE(requestId)
  common.getMobileSession(3):ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" })
end

--[[ Test ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set MixingAudioSupported=true in ini file", common.setSDLIniParameter, { "MixingAudioSupported", "true" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getHMIValues() })
runner.Step("Register App 1 (media)", common.registerAppWOPTU, { 1 })
runner.Step("Register App 2 (navi)", common.registerAppWOPTU, { 2 })
runner.Step("Register App 3 (non media)", common.registerAppWOPTU, { 3 })
runner.Step("Activate App 3 (non media)", appActivation, { 3, appsOnHMIStatusExp.non_media })
runner.Step("Activate App 2 (navi)", appActivation, { 2, appsOnHMIStatusExp.navi })
runner.Step("Activate App 1 (media)", appActivation, { 1, appsOnHMIStatusExp.media })
runner.Step("Embedded audio", embeddedNaviActivated)
runner.Step("Activate media app", activateMediaApp)
runner.Step("Activate navi app", activateNaviApp)

runner.Title("Test")
runner.Step("Deactivate navi app", deactivateApp, { 2 })
runner.Step("Activate non_media app", activateNonMediaApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
