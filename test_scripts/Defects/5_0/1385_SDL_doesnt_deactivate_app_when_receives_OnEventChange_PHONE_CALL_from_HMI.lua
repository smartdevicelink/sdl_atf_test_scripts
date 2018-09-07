---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1385
--
-- Precondition:
-- SDL Core and HMI are started.
-- App is registered and activated
-- Description:
-- Steps to reproduce:
-- 1) SDL receives BasicCommunication.OnEventChanged(Phone_Call,true) from HMI when apps are full.
-- Expected:
-- SDL should send to mobile app OnHMIStatus
--   1) For navi app: hmiLevel = "LIMITED", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
--   2) For media app: hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
--   3) For voice communication app: hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"
---------------------------------------------------------------------------------------------------

-- [[ Required Shared libraries ]]
local config = require("local_config")
local runner = require("user_modules/script_runner")
local common = require("user_modules/sequences/actions")
local connect = require("user_modules/dummy_connecttest")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Test params ]]
local cases = {
  navi_non_media = {
    params = {
      isMediaApplication = false,
      appHMIType = { "NAVIGATION" }
    },
    expectedHmiStatus = {
      hmiLevel = "LIMITED",
      audioStreamingState = "NOT_AUDIBLE",
      systemContext = "MAIN"
    }
  },
  vcommunication_non_media = {
    params = {
      isMediaApplication = false,
      appHMIType = { "COMMUNICATION" }
    },
    expectedHmiStatus = {
      hmiLevel = "BACKGROUND",
      audioStreamingState = "NOT_AUDIBLE",
      systemContext = "MAIN"
    }
  },
  default_media = {
    params = {
      isMediaApplication = true,
      appHMIType = { "DEFAULT" }
    },
    expectedHmiStatus = {
      hmiLevel = "BACKGROUND",
      audioStreamingState = "NOT_AUDIBLE",
      systemContext = "MAIN"
    }
  }
}

--[[Local Functions]]
local function prepareConfig(params)
  for key, value in pairs(params) do
    config.application1.registerAppInterfaceParams[key] = value
  end
end

local function sendOnEventChanged(testCase)
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "PHONE_CALL",
    isActive = true })
  common.getMobileSession():ExpectNotification("OnHMIStatus", cases[testCase][expectedHmiStatus])
  common.getHMIConnection():SendNotification("BasicCommunication.OnEventChanged", {
    eventName = "PHONE_CALL",
    isActive = false })
end

local function cleanSessions()
  for i = 1, common.getAppsCount() do
    connect.mobileSession[i] = nil
  end
end

local function unregisterApp()
  local cid = common.getMobileSession():SendRPC("UnregisterAppInterface", {})
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
  { appID = common.getHMIAppId(), unexpectedDisconnect = false })
  common.getMobileSession():ExpectResponse(cid, {success = true, resultCode = "SUCCESS"})
  cleanSessions()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

for key, value in pairs(cases) do
  runner.Title("TestCase: " .. key)
  runner.Step("Prepare application config", prepareConfig, { value.params })
  runner.Step("Register App1", common.registerAppWOPTU, { 1 })
  runner.Step("Activate App1", common.activateApp, { 1 })

  runner.Step("On event changed", sendOnEventChanged, { key })
  runner.Step("Unregister application", unregisterApp)
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
