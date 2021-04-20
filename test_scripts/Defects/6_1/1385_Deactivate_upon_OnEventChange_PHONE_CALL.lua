---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/1385
--
-- Precondition:
-- SDL Core and HMI are started.
-- App is registered and activated
-- Description:
-- Steps to reproduce:
-- 1) SDL receives BasicCommunication.OnEventChanged(Phone_Call,true) from HMI when apps are in full.
-- Expected:
-- SDL should send to mobile app OnHMIStatus
--   1) For navi app: hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
--   2) For media app: hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
--   3) For voice communication app: hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [1] = { appType = "MEDIA", isMedia = true, hmiLevel = "BACKGROUND", audioSS = "NOT_AUDIBLE" },
  [2] = { appType = "COMMUNICATION", isMedia = false, hmiLevel = "BACKGROUND", audioSS = "NOT_AUDIBLE" },
  [3] = { appType = "NAVIGATION", isMedia = false, hmiLevel = "LIMITED", audioSS = "NOT_AUDIBLE" }
}

--[[ Local Functions ]]
local function registerApp(pAppId, pAppType, pAppIsMedia)
  local params = common.getConfigAppParams(pAppId)
  params.appHMIType = { pAppType }
  params.isMediaApplication = pAppIsMedia
  common.registerAppWOPTU(pAppId)
end

local function activatePhoneCall(pAppId, pExpHMILevel, pExpAudioSS)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = pExpHMILevel, audioStreamingState = pExpAudioSS })
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "PHONE_CALL", isActive = true })
  utils.wait(1000)
end

local function deactivatePhoneCall()
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged",
    { eventName = "PHONE_CALL", isActive = false })
  utils.wait(1000)
end

local function unregisterApp(pAppId)
  local cid = common.getMobileSession(pAppId):SendRPC("UnregisterAppInterface", {})
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { unexpectedDisconnect = false, appID = common.getHMIAppId(pAppId) })
end

local function activateApp(pAppId)
  local cid = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId(pAppId) })
  common.getHMIConnection():ExpectResponse(cid)
  common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
for id, tc in pairs(testCases) do
  runner.Title("App " .. tc.appType)
  runner.Step("Register App", registerApp, { id, tc.appType, tc.isMedia })
  runner.Step("Activate App", activateApp, { id })
  runner.Step("Activate Phone Call", activatePhoneCall, { id, tc.hmiLevel, tc.audioSS })
  runner.Step("Deactivate Phone Call", deactivatePhoneCall)
  runner.Step("Unregister App", unregisterApp, { id })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
