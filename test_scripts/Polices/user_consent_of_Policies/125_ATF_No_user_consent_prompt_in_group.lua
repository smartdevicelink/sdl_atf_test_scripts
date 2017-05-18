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

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
--testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/DeviceGroupInPreconsented_preloadedPT.json")
--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep1_PTU_lack_of_user_consent_prompt()
  local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  --Allow SDL functionality
  EXPECT_HMIRESPONSE(RequestId,{ result = { code = 0, method = "SDL.ActivateApp", isPermissionsConsentNeeded = false, isSDLAllowed = false}})
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
        commonFunctions:userPrint(31, "Wrong SDL bahavior: there are app permissions for consent, isPermissionsConsentNeeded should be false")
        return false
      end
    end)
end

function Test:TestStep_app_no_consent()
  local app_permission = testCasesForPolicyTableSnapshot:get_data_from_PTS("device_data."..config.deviceMAC..".user_consent_records."..config.application1.registerAppInterfaceParams.appID)
  if(app_permission ~= 0) then
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