---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]:Storage of user-consent for device in LocalPT
--
-- Description:
-- Storing by Policies Manager user consent for device
-- 1. Used preconditions:
-- SDL and HMI are running
-- Local PT does not have user_consent_records for <Device>
-- <Device> is connected, <App> is running on that device
-- <App> is registered with SDL and is present in HMI list of registered apps
-- 2. Performed steps:
-- Activate App -> consent device on HMI
-- Check local pt for device consent
--
-- Expected result:
-- PoliciesManager must store the User`s consent for device (data consent) records in "device" subsection of "user_consent_records" subsection
-- of "<device_identifier>" section of "device_data" section in Local PT:
-- Step1:
-- HMI->SDL: SDL.ActivateApp {appID}
-- SDL->HMI: SDL.ActivateApp_response{isPermissionsConsentNeeded: true, params}
-- HMI->SDL: GetUserFriendlyMessage{params},
-- SDL->HMI: GetUserFriendlyMessage_response{params}
-- HMI: display the 'data consent' message
-- Step2:
-- HMI->SDL: SDL.OnAllowSDLFunctionality(isSDLAllowed=true)
-- PoliciesManager records the consent-related information in "device" subsection of "user_consent_records" subsection
-- of "<device_identifier>" section of "device_data" section in Local PT.
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

function Test:TestStep1_Device_consent_on_activate_app()
  local RequestIdActivate = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestIdActivate, {result = { code = 0, device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() }, isSDLAllowed = false, method ="SDL.ActivateApp"}})
  :Do(function()
      local RequestIdGetMes = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetMes, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function()
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true }})
        end)
    end)
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

function Test:TestStep2_check_LocalPT_for_consent_storage()
  local test_fail = false
  local data_consent = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records.device.consent_groups.DataConsent-2")
  print("data_consent = " ..tostring(data_consent))

  if(data_consent ~= true) then
    commonFunctions:printError("Error: consent_groups.DataConsent-2 for device should be true")
    test_fail = true
  end
  if(test_fail == true) then
    self:FailTestCase("Test failed. See prints")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
