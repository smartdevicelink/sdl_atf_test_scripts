---------------------------------------------------------------------------------------------
-- Description:
-- 1. Preconditions: SDL and HMI are running. Local PT contains in "appID_1" section: "groupName_11", "groupName_12" groups;
-- and in "appID_2" section: "groupName_21", "groupName_22" groups;
-- 2. Performed steps: 1. Send SDL.GetListOfPermissions {appID_1}, From HMI: SDL->HMI: GetListOfPermissions {allowedFunctions:
--
-- Requirement summary:
-- [Policies] GetListOfPermissions with appID
-- [HMI API] GetListOfPermissions request/response
--
-- Expected result:
-- On getting SDL.GetListOfPermissions with appID parameter, PoliciesManager must respond with the list of <groupName>s
-- that have the field "user_consent_prompt" in corresponding <functional grouping> and are assigned to the currently registered applications (section "<appID>" -> "groups")
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ Local Functions ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/DeviceConsentedAndAppPermissionsForConsent_preloaded_pt.json")
--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_GetListOfPermissions_with_appID()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  --Allow SDL functionality
  EXPECT_HMIRESPONSE(RequestId,{ result = { code = 0, method = "SDL.ActivateApp", isPermissionsConsentNeeded = true}})
  :Do(function(_,data)
      if(data.result.isSDLAllowed == false) then
        local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})
          end)
      end

      if (data.result.isPermissionsConsentNeeded == true) then
        local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
        EXPECT_HMIRESPONSE(RequestIdListOfPermissions,{result = {code = 0, method = "SDL.GetListOfPermissions",
              --TODO(istoimenova): id should be read from policy.sqlite
              -- allowed: If ommited - no information about User Consent is yet found for app.
              allowedFunctions = {{ name = "DrivingCharacteristics", id = 4734356}}}})
        :Do(function()
            local ReqIDGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
              {language = "EN-US", messageCodes = {"AppPermissions"}})

            EXPECT_HMIRESPONSE(ReqIDGetUserFriendlyMessage,
              { result = { code = 0, messages = {{ messageCode = "AppPermissions"}}, method = "SDL.GetUserFriendlyMessage"}})
            :Do(function(_,_)
                self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent",
                  { appID = self.applications[config.application1.registerAppInterfaceParams.appName],
                    consentedFunctions = {{ allowed = true, id = 4734356, name = "DrivingCharacteristics"}}, source = "GUI"})
                EXPECT_NOTIFICATION("OnPermissionsChange")
              end)

          end)
      else
        commonFunctions:userPrint(31, "Wrong SDL bahavior: there are app permissions for consent, isPermissionsConsentNeeded should be true")
        return false
      end
    end)
end

-- Triger PTU to update sdl snapshot
function Test:TestStep_trigger_user_request_update_from_HMI()
  self.hmiConnection:SendNotification("SDL.OnPolicyUpdate", {} )

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{})
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)
end

function Test:TestStep_verify_PermissionConsent()
  local app_permission = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records."..config.application1.registerAppInterfaceParams.fullAppID..".consent_groups.DrivingCharacteristics-3")
  if(app_permission ~= true) then
    self:FailTestCase("DrivingCharacteristics-3 is not assigned to application, real: " ..app_permission)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
