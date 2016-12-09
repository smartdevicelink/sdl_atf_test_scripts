---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] Treating the device as consented
--
-- Description:
-- Condition for device to be consented
-- 1. Used preconditions:
-- Close current connection
-- Overwrite preloaded policy table to have group both listed in 'device' and 'preconsented_groups' sub-sections of 'app_policies' section
-- Connect device for the first time
-- Register app running on this device
-- 2. Performed steps
-- Activate app: HMI->SDL: SDL.ActivateApp => Policies Manager treats the device as consented => no consent popup appears => SDL->HMI: SDL.ActivateApp(isSDLAllowed: true, params)
--
-- Expected result:
-- Policies Manager must treat the device as consented If "device" sub-section of "app_policies" has its group listed in "preconsented_groups".
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Local variables ]]
local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/DeviceGroupInPreconsented_preloadedPT.json")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_TreatDeviceAsConsented()
  local is_test_fail = false
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)
      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})

      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = ServerAddress, isSDLAllowed = true}})

          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})

          EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{})
          :Do(function(_,_)
              testCasesForPolicyTableSnapshot:extract_pts({self.applications[config.application1.registerAppInterfaceParams.appName]})
              local device_consent_groups = testCasesForPolicyTableSnapshot:get_data_from_PTS("app_policies.device.groups.1")
              local device_preconsented_groups = testCasesForPolicyTableSnapshot:get_data_from_PTS("app_policies.device.preconsented_groups.1")

              print("device_consent_groups = " ..tostring(device_consent_groups))
              print("device_preconsented_groups = " ..tostring(device_preconsented_groups))

              if(device_consent_groups ~= "DataConsent-2") then
                commonFunctions:printError("Error: app_policies.device.groups should be DataConsent-2")
                is_test_fail = true
              end

              if(device_preconsented_groups ~= "DataConsent-2") then
                commonFunctions:printError("Error: app_policies.device.preconsented_groups should be DataConsent-2")
                is_test_fail = true
              end
            end)
      end)
  end)
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_SDLForceStop()
  commonFunctions:SDLForceStop()
end

return Test
