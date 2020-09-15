---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1920
--
-- Description:
-- Multiple media and navigation apps activation during active embedded navigation+audio mixing supported
--
-- Precondition:
-- 1) "MixingAudioSupported" = true at .ini file
-- 2) SDL and HMI are started.
-- 3) Three apps running on system:
--    a. media app_1 in FULL and AUDIBLE
--    b. navigation app_2 in LIMITED and AUDIBLE
--    c. non-media app_3 in BACKGROUND and NOT_AUDIBLE
-- 4) User activates embedded navigation and HMILevel of apps were changed to:
--    a. media app_1 in LIMITED and AUDIBLE
--    b. navigation app_2 in BACKGROUND and NOT_AUDIBLE
-- 
-- Steps to reproduce:
-- 1) User activates media app_1
--    HMI -> SDL: SDL.ActivateApp ( <appID_1> )
--    SDL -> HMI: SDL.ActivateApp (SUCCESS)
-- 2) SDL -> media app_1: OnHMIStatus (FULL, AUDIBLE)
--    Note: embedded navigation is still active
-- 3) User activates navigation app_2
--    HMI -> SDL: OnEventChanged (EMBEDDED_NAVI, isActive:false)
--    HMI -> SDL: OnAppDeactivated ( <appID_1> )
--    HMI -> SDL: SDL.ActivateApp ( <appID_2 )
-- 
-- Expected result:
-- 1) SDL -> media app_1 : OnHMIStatus (LIMITED, AUDIBLE)
-- 2) SDL -> HMI: SDL.ActivateApp (SUCCESS)
-- 3) SDL -> navigation app_2 : OnHMIStatus (FULL, AUDIBLE)
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local hmi_values = require('user_modules/hmi_values')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.application1.registerAppInterfaceParams.isMediaApplication = true
config.application2.registerAppInterfaceParams.appHMIType = { "NAVIGATION" }
config.application2.registerAppInterfaceParams.isMediaApplication = false
config.application3.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application3.registerAppInterfaceParams.isMediaApplication = false

--[[ Local Functions ]]
local function getHMIValues()
  local params = hmi_values.getDefaultHMITable()
  params.BasicCommunication.MixingAudioSupported.attenuatedSupported = true
  return params
end

local function sendActivateApp(pAppId)
  local cid = common.getHMIConnection():SendRequest("SDL.ActivateApp",
    { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(cid)
end

local function sendDeactivateApp(pAppId)
  common.getHMIConnection():SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = common.getHMIAppId(pAppId) })
end

local function sendEmbeddedNavi(pIsActive)
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "EMBEDDED_NAVI", isActive = pIsActive })
end

local function activateApp_3()
  common.getMobileSession(1):ExpectNotification("OnHMIStatus"):Times(0)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus"):Times(0)
  common.getMobileSession(3):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE" })
  sendActivateApp(3)
end

local function activateApp_2()
  common.getMobileSession(1):ExpectNotification("OnHMIStatus"):Times(0)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  common.getMobileSession(3):ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" })
  sendActivateApp(2)
end

local function activateApp_1()
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
  common.getMobileSession(3):ExpectNotification("OnHMIStatus"):Times(0)
  sendActivateApp(1)
end

local function activateEmbeddedNavi()
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE" })
  common.getMobileSession(3):ExpectNotification("OnHMIStatus"):Times(0)
  sendDeactivateApp(1)
  sendEmbeddedNavi(true)
end

local function activateApp_1_EN()
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  common.getMobileSession(2):ExpectNotification("OnHMIStatus"):Times(0)
  common.getMobileSession(3):ExpectNotification("OnHMIStatus"):Times(0)
  sendActivateApp(1)
end

local function activateApp_2_EN()
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" })
  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "LIMITED", audioStreamingState = "AUDIBLE" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE" })
  :Times(2)
  common.getMobileSession(3):ExpectNotification("OnHMIStatus"):Times(0)
  sendEmbeddedNavi(false)
  sendActivateApp(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set MixingAudioSupported=true in ini file", common.setSDLIniParameter, { "MixingAudioSupported", "true" })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { getHMIValues() })
runner.Step("RAI 1", common.registerAppWOPTU, { 1 })
runner.Step("RAI 2", common.registerAppWOPTU, { 2 })
runner.Step("RAI 3", common.registerApp, { 3 })
runner.Step("Activate App 3", activateApp_3)
runner.Step("Activate App 2", activateApp_2)
runner.Step("Activate App 1", activateApp_1)

runner.Title("Test")
runner.Step("Activate Embedded Navi", activateEmbeddedNavi)
runner.Step("Activate App 1 EN", activateApp_1_EN)
runner.Step("Activate App 2 EN", activateApp_2_EN)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
