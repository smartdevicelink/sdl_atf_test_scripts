---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PerformAudioPassThru] "audioPassThruIcon" does NOT exist at 'AppStorageFolder'
-- [HMI API] UI.PerformAudioPassThru request/response
-- [HMI API] TTS.Speak request/response
-- [Mobile API] PerformAudioPassThru request/response
-- [HMI_API] [MOBILE_API] The "audioPassThruIcon" param at "ImageFieldName" struct
--
-- Description:
-- In case mobile app sends PerformAudioPassThru_request to SDL 
-- with valid <audioPassThruIcon> parameter
-- and the requested <audioPassThruIcon> does NOT exist at app`s sandbox
-- and with another related to request valid params
-- transfer UI.PerformAudioPassThru (<audioPassThruIcon>, other params)_request + Speak_request (depends on parameters provided by the app) to HMI
-- respond with <resultCode_received_from_HMI> + <info> to mobile app (expected resultCode from HMI is "WARNINGS" and info: "Reference image(s) not found" 
-- as described in [CTR] Conditions for SDL to handle case when requested <Image> does not exist at "AppStorageFolder"
--
-- 1. Used preconditions
-- 1.1. PerformAudioPassThru RPC is allowed by policy
-- 1.2. audioPassThruIcon does not exist in created by app AppStorageFolder
-- 1.3. Request is sent with valid audioPassThruIcon parameter with type STATIC, all other params used in PerformAudioPassThru_request are present and within bounds 
--
-- 2. Performed steps
-- Send PerformAudioPassThru (audioPassThruIcon, other params)
-- HMI sends UI.PerformAudioPassThru (WARNINGS, info) to SDL
-- HMI sends TTS.Speak (SUCCESS)
--
-- Expected result:
-- SDL sends UI.PerformAudioPassThru to HMI
-- SDL sends TTS.Speak to HMI
-- SDL sends PerformAudioPassThru (WARNINGS, success:true, info:Reference image(s) not found) to mobile app
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
local SDLConfig = require('user_modules/shared_testcases/SmartDeviceLinkConfigurations')
local config_path_sdl = commonPostconditions:GetPathToSDL()
local PathToAppFolder = config_path_sdl .. SDLConfig:GetValue("AppStorageFolder") .. "/" .. tostring(config.application1.registerAppInterfaceParams.appID .. "_" .. tostring(config.deviceMAC) .. "/")

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

function Test:Precondition_Check_that_audioPassThruIcon_is_NonExistent()
  local result = commonSteps:file_exists(PathToAppFolder .. "icon.png")
   if(result ~= true) then
    print("The audioPassThruIcon: icon.png doesn't exist at application's sandbox")
  else
    print("The audioPassThruIcon: icon.png exists at application's sandbox") 
    self:FailTestCase ("The audioPassThruIcon: icon.png exists at application's sandbox")
  end
end

function Test:Precondition_ActivateApp()
  testCasesForPerformAudioPassThru:ActivateAppDiffPolicyFlag
  (self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_All_Params_Missing_audioPassThruIcon_STATIC()
  local CorIdPerformAudioPassThruAppParVD= self.mobileSession:SendRPC("PerformAudioPassThru",
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
      ttsChunks = {{ text = "Makeyourchoice", type = "TEXT"}},
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
        {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
        {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},
      },
      maxDuration = 2000,
      muteAudio = true,
      audioPassThruIcon =
      { 
        value = "icon.png",
        imageType = "STATIC"
      }  
    })
  :Do(function(_,data)
      local function UIPerformAudioResponse()
        self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "WARNINGS",{info = "Reference image(s) not found"})
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

  self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruAppParVD, {success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
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