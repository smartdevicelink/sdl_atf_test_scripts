---------------------------------------------------------------------------------------------
-- Requirements summary:
-- In case HMI sends GetURLs and at least one app is registered SDL must return only default url and url related to registered app
--
-- Description:
-- In case HMI sends GetURLs (<serviceType>) AND at least one mobile app is registered
-- SDL must: check "endpoint" section in PolicyDataBase, retrieve all urls related to requested <serviceType>,
-- return only default url and url related to registered mobile app
-- 1. Used preconditions
-- SDL is built with "DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- 2. Performed steps
-- HMI->SDL: SDL.GetURLs(service=0x07)
--
-- Expected result:
-- PTU is requested. PTS is created.
-- SDL.GetURLs({urls[] = registered_App1, default})
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/jsons/Policies/Policy_Table_Update/few_endpoints_appId.json")
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU_GetURLs()
  local endpoints = {}

  --TODO(istoimenova): Should be removed when "[GENIVI] HTTP: sdl_snapshot.json is not saved to file system" is fixed.
  if ( commonSteps:file_exists( '/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json') ) then
    testCasesForPolicyTableSnapshot:extract_pts(
      {config.application1.registerAppInterfaceParams.appID},
      {self.applications[config.application1.registerAppInterfaceParams.appName]})

    for i = 1, #testCasesForPolicyTableSnapshot.pts_endpoints do
      if (testCasesForPolicyTableSnapshot.pts_endpoints[i].service == "0x07") then
        endpoints[#endpoints + 1] = {
          url = testCasesForPolicyTableSnapshot.pts_endpoints[i].value,
          appID = testCasesForPolicyTableSnapshot.pts_endpoints[i].appID}
      end
    end
  else
    endpoints = {
      {url = "http://policies.telematics.ford.com/api/policies1", appID = nil},
      {url = "http://policies.telematics.ford.com/api/policies2", appID = nil},
      {url = "http://policies.telematics.ford.com/api/policies3", appID = nil},
      {url = "http://policies.telematics.ford.com/api/test_apllication", appID = self.applications[config.application1.registerAppInterfaceParams.appName]}
    }
  end

  local RequestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

  EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetURLS"} } )
  :ValidIf(function(_,data)
    local is_correct = {}
    for i = 1, #data.result.urls do
      for j = 1, #endpoints do
        if ( data.result.urls[i] == endpoints[j] ) then
          is_correct[i] = true
        end
      end
    end
    if(#data.result.urls ~= #endpoints ) then
      self:FailTestCase("Number of urls is not as expected: "..#endpoints..". Real: "..#data.result.urls)
    end
    for i = 1, #is_correct do
      if(is_correct[i] == false) then
        self:FailTestCase("url: "..data.result.urls[i].url.." is not correct")
      end
    end
  end)
end


--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
