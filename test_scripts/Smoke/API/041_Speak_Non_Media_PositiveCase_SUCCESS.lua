---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: Speak
-- Item: Happy path
--
-- Requirement summary:
-- [Speak] SUCCESS on TTS.Speak
--
-- Description:
-- Mobile application sends Speak request with valid parameters to SDL
--
-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
--
-- Steps:
-- Application sends Speak request with valid parameters to SDL
--
-- Expected:
-- SDL validates parameters of the request
-- SDL checks if TTS interface is available on HMI
-- SDL checks if Speak is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the TTS part of request with allowed parameters to HMI
-- SDL receives TTS part of response from HMI with "SUCCESS" result code
-- SDL transfers response to mobile app
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Smoke/commonSmoke')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function getRequestParams()
  return {
    ttsChunks = {
      {
        text ="a",
        type ="TEXT"
      }
    }
  }
end

local function speakSuccess()
  print("Waiting 20s ...")
  local cid = common.getMobileSession():SendRPC("Speak", getRequestParams())
  common.getHMIConnection():ExpectRequest("TTS.Speak", getRequestParams())
  :Do(function(_, data)
      common.getHMIConnection():SendNotification("TTS.Started")
      local function sendSpeakResponse()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
        common.getHMIConnection():SendNotification("TTS.Stopped")
      end
      local function sendOnResetTimeout()
        common.getHMIConnection():SendNotification("BasicCommunication.OnResetTimeout",
          { requestID = data.id, methodName = data.method })
      end
      common.runAfter(sendOnResetTimeout, 9000)
      common.runAfter(sendSpeakResponse, 18000)
    end)

    common.getMobileSession():ExpectNotification("OnHMIStatus")
    :Times(0)

  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(20000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update Preloaded PT", common.updatePreloadedPT)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Speak Positive Case", speakSuccess)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
