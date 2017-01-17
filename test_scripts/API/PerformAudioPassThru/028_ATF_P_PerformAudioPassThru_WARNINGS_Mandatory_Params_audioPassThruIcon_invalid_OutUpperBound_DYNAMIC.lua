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
--1. Used preconditions
--1.1. Request is sent with audioPassThruIcon that is out of upper bound (actual Ubuntu limitation is 255 chars) and is with type DYNAMIC and with all mandatory parameters within bounds (samplingRate, maxDuration, bitsPerSample, audioType)
--2. Performed steps
-- Send PerformAudioPassThru (audioPassThruIcon out of upper bound, mandatory params) from mobile to SDL and check:
--2.1 SDL sends UI.PerformAudioPassThru (without audioPassThruIcon, mandatory params) to HMI
--2.2 SDL sends TTS.Speak to HMI
--2.3 HMI sends UI.PerformAudioPassThru (WARNINGS) to SDL
--2.4 HMI sends TTS.Speak (SUCCESS) to SDL
-- Expected result:
-- SDL sends PerformAudioPassThru (WARNINGS, success:true) to mobile app

---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPerformAudioPassThru = require('user_modules/shared_testcases/testCasesForPerformAudioPassThru')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable ()
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

commonSteps:PutFile("Precondition_PutFile_With_Icon", "icon.png")

function Test:Precondition_Check_audioPassThruIcon_Existence()
  testCasesForPerformAudioPassThru:Check_audioPassThruIcon_Existence(self)
end

function Test:Precondition_ActivateApp()
  testCasesForPerformAudioPassThru:ActivateAppDiffPolicyFlag
  (self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Mandatory_Params_audioPassThruIcon_OutUpperBound_DYNAMIC()
  local CorIdPerfAudioPassThruOnlyMandatory= self.mobileSession:SendRPC("PerformAudioPassThru",
    {
      samplingRate = "16KHZ",
      maxDuration = 2000,
      bitsPerSample = "8_BIT",
      audioType = "PCM", 
      audioPassThruIcon =
      { value = string.rep ("a", 65535).. ".png",
        imageType = "DYNAMIC"
      }      
    })

  -- hmi expects UI.PerformAudioPassThru request
  EXPECT_HMICALL("UI.PerformAudioPassThru",
    {
      appID = self.applications[applicationName],
      maxDuration = 2000,
      muteAudio = true
    })
  :Do(function(_,data)
  	if data.params.audioPassThruIcon ~= nil then 
  		print (" \27[36m Unexpected parameter received \27[0m")
  		return false 
  	end
        self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "WARNINGS", {})
    end)
  self.mobileSession:ExpectResponse(CorIdPerfAudioPassThruOnlyMandatory, { success = true, resultCode = "WARNINGS",
    })
end

--[[ Postconditions ]]

commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
