---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: User-consent "YES"
-- [Mobile API] OnPermissionsChange notification
-- [HMI API] OnAppPermissionConsent notification
--
-- Description:
-- SDL gets user consent information from HMI
-- 1. Used preconditions:
-- Delete log files and policy table from previous cycle
-- Close current connection
-- Backup preloaded PT
-- Overwrite preloaded with specific groups for app
-- Connect device
-- Register app
--
-- 2. Performed steps
-- Activate app
--
-- Expected result:
-- SDL must notify an application about the current permissions active on HMI via onPermissionsChange() notification
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/DeviceConsentedAndAppPermissionsForConsent_preloaded_pt.json")
--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Preconditions")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:IsPermissionsConsentNeeded_false_on_app_activation()
  local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  --Allow SDL functionality
  EXPECT_HMIRESPONSE(RequestId,{ result = { code = 0, method = "SDL.ActivateApp", isPermissionsConsentNeeded = true, isSDLAllowed = true}})
  :Do(function(_,data)
      if(data.result.isSDLAllowed == false) then
        local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = ServerAddress, isSDLAllowed = true}})
          end)
      end

      if (data.result.isPermissionsConsentNeeded == true) then
        local RequestIdListOfPermissions = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", { appID = self.HMIAppID })
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
                EXPECT_NOTIFICATION("OnPermissionsChange",
                  {permissionItem = {
                      {rpcName = "GetVehicleData", hmiPermissions = {allowed = true, userDisallowed = false}, parameterPermissions = {allowed = true, userDisallowed = false} }}})
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
  testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
end

function Test:TestStep_verify_PermissionConsent()
  local app_permission = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..config.deviceMAC..".user_consent_records."..config.application1.registerAppInterfaceParams.appID..".consent_groups.DrivingCharacteristics-3")
  if(app_permission ~= true) then
    self:FailTestCase("DrivingCharacteristics-3 is not assigned to application, real: " ..app_permission)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
