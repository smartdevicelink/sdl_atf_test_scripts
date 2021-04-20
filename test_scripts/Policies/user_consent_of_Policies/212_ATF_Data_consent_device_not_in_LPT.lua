---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: user data concent - device that does not have records in "user_consent_records"
--
-- Description:
-- User activates the application which runs on the device that does not have records in "user_consent_records"-> "device" sub-section of Local PT
-- 1. Used preconditions:
-- Connect device
-- Register application
--
-- 2. Performed steps
-- Activate application
--
-- Expected result:
-- PoliciesManager must initiate getting User`s data consent (that is, User`s permission for using the mobile device`s connection for Policy Table exchange)
----------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Check_user_data_consent_is_requested()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(RequestId, {result = { code = 0, device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() }, isSDLAllowed = false, isPermissionsConsentNeeded = false, method ="SDL.ActivateApp"}})
  :Do(function(_,data)
      if data.result.isSDLAllowed ~= false then
        commonFunctions:userPrint(31, "Error: wrong behavior of SDL - device not from LPT, should be consented on HMI")
      else
        local RequestIdGetMes = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestIdGetMes)
        :Do(function()
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          end)
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
