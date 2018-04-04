---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: PoliciesManager must provide data consent prompt from the policy table upon request from HMI
-- [HMI API] SDL.GetUserFriendlyMessage request/response
--
-- Description:
-- 1. Precondition: SDL is started
-- 2. Steps: HMI->SDL: SDL.GetUserFriendlyMessage_request {messageCodes, language}
--
-- Expected result:
-- 1.1. 'messageCodes' is an array of strings that represent the names of sub-sections of "consumer_friendly_messages" section in PT where SDL takes the data from (for example, "StatusNeeded", "StatusPending", "StatusUpToDate").
-- 1.2. 'language' - optional param, represents the language HMI needs the data in.
-- 2. SDL->HMI: SDL.GetUserFriendlyMessage_response {messages}:
-- 2.1. 'messages' is an array, each element of which contains the following params:
-- 2.1.1. 'messageCode' - is the name of sub-section of PT from the request
-- 2.1.2. 'ttsString' - is the value that SDL takes from PT ("tts" field from 'messageCode' subsection of "consumer_friendly_messages" section). SDL does not provide this param IN CASE the corresponding value does not exist in PT.
-- 2.1.3. 'label' - is the value that SDL takes from PT ("label" field from 'messageCode' subsection of "consumer_friendly_messages" section). SDL omits this param IN CASE the corresponding value does not exist in PT.
-- 2.1.4. 'line1' - is the value that SDL takes from PT ("line1" field from 'messageCode' subsection of "consumer_friendly_messages" section). SDL omits this param IN CASE the corresponding value does not exist in PT.
-- 2.1.5. 'line2' - is the value that SDL takes from PT ("line2" field from 'messageCode' subsection of "consumer_friendly_messages" section). SDL omits this param IN CASE the corresponding value does not exist in PT.
-- 2.1.6. 'textBody' - is the value that SDL takes from PT ("textBody" field from 'messageCode' subsection of "consumer_friendly_messages" section). SDL omits this param IN CASE the corresponding value does not exist in PT.
-- HMI->SDL: SDL.GetUserFriendlyMessage ("messageCodes": "AppPermissions")
-- SDL->HMI: SDL.GetUserFriendlyMessage ("messages":
-- {messageCode: "AppPermissions", ttsString: "%appName% is requesting the use of the following ....", line1: "Grant Requested", line2: "Permission(s)?"} ring: "%appName% is requesting the use of the following ....", line1: "Grant Requested", line2: "Permission(s)?"})
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--TODO(vvvakulenko): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_ActivateApp_StatusNeeded()

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function()
      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "DataConsent" }})

      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function()

          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})

          -- EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })

          EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{})
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
            end)

          local language_status_needed = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.StatusNeeded.languages.en-us.line1")
          local request_id_status_needed = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusNeeded" }})
          EXPECT_HMIRESPONSE(request_id_status_needed, { messages = { { messageCode = "StatusNeeded", line1 = language_status_needed }}})

        end)
    end)

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_, data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", { hmiLevel = "FULL", systemContext = "MAIN" })
end

function Test:TestStep_PTU_SUCCESS_StatusPending_StatusUpToDate()
  local SystemFilesPath = "/tmp/fs/mp/images/ivsu_cache/"

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATING" }, { status = "UP_TO_DATE" }):Times(2)
  :Do(function(exp,_)
      if(exp.occurences == 1) then
        local language_status_pending = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.StatusPending.languages.en-us.line1")
        local request_id_status_up_to_date = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusPending" }})
        EXPECT_HMIRESPONSE(request_id_status_up_to_date, { messages = { { messageCode = "StatusPending", line1 = language_status_pending }}})
      elseif (exp.occurences == 2) then
        local language_status_up_to_date = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("consumer_friendly_messages.messages.StatusUpToDate.languages.en-us.line1")
        local request_id_status_up_to_date = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusUpToDate" }})
        EXPECT_HMIRESPONSE(request_id_status_up_to_date, { messages = { { messageCode = "StatusUpToDate", line1 = language_status_up_to_date }}})
      end
    end)

  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId_GetUrls,{ result = { code = 0, method = "SDL.GetURLS" } })
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ requestType = "PROPRIETARY", fileName = "PolicyTableUpdate" })
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate" }, "files/ptu.json")
          EXPECT_HMICALL("BasicCommunication.SystemRequest",{ requestType = "PROPRIETARY", fileName = SystemFilesPath.."PolicyTableUpdate" })
          :Do(function(_, data)
              self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = SystemFilesPath.."PolicyTableUpdate" })
            end)
          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS" })
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
