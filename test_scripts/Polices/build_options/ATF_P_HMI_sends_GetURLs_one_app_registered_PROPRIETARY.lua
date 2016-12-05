-- UNREADY:
-- Please note still not implemented functions:
-- testCasesForPolicyTable:flow_PTU_SUCCEESS_PROPRIETARY() and testCasesForPolicyTable:trigger_PTU_user_press_button_HMI
-- testCasesForPolicyTable:flow_PTU_SUCCEESS_PROPRIETARY() correct when fucntion will be included in testCasesForPolicyTable

---------------------------------------------------------------------------------------------
-- Requirements summary:
-- In case HMI sends GetURLs and at least one app is registered SDL must return only default url and url related to registered app
-- [HMI API] GetURLs request/response
--
-- Description:
-- SDL should request PTU in case user requests PTU
-- 1. Used preconditions
-- SDL is built with "EXTENDED_POLICY: PROPRIETARY" flag
-- Application is registered.
-- No PTU is requested.
-- 2. Performed steps
-- User press button on HMI to request PTU.
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

--TODO(anikolaev): Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
--TODO(anikolaev): Function still not implemented
function Test.Precondition_PTU_SUCCESS ()
  testCasesForPolicyTable:flow_PTU_SUCCEESS_PROPRIETARY()
end

--TODO(anikolaev): Function still not implemented
function Test.Precondition_Request_PTU ()
  testCasesForPolicyTable:trigger_PTU_user_press_button_HMI()
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_PTU_GetURLs()
  local endpoints = {}
  local is_app_esxist = false

  for i = 1, #testCasesForPolicyTableSnapshot.pts_endpoints do
    if (testCasesForPolicyTableSnapshot.pts_endpoints[i].service == "0x07") then
      endpoints[#endpoints + 1] = { url = testCasesForPolicyTableSnapshot.pts_endpoints[i].value, appID = nil}
    end
    if (testCasesForPolicyTableSnapshot.pts_endpoints[i].service == "app1") then
      endpoints[#endpoints + 1] = { url = testCasesForPolicyTableSnapshot.pts_endpoints[i].value, appID = nil}
      is_app_esxist = true
    end
  end

  local RequestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })

  EXPECT_HMIRESPONSE(RequestId,{result = {code = 0, method = "SDL.GetURLS", urls = endpoints}})
  :Do(function(_,_)
      if(is_app_esxist == false) then
        self:FailTestCase("endpoints for application doesn't exist!")
      end
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
Test["StopSDL"] = function()
  StopSDL()
end
