---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Define the URL(s) the PTS will be sent to
--
-- Description:
-- To get the urls PTS should be transfered to, Policies manager must refer PTS "endpoints" section,
-- key "0x07" for the appropriate <app id> which was chosen for PTS transferring
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- 2. Performed steps
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
--
-- Expected result:
-- SDL.GetURLs({urls[] = default}, (<urls>, appID))
-- SDL-> <app ID> ->OnSystemRequest(params, url, timeout)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTableSnapshot = require('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PolicyManager_sends_PTS_to_HMI()
  local endpoints = {}
  local is_test_fail = false

  --TODO(istoimenova): Should be updated when "[GENIVI] HTTP: sdl_snapshot.json is not saved to file system" is fixed
  if(#testCasesForPolicyTableSnapshot.pts_endpoints == 0) then
    commonFunctions:printError("endpoints don't exist in PTS!")
    is_test_fail = true
    local endpoints_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select url from endpoint where service = '0x07'")

    for _,value in pairs(endpoints_table) do
      endpoints[#endpoints + 1] = { url = value, appID = nil}
    end
  else
    for i = 1, #testCasesForPolicyTableSnapshot.pts_endpoints do
      -- Take default endpoints
      if (testCasesForPolicyTableSnapshot.pts_endpoints[i].service == "0x07") then
        endpoints[#endpoints + 1] = { url = testCasesForPolicyTableSnapshot.pts_endpoints[i].value, appID = nil}
      end
    end
  end

  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

  EXPECT_HMIRESPONSE(RequestId_GetUrls,{result = {code = 0, method = "SDL.GetURLS", urls = endpoints} } )

  if(is_test_fail == true) then
    self:FailTestCase("Test is FAILED. See prints.")
  end
end

--[[ Postconditions ]]

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
