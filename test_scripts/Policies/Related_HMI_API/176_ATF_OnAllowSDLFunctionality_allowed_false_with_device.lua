---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: OnAllowSDLFunctionality with 'allowed=false' and with 'device' param from HMI
--
-- Description:
-- 1. Preconditions: App is registered, device is consented
-- 2. Steps: send SDL.OnAllowSDLFunctionality with 'allowed=false' and with 'device' to HMI
--
-- Expected result:
-- The User sais "NO" for data consent prompt:
-- HMI->SDL: SDL.OnAllowSDLFunctionality (allowed: false, device, source)
-- PoliciesManager updates "user_consent_records" -> "device". sub-section.
-- SDL->HMI: BasicCommunication.ActivateApp ('level': NONE)
-- app stays in NONE level on HMI.
-- HMI->SDL: BasicCommunication.ActivateApp_response
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_RegisterApp_allowed_false_without_device()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)

      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      --hmi side: expect SDL.GetUserFriendlyMessage message response
      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = false, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = false}})
        end)
    end)

  EXPECT_HMICALL("BasicCommunication.CloseApplication", {appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  :Do(function(_,data)
    self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
  end)

  EXPECT_NOTIFICATION("OnHMIStatus"):Times(0)
end

function Test:TestStep_CheckDeviceConsentGroup()
  os.execute("sleep 3")
  local result = commonFunctions:is_db_contains(config.pathToSDL.."/storage/policy.sqlite", "SELECT is_consented FROM device_consent_group", {"0"} )
  if(result ~= true) then
    self:FailTestCase("Error: Value of is_consented on policy DB should be false(0).")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
