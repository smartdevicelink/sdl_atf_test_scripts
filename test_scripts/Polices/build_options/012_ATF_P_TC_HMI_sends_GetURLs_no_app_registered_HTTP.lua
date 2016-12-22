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

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')


--[[ General Precondition before ATF start ]]
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

-- Request PTU
function Test:Precondition_trigger_PTU_user_request_update_from_HMI()
  testCasesForPolicyTable:trigger_user_request_update_from_HMI(self)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU_GetURLs_NoAppRegistered()
  local endpoints = {}
  --TODO(istoimenova): Should be removed when "[GENIVI] HTTP: sdl_snapshot.json is not saved to file system" is fixed.
  if ( commonSteps:file_exists( '/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json') ) then
    testCasesForPolicyTableSnapshot:extract_pts()

    for i = 1, #testCasesForPolicyTableSnapshot.pts_endpoints do
      if (testCasesForPolicyTableSnapshot.pts_endpoints[i].service == "0x07") then
        endpoints[#endpoints + 1] = {
          url = testCasesForPolicyTableSnapshot.pts_endpoints[i].value,
          appID = testCasesForPolicyTableSnapshot.pts_endpoints[i].appID}
      end
    end
  else
    commonFunctions:printError("sdl_snapshot is not created.")
    endpoints = { {url = "http://policies.telematics.ford.com/api/policies", appID = nil} }
  end

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