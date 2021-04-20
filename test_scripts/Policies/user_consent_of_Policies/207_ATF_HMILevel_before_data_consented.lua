---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: HMI Level assignment in case user did not accept the Data Consent prompt
--
-- Description:
-- HMI status assigning if user did not accept the Data Consent prompt, all registered apps shall be given an HMI status
-- PoliciesManager has not yet received the User`s response on data consent prompt for the corresponding device
-- 1. Used preconditions:
-- Delete log files and policy table
-- Close current connection
-- Overwrite preloaded PT with BACKGROUNG as default_hmi for pre_DataConsent
-- Connect unconsented device
-- Register application
-- 2. Performed steps
-- Activate application
-- Press "NO" for data consent on HMI
--
-- Expected result:
-- Registered app should be given HMI status of 'default_hmi' from "pre_dataConsent" section->
-- Step1:
-- HMI->SDL: SDL.ActivateApp{appID}
-- SDL->HMI: SDL.ActivateApp_response{isSDLAllowed: false, params}
-- HMI->SDL: GetUserFriendlyMessage{params},
-- SDL->HMI: GetUserFriendlyMessage_response{params}
-- HMI: display the 'data consent' message
-- Step2:
-- HMI->SDL: OnAllowSDLFunctionality {allowed: false, params}
-- SDL->app: OnPermissionChanged{params}// "pre_DataConsent" sub-section of "app_policies" section of PT, app`s HMI level corresponds to one from "default_hmi" field
-------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:ActivateApp_on_unconsented_device()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId,
    {result = { code = 0,
        device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() },
        isAppPermissionsRevoked = false, isAppRevoked = false, isSDLAllowed = false, isPermissionsConsentNeeded = false, method ="SDL.ActivateApp"}})
  :Do(function(_,data)
      --Consent for device is needed
      if data.result.isSDLAllowed ~= false then
        commonFunctions:userPrint(31, "Error: wrong behavior of SDL - device needs to be consented on HMI")
      else
        local RequestIdGetMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestIdGetMessage)
        :Do(function()
            --Press "NO"on data consent
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = false, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})

            EXPECT_NOTIFICATION("OnPermissionsChange", {}):Times(0)
          end)
      end
    end)
  EXPECT_HMICALL("BasicCommunication.CloseApplication",{}):Times(1)
  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(0)
end

function Test:TestStep_application_assign_pre_dataConsent()
  local group_app_id_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "SELECT functional_group_id FROM app_group where application_id = '0000001'")

  local group_app_id
  for _, value in pairs(group_app_id_table) do
    group_app_id = value
  end
  if(group_app_id ~= "129372391") then
    self:FailTestCase("Application is not assigned to BaseBeforeDataConsent. Group: "..group_app_id)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
