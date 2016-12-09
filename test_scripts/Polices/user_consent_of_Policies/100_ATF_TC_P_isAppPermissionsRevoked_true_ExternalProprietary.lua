---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] SDL.ActivateApp from HMI and 'isAppPermissionsRevoked' parameter in the response
-- [Policies] Support of "EXTERNAL_PROPRIETARY" flow of Policies
-- [HMI API] SDL.ActivateApp
--
-- Description:
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- SDL receives request for app activation from HMI and LocalPT contains revoked permission for the named application
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
-- Activate app
--
-- Expected result:
-- PoliciesManager must respond with "isAppPermissionRevoked:true" and "AppRevokedPermissions" param containing the list of revoked permissions to HMI
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Local Variables ]]
local HMIAppID

--[[ General Precondition before ATF start ]]
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/GroupsForApp_preloaded_pt.json")
commonSteps:DeleteLogsFiles()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')
require('cardinalities')

--[[ Precondtions]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_user_request_update_from_HMI()
  testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
end

function Test:Precondition_PTU_revoke_app_group()
  HMIAppID = self.applications[config.application1.registerAppInterfaceParams.appName]
  print("HMIAppID1 = " ..HMIAppID)
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {{url = "http://policies.telematics.ford.com/api/policies"}}}})
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "filename"})

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/PTU_AppRevokedGroup.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})

              local function to_run()
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end
              RUN_AFTER(to_run, 500)
            end)

          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
          :Do(function(_,_)
              EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = HMIAppID, isAppPermissionsRevoked = true, appRevokedPermissions = {"DataConsent"}})
              :Do(function(_,_)
                  local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = HMIAppID })
                  EXPECT_HMIRESPONSE(RequestIdListOfPermissions)
                  :Do(function()
                      local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
                      EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage, { result = { code = 0, messages = {{ messageCode = "DataConsent"}}, method = "SDL.GetUserFriendlyMessage"}})
                    end)
                  self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
                end)
            end)
        end)
    end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Activate_app_isAppPermissionRevoked_true()
  print("HMIAppID2 = " ..HMIAppID)
  local RequestIdActivateAppAgain = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppID })
  EXPECT_HMIRESPONSE(RequestIdActivateAppAgain, { result = { code = 0, method = "SDL.ActivateApp", isAppRevoked = false, priority = "NONE"}})
  :Do(function(_,data)
      if data.result.isAppPermissionRevoked ~= true then
        commonFunctions:userPrint(31, "Wrong SDL behavior: isAppPermissionRevoked should be false for app with revoked group")
        return false
      else
        commonFunctions:userPrint(33, "isAppPermissionRevoked is true for app with revoked group - expected behavior")
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
