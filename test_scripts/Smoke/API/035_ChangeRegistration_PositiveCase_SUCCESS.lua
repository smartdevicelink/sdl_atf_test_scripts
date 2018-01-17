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
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Functions ]]
local function changeRegistrationSuccess(self)
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

  local cid = self.mobileSession1:SendRPC("ChangeRegistration", requestParams)

  EXPECT_HMICALL("UI.ChangeRegistration", {
    appName = requestParams.appName,
    language = requestParams.hmiDisplayLanguage,
    ngnMediaScreenAppName = requestParams.ngnMediaScreenAppName,
    appID = commonSmoke.getHMIAppId()
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_HMICALL("VR.ChangeRegistration", {
    language = requestParams.language,
    vrSynonyms = requestParams.vrSynonyms,
    appID = commonSmoke.getHMIAppId()
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  EXPECT_HMICALL("TTS.ChangeRegistration", {
    language = requestParams.language,
    ttsName = requestParams.ttsName,
    appID = commonSmoke.getHMIAppId()
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)

  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("ChangeRegistration Positive Case", changeRegistrationSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
