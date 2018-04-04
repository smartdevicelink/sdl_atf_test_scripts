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
--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

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

  local endpoints = {
      { url = "http://policies.telematics.ford.com/api/policies1" },
      { url = "http://policies.telematics.ford.com/api/policies2" },
      { url = "http://policies.telematics.ford.com/api/policies3" },
      { url = "http://policies.telematics.ford.com/api/test_apllication" }
    }

  local RequestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

  EXPECT_HMIRESPONSE(RequestId, { result = { code = 0, method = "SDL.GetURLS" }})
  :ValidIf(function(_, data)
    local is_correct = {}
    for i = 1, #data.result.urls do
      for j = 1, #endpoints do
        if data.result.urls[i].url == endpoints[j].url then
          is_correct[i] = true
        end
      end
    end
    if(#data.result.urls ~= #endpoints ) then
      return false, "Number of urls is not as expected: "..#endpoints..". Real: "..#data.result.urls
    end
    for i = 1, #is_correct do
      if(is_correct[i] == false) then
        return false, "url: "..data.result.urls[i].url.." is not correct"
      end
    end
    return true
  end)
end


--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postconditions")

testCasesForPolicyTable:Restore_preloaded_pt()

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
