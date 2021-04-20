---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] PTS creation rule
--
-- Description:
-- SDL should request PTU in case new application is registered and is not listed in PT
-- and device is not consented.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Connect mobile phone over WiFi.
-- 2. Performed steps
-- Register new application and perfor trigger getting user consent device
--
-- Expected result:
-- PTU is requested. PTS is created.
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PTS_Creation_rule()
  local hmi_app1_id = self.applications[config.application1.registerAppInterfaceParams.appName]
  local result = true

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})

  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)

      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          testCasesForPolicyTable.time_trigger = timestamp()

          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName(), isSDLAllowed = true}})
      end)

      EXPECT_HMICALL("BasicCommunication.PolicyUpdate", { file = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json" })
      :Do(function(_,data)
        result = testCasesForPolicyTableSnapshot:verify_PTS(true,
          {config.application1.registerAppInterfaceParams.fullAppID},
          {utils.getDeviceMAC()},
          {hmi_app1_id},
          "print")

        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        if(result == false) then
          self:FailTestCase("Test is FAILED. See prints.")
        end
      end)
    end)

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
