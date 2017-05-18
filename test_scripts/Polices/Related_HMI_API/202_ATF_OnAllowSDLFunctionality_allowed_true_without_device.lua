---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies]: OnAllowSDLFunctionality with 'allowed=true' and without 'device' param from HMI
--
-- Description:
-- 1. Preconditions: App is registered
-- 2. Steps: Activate App, send SDL.OnAllowSDLFunctionality with 'allowed=true' and without 'device' to HMI
--
-- Expected result:
-- HMI->SDL: SDL.OnAllowSDLFunctionality(allowed: true, without ‘device’ param)
-- SDL->HMI:BC.ActivateApp(params, level: <”default_hmi”-value-from-assigned-policies>)
-- SDL->app: OnHMIStatus(params, level: <”default_hmi”-value-from-assigned-policies>)
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_RegisterApp_allowed_true_without_device()
  local hmi_app1_id = self.applications[config.application1.registerAppInterfaceParams.appName]

  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = hmi_app1_id})

  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,_)

      local RequestId1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      --hmi side: expect SDL.GetUserFriendlyMessage message response
      EXPECT_HMIRESPONSE( RequestId1, {result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)

          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI"})
        end)

      EXPECT_HMICALL("BasicCommunication.PolicyUpdate",{})
      :Do(function(_,data) self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {}) end)
    end)

  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {}) end)

  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
