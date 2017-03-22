---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PerformAudioPassThru] SDL must transfer request to HMI in case "audioPassThruIcon" param was omited in request from mobile app
-- [HMI API] UI.PerformAudioPassThru request/response
-- [Mobile API] PerformAudioPassThru request/response
-- [HMI_API] [MOBILE_API] The "audioPassThruIcon" param at "ImageFieldName" struct
--
-- Description:
-- In case mobile app sends PerformAudioPassThru_request to SDL 
-- without <audioPassThruIcon> parameter
-- and with another related to request valid params
-- SDL must transfer UI.PerformAudioPassThru (other params)_request + Speak_request (depends on parameters provided by the app) to HMI
-- 
-- 1. Used preconditions
-- 1.1. PerformAudioPassThru RPC is allowed by policy
-- 1.2. Request is sent without audioPassThruIcon and with all mandatory parameters within bounds (samplingRate, maxDuration, bitsPerSample, audioType)
--
-- 2. Performed steps
-- Send PerformAudioPassThru (without audioPassThruIcon, mandatory params) from mobile to SDL and check:
-- 
--
-- Expected result:
-- SDL sends UI.PerformAudioPassThru (without audioPassThruIcon, mandatory params) to HMI
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPostconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPerformAudioPassThru = require('user_modules/shared_testcases/testCasesForPerformAudioPassThru')
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

commonSteps:PutFile("Precondition_PutFile_With_Icon", "icon.png")

function Test:Precondition_Check_audioPassThruIcon_Existence()
  testCasesForPerformAudioPassThru.Check_audioPassThruIcon_Existence(self, "icon.png")
end

function Test:Precondition_ActivateApp()
  testCasesForPerformAudioPassThru:ActivateAppDiffPolicyFlag(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_ValidRequest_Without_audioPassThruIcon_Mandatory_Params_Present()
  local CorIdPerfAudioPassThruOnlyMandatory= self.mobileSession:SendRPC("PerformAudioPassThru",
    {
      samplingRate = "16KHZ",
      maxDuration = 2000,
      bitsPerSample = "8_BIT",
      audioType = "PCM"
    })

  EXPECT_HMICALL("UI.PerformAudioPassThru",
    {
      appID = self.applications[config.application1.registerAppInterfaceParams.appName],
      maxDuration = 2000,
      muteAudio = true
    })
  :Do(function(_,data)
  self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "WARNINGS", {})
  end)
    :ValidIf(function(_,data1)
    if data1.params.audioPassThruIcon ~= nil then 
      print (" \27[36m Unexpected parameter audioPassThruIcon received \27[0m")
      return false 
      else 
      print("No audioPassThruIcon sent as expected")
        return true 
    end
  end)

  EXPECT_HMICALL("TTS.Speak"):Times(0)
  self.mobileSession:ExpectResponse(CorIdPerfAudioPassThruOnlyMandatory, {success = true, resultCode = "WARNINGS"})
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
