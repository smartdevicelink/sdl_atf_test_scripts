---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: ChangeRegistration
-- Item: Happy path
--
-- Requirement summary:
-- [ChangeRegistration] SUCCESS on UI.ChangeRegistration
--
-- Description:
-- Mobile application sends ChangeRegistration request with valid parameters to SDL
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
--
-- Steps:
-- Application sends ChangeRegistration request with valid parameters to SDL
--
-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI, VR, TTS interface is available on HMI
-- SDL checks if ChangeRegistration is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI, VR, TTS part of request with allowed parameters to HMI
-- SDL receives UI, VR, TTS part of response from HMI with "SUCCESS" result code
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function changeRegistrationSuccess()
  local requestParams = {
    language ="EN-US",
    hmiDisplayLanguage ="EN-US",
    appName ="SyncProxyTester",
    ttsName = {
      {
        text ="SyncProxyTester",
        type ="TEXT",
      },
    },
    ngnMediaScreenAppName ="SPT",
    vrSynonyms = {
      "VRSyncProxyTester",
    }
  }

  local cid = common.getMobileSession():SendRPC("ChangeRegistration", requestParams)

  common.getHMIConnection():ExpectRequest("UI.ChangeRegistration", {
    appName = requestParams.appName,
    language = requestParams.hmiDisplayLanguage,
    ngnMediaScreenAppName = requestParams.ngnMediaScreenAppName,
    appID = common.getHMIAppId()
  })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getHMIConnection():ExpectRequest("VR.ChangeRegistration", {
    language = requestParams.language,
    vrSynonyms = requestParams.vrSynonyms,
    appID = common.getHMIAppId()
  })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getHMIConnection():ExpectRequest("TTS.ChangeRegistration", {
    language = requestParams.language,
    ttsName = requestParams.ttsName,
    appID = common.getHMIAppId()
  })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("ChangeRegistration Positive Case", changeRegistrationSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
