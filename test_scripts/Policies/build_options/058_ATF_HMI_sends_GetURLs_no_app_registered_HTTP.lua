---------------------------------------------------------------------------------------------
-- Requirements summary:
-- In case HMI sends GetURLs and no apps registered SDL must return only default url
--
-- Description:
-- In case HMI sends GetURLs (<serviceType>) AND NO mobile apps registered
-- SDL must:check "endpoint" section in PolicyDataBase return only default url
--(meaning: SDL must skip others urls which relate to not registered apps)
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered. AppID is listed in PTS
-- No PTU is requested.
-- 2. Performed steps
-- Unregister application.
-- User press button on HMI to request PTU.
-- HMI->SDL: SDL.GetURLs(service=0x07)
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL.GetURLs({urls[] = default})
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local mobile_session = require('mobile_session')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/Policy_Table_Update/endpoints_appId.json")
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test.Precondition_Wait()
  commonTestCases:DelayedExp(1000)
end

function Test:Precondition_PTU_flow_SUCCESS ()
  testCasesForPolicyTable:flow_PTU_SUCCEESS_HTTP(self)
end

function Test:Precondition_UnregisterApp()
  self.mobileSession:SendRPC("UnregisterAppInterface", {})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = self.applications[config.application1.registerAppInterfaceParams.appName], unexpectedDisconnect = false})
  EXPECT_RESPONSE("UnregisterAppInterface", {success = true , resultCode = "SUCCESS"})
end

-- -- Request PTU
-- function Test:Precondition_TriggerPTU()
--   self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
--   self.mobileSession2:StartService(7)
--   :Do(function()
--     local correlationId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
--     EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" })
--     self.mobileSession2:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
--   end)
-- end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU_GetURLs_NoAppRegistered()
  local endpoints = { {url = "http://policies.telematics.ford.com/api/policies", appID = nil} }
  local RequestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetURLS"} } )
  :Do(function(_,data)
    local is_correct = {}
    for i = 1, #data.result.urls do
      is_correct[i] = false
      for j = 1, #endpoints do
        if ( data.result.urls[i].url == endpoints[j].url ) then
          is_correct[i] = true
        end
      end
    end
    if(#data.result.urls ~= #endpoints ) then
      self:FailTestCase("Number of urls is not as expected: "..#endpoints..". Real: "..#data.result.urls)
    end
    for i = 1, #is_correct do
      if(is_correct[i] == false) then
        self:FailTestCase("url: "..data.result.urls[i].url.." is not correct. Expected: "..endpoints[i].url)
      end
    end
  end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
