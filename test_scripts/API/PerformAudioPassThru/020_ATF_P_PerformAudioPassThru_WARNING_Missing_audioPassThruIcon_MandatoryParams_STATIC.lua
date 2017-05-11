---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PerformAudioPassThru] "audioPassThruIcon" does NOT exist at 'AppStorageFolder'
-- [HMI API] UI.PerformAudioPassThru request/response
-- [Mobile API] PerformAudioPassThru request/response
-- [HMI_API] [MOBILE_API] The "audioPassThruIcon" param at "ImageFieldName" struct
--
-- Description:
-- In case mobile app sends PerformAudioPassThru_request to SDL 
-- with valid <audioPassThruIcon> parameter
-- and the requested <audioPassThruIcon> does NOT exist at app`s sandbox
-- and with another related to request valid mandatory params
-- transfer UI.PerformAudioPassThru (<audioPassThruIcon>, other params)_request + Speak_request (depends on parameters provided by the app) to HMI
-- respond with <resultCode_received_from_HMI> + <info> to mobile app (expected resultCode from HMI is "WARNINGS" and info: "Reference image(s) not found" 
-- as described in [CTR] Conditions for SDL to handle case when requested <Image> does not exist at "AppStorageFolder"
--
-- 1. Used preconditions
-- 1.1. PerformAudioPassThru RPC is allowed by policy
-- 1.2. audioPassThruIcon does not exist in created by app AppStorageFolder
-- 1.3. Request is sent with valid audioPassThruIcon parameter with type STATIC, all mandatory params used in PerformAudioPassThru_request are present and within bounds 
--
-- 2. Performed steps
-- Send PerformAudioPassThru (audioPassThruIcon, mandatory params)
-- HMI sends UI.PerformAudioPassThru (WARNINGS, info) to SDL
--
-- Expected result:
-- SDL sends UI.PerformAudioPassThru to HMI
-- SDL sends PerformAudioPassThru (WARNINGS, success:true, info:Reference image(s) not found) to mobile app
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPostconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPerformAudioPassThru = require('user_modules/shared_testcases/testCasesForPerformAudioPassThru')
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

function Test:TestStep_Mandatory_Params_Missing_audioPassThruIcon_STATIC()
  local CorIdPerformAudioPassThruAppParVD= self.mobileSession:SendRPC("PerformAudioPassThru",
    {
      samplingRate = "16KHZ",
      maxDuration = 2000,
      bitsPerSample = "8_BIT",
      audioType = "PCM",
      audioPassThruIcon =
      { 
        value = "icon.png",
        imageType = "STATIC"
      }      
    })

  EXPECT_HMICALL("UI.PerformAudioPassThru",
    {
      appID = self.applications[config.application1.registerAppInterfaceParams.appName],
      maxDuration = 2000,
      muteAudio = true,
      audioPassThruIcon =
      { 
        value = "icon.png",
        imageType = "STATIC"
      }  
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "WARNINGS",{info = "Reference image(s) not found"})
  end)

  EXPECT_HMICALL("TTS.Speak"):Times(0)
  self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruAppParVD, {success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
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
