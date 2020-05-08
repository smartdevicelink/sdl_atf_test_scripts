---------------------------------------------------------------------------------------------
-- Description:
-- 1. Preconditions: App is registered
-- 2. Steps: Activate App, send SDL.OnAllowSDLFunctionality with 'allowed=false' and without 'device' to HMI
-- Requirement summary:
-- [Policy] "EXTERNAL_PROPRIETARY" flow: Related HMI API
-- [Policies]: OnAllowSDLFunctionality with 'allowed=false' and without 'device' param from HMI
--
-- Expected result:
-- In case PoliciesManager receives SDL.OnAllowSDLFunctionality with 'allowed=false' and without 'device' param from HMI, PoliciesManager must record
-- all of currently registered devices as NOT consented in Local PT ("device_data" - > "<device_id_1>", "<device_id_2>", etc. - >"user_consent_records"- > "device" sub-section).
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ Local variables ]]
local device_consent
local device_consent_group

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General configuration parameters ]]
Test = require('connecttest')
require('cardinalities')
require('mobile_session')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, utils.getDeviceMAC())
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Allowed_false_without_device()

  device_consent_group = testCasesForPolicyTableSnapshot:get_data_from_PTS("app_policies.device.groups.1")
  device_consent = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records.device.consent_groups.DataConsent-2")
  if( (device_consent == nil) or (device_consent_group == nil)) then
    self:FailTestCase("Device is not consented after user consent.")
  elseif (device_consent_group ~= "DataConsent-2") then
    self:FailTestCase("app_policies.device.groups is not DataConsent-2.")
  elseif (device_consent) then
    if(device_consent ~= true) then
      self:FailTestCase("Device is not consented after user consent.")
    else
      self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
        {allowed = false, source = "GUI"})
    end
  end
end

function Test:TestStep_Check_Device_IsnotAllowed()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if (data.result.isSDLAllowed == true) then
        self:FailTestCase("Device is still consented after user disallowed access to it.")
      end
    end)
end

function Test:TestStep_Check_Device_IsNotAllowed_policDB()
  local device_consent_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select is_consented from device_consent_group")

  local device_consent1
  for _, value in pairs(device_consent_table) do
    device_consent1 = value
  end
  if(device_consent1 == "1") then
    self:FailTestCase("Device is consented after user consent.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
