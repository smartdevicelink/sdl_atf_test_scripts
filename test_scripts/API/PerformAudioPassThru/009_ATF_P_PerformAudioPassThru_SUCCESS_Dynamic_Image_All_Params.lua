---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PerformAudioPassThru] SDL must transfer request to HMI in case of valid "audioPassThruIcon" param
-- [HMI API] UI.PerformAudioPassThru request/response
-- [Mobile API] PerformAudioPassThru request/response
-- [HMI_API] [MOBILE_API] The "audioPassThruIcon" param at "ImageFieldName" struct
-- [HMI API] TTS.Speak request/response
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
-- 1.2. All params used in PerformAudioPassThru_request are present and within bounds, audioPassThruIcon is sent with imageType = "DYNAMIC"
-- 1.3. AudioPassThruIcon exists at apps sub-directory of AppStorageFolder (value from ini file)
--
-- 2. Performed steps
-- Send PerformAudioPassThru (audioPassThruIcon, other params) from mobile to SDL and check:
--
-- Expected result:
-- SDL sends UI.PerformAudioPassThru (audioPassThruIcon (imageType = "DYNAMIC"), other params) to HMI
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
local storagePath = commonPostconditions:GetPathToSDL() .."storage/"

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

function Test:TestStep_PerformAudioPassThru_AllParameters_DYNAMIC_ImageType_SUCCESS()
  local CorIdPerformAudioPassThruAppParALLDynamic= self.mobileSession:SendRPC("PerformAudioPassThru",
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
        imageType = "DYNAMIC"
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
      audioPassThruIcon = { imageType = "DYNAMIC" },
      appID = self.applications[config.application1.registerAppInterfaceParams.appName],
      audioPassThruDisplayTexts = {
        {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
        {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},
      },
      maxDuration = 2000,
      muteAudio = true
    })
  :Do(function(_,data)
      local function UIPerformAudioResponse()
        self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
      end
      RUN_AFTER(UIPerformAudioResponse, 1500)
    end)
   :ValidIf (function(_,data2)
    	if(data2.params.audioPassThruIcon ~= nil) then
		  	if (string.match(data2.params.audioPassThruIcon.value, "%S*" .. "("..string.sub(storagePath, 2).."icon.png)" .. "$") == nil ) then
					print("\27[31m Invalid path to DYNAMIC image\27[0m")
					return false 
				else 
					return true
				end
			else
				print("\27[31m The audioPassThruIcon is not received \27[0m")
				return false 
			end
		end)
  if
  (self.appHMITypes["NAVIGATION"]) == true or
  (self.appHMITypes["COMMUNICATION"]) == true or
  (self.isMediaApplication == true) then

    EXPECT_NOTIFICATION("OnHMIStatus",
      {hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
      {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
    :Times(2)
  else
    EXPECT_NOTIFICATION("OnHMIStatus"):Times(0)
  end

  self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruAppParALLDynamic, { success = true, resultCode = "SUCCESS"})
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
