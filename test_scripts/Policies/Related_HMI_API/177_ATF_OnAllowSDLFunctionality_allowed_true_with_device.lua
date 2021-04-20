---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: OnAllowSDLFunctionality with 'allowed=true' and with 'device' param from HMI
--
-- Description:
-- 1. Preconditions: App is registered
-- 2. Steps: Activate App, send SDL.OnAllowSDLFunctionality with 'allowed=true' and with 'device' to HMI
--
-- Expected result:
-- app->SDL: RegisterAppInterface
-- SDL->HMI: OnAppRegistered (appID)
-- PoliciesManager: device needs consent; app is not present in Local PT.
-- PoliciesManager: "<appID>": "pre_DataConsent" //that is, adds appID to the Local PT and assigns default policies to it
-- SDL->HMI: SDL.OnSDLConsentNeeded
-- HMI->SDL: SDL.GetUserFriendlyMessages ("DataConsent")
-- SDL->HMI: SDL.GetUserFriendlyMessages_response
-- HMI displays the device consent pormpt. User makes choice.
-- HMI->SDL: OnAllowSDLFunctionality
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_ActivateApp_allowed_true_with_device()
  local device_consent
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)

      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      --hmi side: expect SDL.GetUserFriendlyMessage message response
      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})
        end)

      EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{})
      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
          testCasesForPolicyTableSnapshot:extract_pts({self.applications[config.application1.registerAppInterfaceParams.appName]})
          device_consent = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records.device.consent_groups.DataConsent-2")

          if(device_consent ~= true) then
            self:FailTestCase("Device is not consented after user consented it.")
          end
        end)
    end)

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
