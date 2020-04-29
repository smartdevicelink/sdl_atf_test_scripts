---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] language of the message requested doesn't exist in LocalPT
-- [HMI API] SDL.GetUserFriendlyMessage request/response
--
-- Description:
-- HMI requests a language for a particular prompt via GetUserFriendlyMessage and the language("JA-JP") is not present in policy table
-- 1. Used preconditions:
-- Unregister default application
-- Register application
-- Activate application
--
-- 2. Performed steps
-- Perform PTU with nickname not from policy table
--
-- Expected result:
-- English ("en-us") prompt must be returned to HMI
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local variables ]]
local language = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.DataConsent.languages.en-us.tts")
local line1 = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.DataConsent.languages.en-us.line1")
local line2 = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.DataConsent.languages.en-us.line2")
local textBody = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.DataConsent.languages.en-us.textBody")
local label = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.DataConsent.languages.en-us.label")

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_GetUserFriendlyMessage_without_DE_DE.json")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_Activate_app_EN_US()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp",
    { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  if(language == 0) then language = nil end
  if(line1 == 0) then line1 = nil end
  if(line2 == 0) then line2 = nil end
  if(textBody == 0) then textBody = nil end
  if(label == 0) then label = nil end

  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if data.result.isSDLAllowed ~= true then
        local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestId1,
          { messages = {
              {messageCode = "DataConsent", ttsString = language, textBody = textBody, line1 = line1, line2 = line2, label = label}}})
        :Do(function(_,_)
            -- Do not allow SDL to have again message GetUserFriendlyMessage
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = false, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = false}})

          end)
      end
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_GetUserFriendlyMessage_DE_DE_missed_in_PT()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName] })
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if data.result.isSDLAllowed ~= true then
        local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "DE-DE", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestId1,
          { messages = {
              {messageCode = "DataConsent", ttsString = language, textBody = textBody, line1 = line1, line2 = line2}}})
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
