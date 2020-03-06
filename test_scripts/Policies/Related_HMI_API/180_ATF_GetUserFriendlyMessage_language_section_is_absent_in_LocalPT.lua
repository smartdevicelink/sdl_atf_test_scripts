---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: GetUserFriendlyMessage Local PT does not contain section of requested language value
-- [HMI API] SDL.GetUserFriendlyMessage request/response
--
-- Description:
-- 1. Precondition: stop SDL, backup sdl_preloaded_pt.json, rewrite sdl_preloaded_pt.json with PTU_GetUserFriendlyMessage_without_DE_DE.json.
-- 2. Steps: Start SDL, Activate App, in SDL.GetUserFriendlyMessage parameter language = "de-de".
--
-- Expected result:
-- HMI->SDL: SDL.GetUserFriendlyMessage ("messageCodes": "AppPermissions")
-- SDL->HMI: SDL.GetUserFriendlyMessage ("messages": {messageCode: "AppPermissions", ttsString: "%appName% is requesting the use of the following ....", line1: "Grant Requested", line2: "Permission(s)?"})
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_GetUserFriendlyMessage_without_DE_DE.json")

--TODO(vvvakulenko): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_ActivateApp_language_section_in_localPT()
  local language = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.AppPermissions.languages.en-us.tts")
  local line1 = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.AppPermissions.languages.en-us.line1")
  local line2 = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.AppPermissions.languages.en-us.line2")
  local textBody = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.AppPermissions.languages.en-us.textBody")

  local request_id = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(request_id)
  :Do(function(_,_)

      local request_id_get_user_friendly_message = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
        {language = "DE-DE", messageCodes = {"AppPermissions"}})
      EXPECT_HMIRESPONSE(request_id_get_user_friendly_message,
        { messages = {
            {messageCode = "AppPermissions", ttsString = language, textBody = textBody, line1 = line1, line2 = line2}}})
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
