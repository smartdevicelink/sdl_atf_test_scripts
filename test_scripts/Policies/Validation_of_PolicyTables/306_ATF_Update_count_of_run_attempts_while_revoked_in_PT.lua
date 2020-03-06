---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and "count_of_run_attempts_while_revoked" update
--
-- Description:
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Incrementing value in 'count_of_run_attempts_while_revoked' section of LocalPT
-- 1. Used preconditions:
-- Delete SDL log file and policy table
-- Close current connection
-- Make backup copy of preloaded PT
-- Overwrite preloaded PT adding list of groups for specific app
-- Connect device
-- Register app
-- Revoke app group by PTU
--
-- 2. Performed steps
-- Activate revoked app
-- Check "count_of_run_attempts_while_revoked" value of LocalPT
--
-- Expected result:
-- PoliciesManager increments "count_of_run_attempts_while_revoked" at PolicyTable
---------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local HMIAppID
local appID = "0000001"
local countOfActivationTries = 3

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')
require('cardinalities')

--[[ Precondtions]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:TestStep_PTU_appPermissionsConsentNeeded_true()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
  :Do(function(_,data)
      if(data.params.status == "UP_TO_DATE") then

        EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged",
          {appID = self.applications[config.application1.registerAppInterfaceParams.appName], appPermissionsConsentNeeded = true })
        :Do(function(_,_)
            local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions",
              { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

            EXPECT_HMIRESPONSE(RequestIdListOfPermissions)
            :Do(function(_,data1)
                local groups = {}
                if #data1.result.allowedFunctions > 0 then
                  for i = 1, #data1.result.allowedFunctions do
                    groups[i] = {
                      name = data1.result.allowedFunctions[i].name,
                      id = data1.result.allowedFunctions[i].id,
                      allowed = true}
                  end
                end
                self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", { appID = self.applications[config.application1.registerAppInterfaceParams.appName], consentedFunctions = groups, source = "GUI"})
                EXPECT_NOTIFICATION("OnPermissionsChange")
              end)
          end)
      end
    end)
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "filename"})

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_,_)
          self.mobileSession:SendRPC("SystemRequest", { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"},
          "files/PTU_NewPermissionsForUserConsent.json")

          local systemRequestId
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              systemRequestId = data.id
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})

              local function to_run()
                self.hmiConnection:SendResponse(systemRequestId,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end
              RUN_AFTER(to_run, 500)
            end)

        end)
    end)
end

function Test:Precondition_trigger_user_request_update_from_HMI()
  testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
end

function Test:Precondition_PTU_revoke_app()
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
  :Do(function(_,data)
      if(data.params.status == "UP_TO_DATE") then
        EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged")
        :Do(function(_,_)
            local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = HMIAppID })
            EXPECT_HMIRESPONSE(RequestIdListOfPermissions)
            :Do(function()
                local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"AppPermissionsRevoked"}})
                EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage, { result = { code = 0, messages = {{ messageCode = "AppPermissionsRevoked"}}, method = "SDL.GetUserFriendlyMessage"}})
              end)
          end)
      end
    end)
  HMIAppID = self.applications[config.application1.registerAppInterfaceParams.appName]
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "filename"})

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/PTU_AppRevokedGroup.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})

              local function to_run()
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end
              RUN_AFTER(to_run, 500)
              self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
            end)
        end)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

for i = 1, countOfActivationTries do
  Test["TestStep_Activate_app_isAppPermissionRevoked_true_" .. i] = function(self)
    local RequestIdActivateAppAgain = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName] })
    EXPECT_HMIRESPONSE(RequestIdActivateAppAgain, { result = { isAppRevoked = true}})
    os.execute("sleep 3")
  end
end

function Test:TestStep_Check_count_of_run_attempts_while_revoked_incremented_in_PT()
  local query = "select count_of_run_attempts_while_revoked from app_level where application_id = '" .. appID .. "'"
  local CountOfAttemptsWhileRevoked = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", query)[1]
  if CountOfAttemptsWhileRevoked == tostring(countOfActivationTries) then
    return true
  else
    self:FailTestCase("Wrong count_of_run_attempts_while_revoked. Expected: " .. countOfActivationTries .. ", Actual: " .. CountOfAttemptsWhileRevoked)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

testCasesForPolicyTable:Restore_preloaded_pt()

function Test.Postcondition_StopSDL()
  StopSDL()
end
