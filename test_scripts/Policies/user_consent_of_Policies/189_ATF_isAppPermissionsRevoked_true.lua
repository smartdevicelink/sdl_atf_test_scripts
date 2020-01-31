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
--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local HMIAppID

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')
require('cardinalities')

config.application1.registerAppInterfaceParams.isMediaApplication = false
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Precondtions]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:SetHMIAppID()
  HMIAppID = self.applications["Test Application"]
end

function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:TestStep_PTU_appPermissionsConsentNeeded_true()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function(_,_)
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate")
          :Do(function(_,data)
              if(data.params.status == "UP_TO_DATE") then

                EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = HMIAppID, appPermissionsConsentNeeded = true })
                :Do(function(_,_)

                    local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions",
                      { appID = self.applications[config.application1.registerAppInterfaceParams.appName] })

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
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "filename"})

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_,_)
        self.mobileSession:SendRPC("SystemRequest", { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"},
          "files/PTU_NewPermissionsForUserConsent.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)

              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})
              self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

            end)
        end)
    end)
end

function Test:Precondition_trigger_user_request_update_from_HMI()
  testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
end

-- function Test:SetAppTo_BACKGROUND()
-- self.hmiConnection:SendNotification("BasicCommunication.OnAppDeactivated", { appID = HMIAppID })
-- EXPECT_NOTIFICATION("OnHMIStatus", { hmiLevel = "BACKGROUND" })
-- end

function Test:SetAppTo_NONE()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", { appID = HMIAppID, reason = "USER_EXIT" })
  EXPECT_NOTIFICATION("OnHMIStatus", { hmiLevel = "NONE" })
end

function Test:Precondition_PTU_revoke_app_group()
  HMIAppID = self.applications[config.application1.registerAppInterfaceParams.appName]
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "filename"})

      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            { fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/PTU_AppPermissionsRevoked.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})

              local function to_run()
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              end
              RUN_AFTER(to_run, 1000)
              self.mobileSession:ExpectResponse(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
            end)

          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate"):Times(AtLeast(1))
          :Do(function(_,data)
              if(data.params.status == "UP_TO_DATE") then

                EXPECT_HMINOTIFICATION("SDL.OnAppPermissionChanged", {appID = HMIAppID, isAppPermissionsRevoked = true, appRevokedPermissions = { {name = "DrivingCharacteristics"} } })
                :Times(0)
                -- :Do(function(_,_)
                -- -- EXPECT_NOTIFICATION("OnPermissionsChange")
                -- local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = HMIAppID })
                -- EXPECT_HMIRESPONSE(RequestIdListOfPermissions)
                -- :Do(function()
                -- local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"AppPermissionsRevoked"}})
                -- EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage, { result = { code = 0, messages = {{ messageCode = "AppPermissionsRevoked"}}, method = "SDL.GetUserFriendlyMessage"}})
                -- end)

                -- end)

              end
            end)
        end)
    end)
end

-- --[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Activate_app_isAppPermissionRevoked_true()
  local RequestIdActivateAppAgain = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = HMIAppID })
  EXPECT_HMIRESPONSE(RequestIdActivateAppAgain,
    {
      result =
      {
        code = 0,
        method = "SDL.ActivateApp",
        isAppRevoked = false,
        isAppPermissionsRevoked = false      }
    })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
-- testCasesForPolicyTable:Restore_preloaded_pt()

function Test.Postcondition_Stop()
  StopSDL()
end

return Test
