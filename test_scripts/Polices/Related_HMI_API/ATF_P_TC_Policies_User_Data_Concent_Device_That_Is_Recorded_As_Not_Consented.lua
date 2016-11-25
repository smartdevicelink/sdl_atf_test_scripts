---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: user data concent - device that is recorded as NOT-consented
--
-- Description:
-- SDL must:
-- send OnSDLConsentNeeded to initiate getting User`s data consent
-- (that is, User`s permission for using the mobile device`s connection for Policy Table exchange)
-- In case:
-- the User activates the application which runs on the device that is recorded as NOT-consented
-- in "user_consent_records"-> "device" sub-section of Local PT
--
-- Preconditions:
-- 1. Application with <appID> is registered on SDL.
-- Steps:
-- 1. Activate appllication: HMI -> SDL: SDL.ActivateApp
-- 2. Verify that SDL.OnSDLConsentNeeded notification is sent with appropriate payload
--
-- Expected result:
-- SDL -> HMI: SDL.OnSDLConsentNeeded
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local testCasesForBuildingSDLPolicyFlag = require('user_modules/shared_testcases/testCasesForBuildingSDLPolicyFlag')

--[[ General Precondition before ATF start ]]
testCasesForBuildingSDLPolicyFlag:CheckPolicyFlagAfterBuild("EXTERNAL_PROPRIETARY")
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:ActivateNewApp()
  local reqId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(reqId1)
  :Do(function(_, d1)
      EXPECT_HMINOTIFICATION("SDL.OnSDLConsentNeeded", {})
      if d1.result.isSDLAllowed == false then
        local reqId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(reqId2)
        :Do(function(_, _)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_, d2)
                self.hmiConnection:SendResponse(d2.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(1)
          end)
      end
    end)
  self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "FULL" })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
end

return Test
