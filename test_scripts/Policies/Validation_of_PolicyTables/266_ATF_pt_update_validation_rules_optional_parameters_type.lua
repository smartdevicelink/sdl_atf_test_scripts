---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] At least one optional param has invalid type
--
-- Check SDL behavior in case optional parameter ith invalid type in received PTU
-- 1. Used preconditions:
-- Do not start default SDL
-- Prepare PTU file with with one optional field with invalid type
-- Start SDL
-- InitHMI register MobileApp
-- Perform PT update
--
-- 2. Performed steps:
-- Check LocalPT changes
--
-- Expected result:
-- SDL must invalidate this received PolicyTableUpdated and log corresponding error internally
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General configuration parameters ]]
Test = require('connecttest')
local config = require('config')
require('user_modules/AppTypes')
config.defaultProtocolVersion = 2

local function activateAppInSpecificLevel(self)
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  --hmi side: expect SDL.ActivateApp response
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      --In case when app is not allowed, it is needed to allow app
      if data.result.isSDLAllowed ~= true then
        --hmi side: sending SDL.GetUserFriendlyMessage request
        RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          {language = "EN-US", messageCodes = {"DataConsent"}})

        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,_)

            --hmi side: send request SDL.OnAllowSDLFunctionality
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})

            --hmi side: expect BasicCommunication.ActivateApp request
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,data2)

                --hmi side: sending BasicCommunication.ActivateApp response
                self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            -- :Times()
          end)
        EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN" })
      end
    end)
end

function Test:updatePolicyInDifferentSessions(_, appName, mobileSession)

  local iappID = self.applications[appName]
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"} )

      mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_,_)
          local CorIdSystemRequest = mobileSession:SendRPC("SystemRequest",
            {
              fileName = "PolicyTableUpdate",
              requestType = "PROPRIETARY",
              appID = iappID
            },
          "files/jsons/Policies/PTU_ValidationRules/PTU_invalid_optional.json")

          local systemRequestId
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,_data1)
              systemRequestId = _data1.id
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"} )
              local function to_run()
                self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end

              RUN_AFTER(to_run, 500)
            end)
          mobileSession:ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)

  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_ActivateAppInFULL()
  activateAppInSpecificLevel(self)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data3)
      self.hmiConnection:SendResponse(data3.id, data3.method, "SUCCESS", {})
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
end

function Test:TestStep_UpdatePolicy_ExpectOnAppPermissionChangedWithAppID()
  self:updatePolicyInDifferentSessions(nil,
    config.application1.registerAppInterfaceParams.appName,
    self.mobileSession)
end

function Test.Wait()
  os.execute("sleep 3")
end

function Test:TestStep_CheckSDLLogError()
  local log_file = "SmartDeviceLinkCore.log"
  local log_path = table.concat({ config.pathToSDL, "/", log_file })
  local is_test_fail = false

  local exp_msg = 'policy_table.policy_table.consumer_friendly_messages.messages%[\"AppPermissionsRevoked\"%].languages%[\"de%-de\"%].tts: value initialized incorrectly'
  local result = commonFunctions:read_specific_message(log_path, exp_msg)
  if(result == false) then
    commonFunctions:printError("Error: message 'policy_table.policy_table.consumer_friendly_messages.messages[\"AppPermissionsRevoked\"].languages[\"de-de\"].tts: value initialized incorrectly' is not observed in smartDeviceLink.log.")
    is_test_fail = true
  end

  exp_msg = "policy_table.policy_table.module_config.certificate: value initialized incorrectly"
  result = commonFunctions:read_specific_message(log_path, exp_msg)
  if(result == false) then
    commonFunctions:printError("Error: message 'policy_table.policy_table.module_config.certificate: value initialized incorrectly' is not observed in smartDeviceLink.log.")
    is_test_fail = true
  end

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
