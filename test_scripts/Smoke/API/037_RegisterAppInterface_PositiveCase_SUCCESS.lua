---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: RegisterAppInterface
-- Item: Happy path
--
-- Requirement summary:
-- [RegisterAppInterface] SUCCESS: getting SUCCESS:RegisterAppInterface() during reregistration
--
-- Description:
-- Mobile application sends valid RegisterAppInterface request after unregistration and
-- gets RegisterAppInterface "SUCCESS" response from SDL

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests RegisterAppInterface

-- Expected:
-- SDL checks if RegisterAppInterface is allowed by Policies
-- SDL sends the BasicCommunication notification to HMI
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local requestParams = {
  syncMsgVersion = {
    majorVersion = 5,
    minorVersion = 0,
  },
  appName = "SyncProxyTester",
  ttsName = {
    {
      text ="SyncProxyTester",
      type ="TEXT",
    },
  },
  ngnMediaScreenAppName = "SPT",
  vrSynonyms = {
    "VRSyncProxyTester",
  },
  isMediaApplication = true,
  languageDesired = "EN-US",
  hmiDisplayLanguageDesired = "EN-US",
  appHMIType = {
    "DEFAULT",
  },
  appID = "123",
  fullAppID = "123456",
  deviceInfo = {
    hardware = "hardware",
    firmwareRev = "firmwareRev",
    os = "os",
    osVersion = "osVersion",
    carrier = "carrier",
    maxNumberRFCOMMPorts = 5
  }
}

local function SetNotificationParams()
  local notificationParams = {
    application = {}
  }
  notificationParams.application.appName = requestParams.appName
  notificationParams.application.ngnMediaScreenAppName = requestParams.ngnMediaScreenAppName
  notificationParams.application.isMediaApplication = requestParams.isMediaApplication
  notificationParams.application.hmiDisplayLanguageDesired = requestParams.hmiDisplayLanguageDesired
  notificationParams.application.appType = requestParams.appHMIType
  notificationParams.application.deviceInfo = {
    name = common.getDeviceName(),
    id = common.getDeviceMAC(),
    transportType = common.getDeviceTransportType(),
    isSDLAllowed = true
  }
  notificationParams.application.policyAppID = requestParams.fullAppID
  notificationParams.ttsName = requestParams.ttsName
  notificationParams.vrSynonyms = requestParams.vrSynonyms
  return notificationParams
end

--[[ Local Functions ]]
local function unregisterAppInterface()
  local cid = common.getMobileSession():SendRPC("UnregisterAppInterface", { })
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered",
    { appID = common.getHMIAppId(), unexpectedDisconnect = false })
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

local function registerAppInterface()
  local CorIdRAI = common.getMobileSession():SendRPC("RegisterAppInterface", requestParams)
  local notificationParams = SetNotificationParams()
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered", notificationParams)
  common.getMobileSession():ExpectResponse(CorIdRAI, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  common.getMobileSession():ExpectNotification("OnPermissionsChange")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("UnregisterAppInterface Positive Case", unregisterAppInterface)

runner.Title("Test")
runner.Step("RegisterAppInterface Positive Case", registerAppInterface)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
