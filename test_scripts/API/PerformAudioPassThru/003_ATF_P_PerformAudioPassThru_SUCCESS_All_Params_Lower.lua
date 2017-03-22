---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PerformAudioPassThru] SDL must transfer request to HMI in case of valid "audioPassThruIcon" param
-- [HMI API] UI.PerformAudioPassThru request/response
-- [HMI API] TTS.Speak request/response
-- [Mobile API] PerformAudioPassThru request/response
-- [HMI_API] [MOBILE_API] The "audioPassThruIcon" param at "ImageFieldName" struct
--
-- Description:
-- In case mobile app sends PerformAudioPassThru_request to SDL with:
-- valid <audioPassThruIcon> parameter
-- and the requested <audioPassThruIcon> exists at app`s sandbox (see AppStorageFolder section)
-- as well as another related to request valid params
-- SDL must transfer UI.PerformAudioPassThru (<audioPassThruIcon>, other params)_request + Speak_request (depends on parameters provided by the app) to HMI
--
-- 1. Used preconditions
-- 1.1. PerformAudioPassThru RPC is allowed by policy
-- 1.2. All params used in PerformAudioPassThru_request are present and in lower bound. 
-- 1.3. AudioPassThruIcon exists at apps sub-directory of AppStorageFolder (value from ini file)
--
-- 2. Performed steps
-- Send PerformAudioPassThru (audioPassThruIcon, other params in lower) from mobile to SDL and check:
--
-- Expected result:
-- SDL sends UI.PerformAudioPassThru (audioPassThruIcon, other params) to HMI
-- SDL sends TTS.Speak to HMI
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPostconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPerformAudioPassThru = require('user_modules/shared_testcases/testCasesForPerformAudioPassThru')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

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

commonSteps:PutFile("Precondition_PutFile_With_Icon","1")

function Test:Precondition_Check_audioPassThruIcon_Existence()
  local icon = "1"
  testCasesForPerformAudioPassThru.Check_audioPassThruIcon_Existence(self, icon)
end

function Test:Precondition_ActivateApp()
  testCasesForPerformAudioPassThru:ActivateAppDiffPolicyFlag(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PerformAudioPassThru_AllParameters_Lower_SUCCESS()
  local CorIdPerformAudioPassThruAppLowerPar= self.mobileSession:SendRPC("PerformAudioPassThru",
    {
      initialPrompt = {{text = "A", type = "TEXT"}},
      audioPassThruDisplayText1 = "1",
      audioPassThruDisplayText2 = "2",
      samplingRate = "8KHZ",
      maxDuration = 1,
      bitsPerSample = "8_BIT",
      audioType = "PCM",
      muteAudio = true,
      audioPassThruIcon =
      { 
        value = "1",
        imageType = "STATIC"
      }
    })

  EXPECT_HMICALL("TTS.Speak",
    {
      speakType = "AUDIO_PASS_THRU",
      ttsChunks = {{text = "A", type = "TEXT"}},
      appID = self.applications[config.application1.registerAppInterfaceParams.appName]
    })
  :Do(function(_,data)
      self.hmiConnection:SendNotification("TTS.Started",{})

      local function ttsSpeakResponse()
        self.hmiConnection:SendResponse (data.id, data.method, "SUCCESS", {})
        self.hmiConnection:SendNotification("TTS.Stopped")
      end
      RUN_AFTER(ttsSpeakResponse, 1000)
  end)

  EXPECT_HMICALL("UI.PerformAudioPassThru",
    {
      appID = self.applications[config.application1.registerAppInterfaceParams.appName],
      audioPassThruDisplayTexts = {
        {fieldName = "audioPassThruDisplayText1", fieldText = "1"},
        {fieldName = "audioPassThruDisplayText2", fieldText = "2"},
      },
      maxDuration = 1,
      muteAudio = true,
      audioPassThruIcon = 
      { 
        imageType = "STATIC", 
        value = "1"
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

  self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruAppLowerPar, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange"):Times(0)
  
  commonTestCases:DelayedExp(1500)
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
