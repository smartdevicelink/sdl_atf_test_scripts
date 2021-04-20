-- Requirement summary:
-- [Policies] "default" policies and "KEEP_CONTEXT" validation

-- Description:
-- In case the "default" policies are assigned to the application, PoliciesManager must validate "KEEP_CONTEXT" section and in case "keep_context:true",
-- PoliciesManager must allow SDL to pass the RPC that contains the soft button with KEEP_CONTEXT value for SystemAction.
-- Note: Verification is applied to LocalPT
-- Note: in sdl_preloaded_pt.json, should have "keep_context:true" for "app_policies" and "pre_DataConsent".

-- 1. RunSDL. InitHMI. InitHMI_onReady. ConnectMobile. StartSession.
-- 2. Activiate Application for allow sendRPC Alert
-- 3. MOB-SDL: SendRPC with soft button, KEEP_CONTEXT in SystemAction
-- Expected result
-- SDL must response: success = true, resultCode = "SUCCESS"
--------------------------------------------------------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ Local Functions ]]
local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end

--[[ General Precondition before ATF start]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/ptu_general_default_keep_context_true.json")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_ActivateApplication()

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, { result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestId1,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
            end)
          EXPECT_NOTIFICATION("OnPermissionsChange", {})
        end)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Verify_default_section()
  local test_fail = false
  local keep_context = testCasesForPolicyTableSnapshot:get_data_from_PTS("app_policies.default.keep_context")

  if(keep_context ~= true) then
    commonFunctions:printError("Error: keep_context is not true")
    test_fail = true
  end
  if(test_fail == true) then
    self:FailTestCase("Test failed. See prints")
  end
end

function Test:TestStep_SendRPC_with_KEEP_CONTEXT_true()
  local CorIdAlert = self.mobileSession:SendRPC("Alert",
    {
      alertText1 = "alertText1",
      alertText2 = "alertText2",
      alertText3 = "alertText3",
      ttsChunks =
      {
        {
          text = "TTSChunk",
          type = "TEXT",
        }
      },
      duration = 5000,
      playTone = true,
      progressIndicator = true,
      softButtons =
      {
        {
          type = "TEXT",
          text = "Keep",
          isHighlighted = true,
          softButtonID = 4,
          systemAction = "KEEP_CONTEXT",
        },
        {
          type = "IMAGE",
          image =
          {
            value = "icon.png",
            imageType = "STATIC",
          },
          softButtonID = 5,
          systemAction = "KEEP_CONTEXT",
        },
      }
    })
  local AlertId
  EXPECT_HMICALL("UI.Alert",
    {
      appID = self.applications["Test Application"],
      alertStrings =
      {
        {fieldName = "alertText1", fieldText = "alertText1"},
        {fieldName = "alertText2", fieldText = "alertText2"},
        {fieldName = "alertText3", fieldText = "alertText3"}
      },
      alertType = "BOTH",
      duration = 0,
      progressIndicator = true,
      softButtons =
      {
        {
          type = "TEXT",
          text = "Keep",
          isHighlighted = true,
          softButtonID = 4,
          systemAction = "KEEP_CONTEXT",
        },
        {
          type = "IMAGE",
          softButtonID = 5,
          systemAction = "KEEP_CONTEXT",
        },
      }
    })
  :Do(function(_,data)
      SendOnSystemContext(self,"ALERT")
      AlertId = data.id
      local function alertResponse()
        self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })
        SendOnSystemContext(self,"MAIN")
      end

      RUN_AFTER(alertResponse, 3000)
    end)
  local SpeakId
  EXPECT_HMICALL("TTS.Speak",
    {
      ttsChunks =
      {
        {
          text = "TTSChunk",
          type = "TEXT"
        }
      },
      speakType = "ALERT",
      playTone = true
    })
  :Do(function(_,data)
      self.hmiConnection:SendNotification("TTS.Started")
      SpeakId = data.id
      local function speakResponse()
        self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })

        self.hmiConnection:SendNotification("TTS.Stopped")
      end
      RUN_AFTER(speakResponse, 2000)
    end)
  :ValidIf(function(_,data)
      if #data.params.ttsChunks == 1 then
        return true
      else
        print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1")
        return false
      end
    end)
  EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
