---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PerformAudioPassThru] Speak (<errorCode>) + UI.PerformAudioPassThru (SUCCESS)
-- Clarification of expected result when in PerformAudioPassThru Speak part returns result code that is not error
-- SDL must transfer all <resultCodes> received from HMI to mobile app
-- [HMI API] UI.PerformAudioPassThru request/response
-- [HMI API] TTS.Speak request/response
-- [Mobile API] PerformAudioPassThru request/response
-- [HMI_API] [MOBILE_API] The "audioPassThruIcon" param at "ImageFieldName" struct
--
-- Description:
-- In case SDL transfers Speak_request + UI.PerfromAudioPassThru_request to HMI
-- and receives Speak(<errorCode>) or Speak (resultCode, success:true) response from HMI
-- and UI.PerformAudioPassThru (SUCCESS) from HMI
-- SDL must respond PerformAudioPassThru (WARNINGS, success:true) to mobile app
--
-- 1. Used preconditions
-- 1.1. Structure containing all HMI result_codes, success: false + success: true (without SUCCESS itself) is created
-- 1.2. PerformAudioPassThru RPC is allowed by policy
-- 1.3. All params used in PerformAudioPassThru_request are present and within bounds
-- 1.4. AudioPassThruIcon exists at apps sub-directory of AppStorageFolder (value from ini file)
--
-- 2. Performed steps
-- Send PerformAudioPassThru (audioPassThruIcon, other params)
-- HMI sends to SDL UI.PerformAudioPassThru (SUCCESS)
-- HMI sends to SDL TTS.Speak (resultcode: HMI_result_code,success:false/success:true)
--
-- Expected result:
-- SDL sends UI.PerformAudioPassThru (audioPassThruIcon, other params) to HMI
-- SDL sends to HMI TTS.Speak
-- SDL sends to mobile PerformAudioPassThru (WARNINGS,success:true)
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
  { result_code = "UNSUPPORTED_REQUEST", success = false, info = "" },
  { result_code = "DISALLOWED", success = false, info = "" },
  { result_code = "USER_DISALLOWED", success = false, info = "" },
  { result_code = "REJECTED", success = false, info = "" },
  { result_code = "ABORTED", success = false, info = "" },
  { result_code = "IGNORED", success = false, info = "" },
  { result_code = "IN_USE", success = false, info = "" },
  --TODO(istoimenova): update when "Must SDL resend HMI resultCode hmi_apis::Common_Result::DATA_NOT_AVAILABLE to mobile app" is resolved
  --{ result_code = "VEHICLE_DATA_NOT_AVAILABLE", success = false, info = "" },
  { result_code = "TIMED_OUT", success = false, info = "" },
  { result_code = "INVALID_DATA", success = false, info = "" },
  { result_code = "CHAR_LIMIT_EXCEEDED", success = false, info = "" },
  { result_code = "INVALID_ID", success = false, info = "" },
  { result_code = "DUPLICATE_NAME", success = false, info = "" },
  { result_code = "APPLICATION_NOT_REGISTERED", success = false, info = "" },
  { result_code = "OUT_OF_MEMORY", success = false, info = "" },
  { result_code = "TOO_MANY_PENDING_REQUESTS", success = false, info = "" },
  { result_code = "GENERIC_ERROR", success = false, info = "" },
  { result_code = "TRUNCATED_DATA", success = false, info = "" },
  { result_code = "WARNINGS", success = true, info = "" },
  { result_code = "WRONG_LANGUAGE", success = true, info = "" },
  { result_code = "RETRY", success = true, info = "" },
  { result_code = "SAVED", success = true, info = "" },
  { result_code = "UNSUPPORTED_RESOURCE", success = true, info = "" },

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
  Test["TestStep_PerformAudioPassThru_UI_SUCCESS_TTS_"..hmi_result_code[i].result_code] = function(self)
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
        --TODO (mmihaylova): If should be removed when "[ATF] ATF doesn't process code of HMI response VEHICLE_DATA_NOT_AVAILABLE in error message." is fixed.
        local function ttsSpeakResponse()
          if (hmi_result_code[i].success == true) then
            self.hmiConnection:SendResponse(data.id, data.method, hmi_result_code[i].result_code, {})
          elseif
            (hmi_result_code[i].result_code == "VEHICLE_DATA_NOT_AVAILABLE") then
              self.hmiConnection:Send('{"error":{"data":{"method":"UI.SetAudioStreamingIndicator"},"message":"error message","code":9},"jsonrpc":"2.0","id":'..tostring(data.id)..'}')
            elseif
              (hmi_result_code[i].result_code ~= "VEHICLE_DATA_NOT_AVAILABLE") then
                self.hmiConnection:SendError(data.id,data.method, hmi_result_code[i].result_code, "error")
              end
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
              self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
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

        self.mobileSession:ExpectResponse(CorIdPerformAudioPassThru, {success = true, resultCode = "WARNINGS"})
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