---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PerformAudioPassThru] SDL must transfer request to HMI in case of valid "audioPassThruIcon" param
-- [HMI API] UI.PerformAudioPassThru request/response
-- [Mobile API] PerformAudioPassThru request/response
-- [HMI_API] [MOBILE_API] The "audioPassThruIcon" param at "ImageFieldName" struct
--
-- Description:
-- In case mobile app sends PerformAudioPassThru_request to SDL with:
-- valid <audioPassThruIcon> parameter
-- and the requested <audioPassThruIcon> exists at app`s sandbox (see AppStorageFolder section)
-- as well as another related to request valid mandatory params
-- SDL must transfer UI.PerformAudioPassThru (<audioPassThruIcon>, other params)_request + Speak_request (depends on parameters provided by the app) to HMI
--
-- 1. Used preconditions
-- 1.1. PerformAudioPassThru RPC is allowed by policy
-- 1.2. Only mandatory parameters are present and within bounds (samplingRate, maxDuration, bitsPerSample, audioType), 
-- audioPassThruIcon is sent with imageType = "DYNAMIC"
-- 1.3. AudioPassThruIcon exists at apps sub-directory of AppStorageFolder (value from ini file)
--
-- 2. Performed steps
-- Send PerformAudioPassThru (audioPassThruIcon, mandatory params) from mobile to SDL and check:
--
-- Expected result:
-- SDL sends UI.PerformAudioPassThru (audioPassThruIcon (imageType = "DYNAMIC"), mandatory params) to HMI
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPostconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPerformAudioPassThru = require('user_modules/shared_testcases/testCasesForPerformAudioPassThru')
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

commonSteps:PutFile("Precondition_PutFile_With_Icon","icon.png")

function Test:Precondition_Check_audioPassThruIcon_Existence()
  testCasesForPerformAudioPassThru.Check_audioPassThruIcon_Existence(self, "icon.png")
end

function Test:Precondition_ActivateApp()
  testCasesForPerformAudioPassThru:ActivateAppDiffPolicyFlag(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PerformAudioPassThru_MandatoryParameters_audioPassThruIcon_DYNAMIC_SUCCESS()
  local CorIdPerfAudioPassThruOnlyMandatoryDYNAMIC= self.mobileSession:SendRPC("PerformAudioPassThru",
    {
      samplingRate = "22KHZ",
      maxDuration = 500500,
      bitsPerSample = "16_BIT",
      audioType = "PCM",
      audioPassThruIcon =
      { 
        value = "icon.png",
        imageType = "DYNAMIC"
      }
    })

  EXPECT_HMICALL("UI.PerformAudioPassThru",
    {
      audioPassThruIcon = { imageType = "DYNAMIC" },		
      appID = self.applications[config.application1.registerAppInterfaceParams.appName],
      maxDuration = 500500,
      muteAudio = true
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
    end)
   :ValidIf (function(_,data3)
      if(data3.params.audioPassThruIcon ~= nil) then
        if (string.match(data3.params.audioPassThruIcon.value, "%S*" .. "("..string.sub(storagePath, 2).."icon.png)" .. "$") == nil ) then
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
  
  EXPECT_HMICALL("TTS.Speak"):Times(0)
  self.mobileSession:ExpectResponse(CorIdPerfAudioPassThruOnlyMandatoryDYNAMIC, {success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHashChange"):Times(0)
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
