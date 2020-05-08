---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: User consent storage in LocalPT (OnAppPermissionConsent without appID)
-- [HMI API] OnAppPermissionConsent notification
--
-- Description:
-- 1. Used preconditions:
-- SDL and HMI are running
-- <Device> is connected to SDL and consented by the User, <App> is running on that device.
-- <App> is registered with SDL and is present in HMI list of registered aps.
-- Local PT has permissions for <App> that require User`s consent
-- 2. Performed steps: Activate App
--
-- Expected result:
-- 1. HMI->SDL: SDL.ActivateApp {appID}
-- 2. SDL->HMI: SDL.ActivateApp_response{isPermissionsConsentNeeded: true, params}
-- 3. HMI->SDL: GetUserFriendlyMessage{params},
-- 4. SDL->HMI: GetUserFriendlyMessage_response{params}
-- 5. HMI->SDL: GetListOfPermissions{appID}
-- 6. SDL->HMI: GetListOfPermissions_response{}
-- 7. HMI: display the 'app permissions consent' message.
-- 8. The User allows or disallows definite permissions.
-- 9. HMI->SDL: OnAppPermissionConsent {params}
-- 10. PoliciesManager: update "<appID>" subsection of "user_consent_records" subsection of "<device_identifier>" section of "device_data" section in Local PT
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyAppIdManagament = require("user_modules/shared_testcases/testCasesForPolicyAppIdManagament")
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

function Test:UpdatePolicy()
  testCasesForPolicyAppIdManagament:updatePolicyTable(self, "files/jsons/Policies/Related_HMI_API/OnAppPermissionConsent_ptu.json")
end

function Test:Precondition_ExitApplication()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications["Test Application"], reason = "USER_EXIT"})
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_User_consent_on_activate_app()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  EXPECT_HMIRESPONSE(RequestId,{ isPermissionsConsentNeeded = true })
  :Do(function(_,_)

      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"Notifications", "Location"}})
      --hmi side: expect SDL.GetUserFriendlyMessage message response
      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)

          local request_id_list_of_permissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = nil })
          EXPECT_HMIRESPONSE(request_id_list_of_permissions)
          :Do(function(_,data)
              local groups = {}
              if #data.result.allowedFunctions > 0 then
                for i = 1, #data.result.allowedFunctions do
                  print(data.result.allowedFunctions[i].name)
                  groups[i] = {
                    name = data.result.allowedFunctions[i].name,
                    id = data.result.allowedFunctions[i].id,
                    allowed = true}
                end
              end
              self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
                consentedFunctions = groups,
                source = "GUI",
                appID = nil
              })
              EXPECT_NOTIFICATION("OnPermissionsChange")
            end)

        end)
    end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end


function Test:TestStep_check_LocalPT_for_updates()
  local RequestId = self.hmiConnection:SendRequest("SDL.UpdateSDL", {} )
  EXPECT_HMIRESPONSE(RequestId, { result = { result = "UPDATE_NEEDED" }})

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{})
  :Do(function(_,data)
      local is_test_fail = false
      local app_consent_location = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records."..config.application1.registerAppInterfaceParams.fullAppID..".consent_groups.Location-1")
      local app_consent_notifications = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records."..config.application1.registerAppInterfaceParams.fullAppID..".consent_groups.Notifications")

      if(app_consent_location ~= true) then
        commonFunctions:printError("Error: consent_groups.Location function for appID should be true")
        is_test_fail = true
      end

      if(app_consent_notifications ~= true) then
        commonFunctions:printError("Error: consent_groups.Notifications function for appID should be true")
        is_test_fail = true
      end
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})

      if(is_test_fail == true) then
        self:FailTestCase("Test is FAILED. See prints.")
      end
    end)
end


--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
