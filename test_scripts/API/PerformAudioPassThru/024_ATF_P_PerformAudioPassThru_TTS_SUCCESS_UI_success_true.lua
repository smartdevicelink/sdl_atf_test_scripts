---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PerformAudioPassThru] Speak (SUCCESS) + UI.PerformAudioPassThru (<applicable_resultCode>)
-- SDL must transfer all <resultCodes> received from HMI to mobile app
-- [HMI API] UI.PerformAudioPassThru request/response
-- [HMI API] TTS.Speak request/response
-- [Mobile API] PerformAudioPassThru request/response
-- [HMI_API] [MOBILE_API] The "audioPassThruIcon" param at "ImageFieldName" struct
--
-- Description:
-- In case SDL transfers Speak_request + UI.PerfromAudioPassThru_request to HMI
-- and receives Speak(SUCCESS) response from HMI
-- and UI.PerformAudioPassThru (<resultCode>, sucess:true) from HMI
-- SDL must respond PerformAudioPassThru (<resultCode>, sucess:true) to mobile app
--
-- 1. Used preconditions
-- 1.1. Structure containing all HMI result_codes, success:true is created
-- 1.2. PerformAudioPassThru RPC is allowed by policy
-- 1.3. All params used in PerformAudioPassThru_request are present and within bounds
-- 1.4. AudioPassThruIcon exists at apps sub-directory of AppStorageFolder (value from ini file)
--
-- 2. Performed steps
-- Send PerformAudioPassThru (audioPassThruIcon, other params)
-- HMI sends to SDL UI.PerformAudioPassThru(resultcode: HMI_result_code)
-- HMI sends to SDL TTS.Speak (SUCCESS)
--
-- Expected result:
-- SDL sends UI.PerformAudioPassThru (audioPassThruIcon, other params) to HMI
-- SDL sends TTS.Speak to HMI
-- SDL sends to mobile UI.PerformAudioPassThru(resultcode: HMI_result_code, success:true)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPostconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPerformAudioPassThru = require('user_modules/shared_testcases/testCasesForPerformAudioPassThru')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Local variables ]]
-- info parameter is not specified in scope of the CRQ, it is intended for any applicable future use.
local hmi_result_code = {
  { result_code = "SUCCESS", info = "" },
  { result_code = "WARNINGS", info = "" },
  { result_code = "WRONG_LANGUAGE", info = "" },
  { result_code = "RETRY", info = "" },
  { result_code = "SAVED", info = "" },
  { result_code = "UNSUPPORTED_RESOURCE", info = "" },
}

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
config.defaultProtocolVersion = 2

testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"},"PerformAudioPassThru")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

commonSteps:PutFile("Precondition_PutFile_With_Icon", "icon.png")

function Test:Precondition_Check_audioPassThruIcon_Existence()
  testCasesForPerformAudioPassThru.Check_audioPassThruIcon_Existence(self, "icon.png")
end

function Test:Precondition_ActivateApp()
  testCasesForPerformAudioPassThru:ActivateAppDiffPolicyFlag(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

for i = 1, #hmi_result_code do
  Test["TestStep_PerformAudioPassThru_TTS_SUCCESS_UI_"..hmi_result_code[i].result_code] = function(self)
    local CorIdPerformAudioPassThru= self.mobileSession:SendRPC("PerformAudioPassThru",
      {
        initialPrompt = {{text = "Makeyourchoice",type = "TEXT"}},
        audioPassThruDisplayText1 = "DisplayText1",
        audioPassThruDisplayText2 = "DisplayText2",
        samplingRate = "16KHZ",
        maxDuration = 2000,
        bitsPerSample = "8_BIT",
        audioType = "PCM",
        muteAudio = true,
        audioPassThruIcon =
        {
          value = "icon.png",
          imageType = "STATIC"
        }
      })

    EXPECT_HMICALL("TTS.Speak",
      {
        speakType = "AUDIO_PASS_THRU",
        ttsChunks = {{text = "Makeyourchoice", type = "TEXT"}},
        appID = self.applications[config.application1.registerAppInterfaceParams.appName]
      })
    :Do(function(_,data)
        self.hmiConnection:SendNotification("TTS.Started",{})

        local function ttsSpeakResponse()
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          self.hmiConnection:SendNotification("TTS.Stopped")
        end
        RUN_AFTER(ttsSpeakResponse, 1000)
    end)

    EXPECT_HMICALL("UI.PerformAudioPassThru",
      {
        appID = self.applications[config.application1.registerAppInterfaceParams.appName],
        audioPassThruDisplayTexts = {
          {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
          {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},
        },
        maxDuration = 2000,
        muteAudio = true,
        audioPassThruIcon =
        {
          imageType = "STATIC",
          value = "icon.png"
        }
      })
    :Do(function(_,data)

        local function UIPerformAudioResponse()
          self.hmiConnection:SendResponse(data.id, data.method, hmi_result_code[i].result_code)
        end
        RUN_AFTER(UIPerformAudioResponse, 1500)
    end)

    if
    (self.appHMITypes["NAVIGATION"] == true) or
    (self.appHMITypes["COMMUNICATION"] == true) or
    (self.isMediaApplication == true) then

      EXPECT_NOTIFICATION("OnHMIStatus",
        {hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Times(2)
    else
      EXPECT_NOTIFICATION("OnHMIStatus"):Times(0)
    end

    self.mobileSession:ExpectResponse(CorIdPerformAudioPassThru, {success = true, resultCode = hmi_result_code[i].result_code})
    EXPECT_NOTIFICATION("OnHashChange",{}):Times(0)
  end

end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_preloaded_pt_File()
  commonPostconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
