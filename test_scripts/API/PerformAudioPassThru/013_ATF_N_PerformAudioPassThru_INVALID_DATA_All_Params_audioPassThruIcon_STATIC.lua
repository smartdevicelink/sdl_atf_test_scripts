---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PerformAudioPassThru] SDL must transfer request to HMI in case of valid "audioPassThruIcon" param
-- [GeneralResultCodes] INVALID_DATA wrong characters
-- [GeneralResultCodes] INVALID_DATA empty String parameter
-- [GeneralResultCodes] INVALID_DATA wrong type
-- [GeneralResultCodes] INVALID_DATA out of bounds
-- [Mobile API] PerformAudioPassThru request/response
-- [HMI_API] [MOBILE_API] The "audioPassThruIcon" param at "ImageFieldName" struct
--
-- Description:
-- In case that the request comes with
-- '\n' and-or '\t' and-or 'whitespace'-as-the-only-symbol(s) at any "String" type parameter in the request structure,
-- or with empty value"" in "String" type parameters (including parameters of the structures)
-- or wrong type parameters (including parameters of the structures)
-- or out-of-bounds parameters values of any type
-- SDL must respond with resultCode "INVALID_DATA" and success:"false"
--
-- 1. Used preconditions
-- 1.1. Request is sent with audioPassThruIcon image structure with invalid value parameter
-- and ImageType = STATIC, all other params used in PerformAudioPassThru_request
-- are present and within bounds
--
-- 2. Performed steps
-- Send PerformAudioPassThru (audioPassThruIcon (invalid value parameter,ImageType = STATIC), other params) from mobile to SDL and check:
--
-- Expected result:
-- SDL sends PerformAudioPassThru (INVALID_DATA, success:false) to mobile app
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

--[[ Local variables ]]
local params_invalid_data =
{
  {param_value = " ", comment = "audioPassThruIcon_only_whitespaces"}, -- audioPassThruIcon contains only whitespaces in value parameter
  {param_value = "iconvalue\newlinechar", comment = "audioPassThruIcon_new_line_char"}, -- audioPassThruIcon contains new line character in value parameter
  {param_value = "iconvalue\ttabchar", comment = "audioPassThruIcon_tab_char"}, -- audioPassThruIcon contains tab character in value parameter
  {param_value = "", comment = "audioPassThruIcon_empty"}, -- audioPassThruIcon with empty value parameter
  {param_value = 123, comment = "audioPassThruIcon_wrong_type"}, --audioPassThruIcon contains wrong type (integer instead of string) in value parameter
  {param_value = string.rep ("a", 65535).. ".png", comment = "audioPassThruIcon_out_upper_bound"} -- audioPassThruIcon contains out of upper bound value parameter
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

for ind = 1, #params_invalid_data do
  Test["TestStep"..ind.."_"..params_invalid_data[ind].comment.."_all_params_STATIC"] = function(self)
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
          value = params_invalid_data[ind].param_value,
          imageType = "STATIC"
        }
      })

    EXPECT_HMICALL("TTS.Speak"):Times(0)

    EXPECT_HMICALL("UI.PerformAudioPassThru"):Times(0)

    self.mobileSession:ExpectResponse(CorIdPerformAudioPassThruAppParVD, {success = false, resultCode = "INVALID_DATA"})
    commonTestCases:DelayedExp(10000)
    EXPECT_NOTIFICATION("OnHashChange"):Times(0)
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
