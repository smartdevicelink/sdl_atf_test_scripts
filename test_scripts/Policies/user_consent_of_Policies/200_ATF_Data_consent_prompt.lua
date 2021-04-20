---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: PoliciesManager must provide data consent prompt from the policy table upon request from HMI
--
-- Description:
-- HMI requests from SDL user friendly message for data consent
-- 1. Used preconditions:
-- Unregister default application
-- Register application
--
-- 2. Performed steps
-- Activate application
--
-- Expected result:
-- PoliciesManager must provide user prompt/message from the policy table ("messages" under “consumer_friendly_messages”,
-- sub-sections of <message code> section which name corresponds to the value of messageCodes param of
-- SDL.GetUserFriendlyMessage request
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/PTU_GetUserFriendlyMessage_without_DE_DE.json")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:GetUserFriendlyMessage_data_consent_prompt()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName] })
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
    if data.result.isSDLAllowed ~= true then
      local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage,
        { messages = { {messageCode = "DataConsent"}}})
      :Do(function(_,_)
        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
          {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})
      end)
    end
  end)
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
