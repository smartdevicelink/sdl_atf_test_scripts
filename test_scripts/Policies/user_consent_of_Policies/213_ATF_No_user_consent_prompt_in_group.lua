---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: lack of "user_consent_prompt" field is included to the <appID>`s policies
--
-- Description:
-- PTU for <appID> contains policies with <functional grouping> that lacks "user_consent_prompt" field
-- 1. Used preconditions:
-- Delete log files and policy table
-- Close default connection
-- Backup preloaded PT
-- Overwrite preloaded PT to make device preconsented
-- Connect device
-- Register application
--
-- 2. Performed steps
-- Perform PTU that contains policies for app with <functional grouping> that lacks "user_consent_prompt" field
-- Activate application
--
-- Expected result:
-- PoliciesManager must apply such <functional grouping> without asking User`s consent for it
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
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

function Test:TestStep1_PTU_lack_of_user_consent_prompt()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  --Allow SDL functionality
  EXPECT_HMIRESPONSE(RequestId,{ result = { code = 0, method = "SDL.ActivateApp", isPermissionsConsentNeeded = false, isSDLAllowed = false}})
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
        commonFunctions:userPrint(31, "Wrong SDL bahavior: there are app permissions for consent, isPermissionsConsentNeeded should be false")
        return false
      end
    end)
end

function Test:TestStep_app_no_consent()
  local app_permission = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..utils.getDeviceMAC()..".user_consent_records."..config.application1.registerAppInterfaceParams.fullAppID)
  if(app_permission ~= nil) then
    self:FailTestCase("Consented gropus are assigned to application")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
