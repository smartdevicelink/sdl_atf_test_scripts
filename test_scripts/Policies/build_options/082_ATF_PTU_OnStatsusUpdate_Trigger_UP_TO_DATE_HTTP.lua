---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] OnStatusUpdate trigger
-- c) UP_TO_DATE VC
-- [HMI API] OnStatusUpdate
-- [HMI API] OnReceivedPolicyUpdate notification
--
-- Description:
--PoliciesManager must change the status to “UP_TO_DATE” and notify HMI with
--OnStatusUpdate("UP_TO_DATE") right after successful validation of received PTU .
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:HTTP)
-- SDL->app: OnSystemRequest ('url', requestType:HTTP, fileType="JSON")
-- app->SDL: SystemRequest(requestType=HTTP)
-- SDL->HMI: SystemRequest(requestType=HTTP, fileName)
-- HMI->SDL: SystemRequest(SUCCESS)
-- 2. Performed steps
-- HMI->SDL: OnReceivedPolicyUpdate(policy_file) according to data dictionary
--
-- Expected result:
-- SDL->HMI: OnStatusUpdate(UP_TO_DATE)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test.Wait()
	commonTestCases:DelayedExp(2000)
end

function Test:TestStep_PoliciesManager_changes_UP_TO_DATE()
  assert(commonFunctions:File_exists("files/ptu.json"))
  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
    { requestType = "HTTP", fileName = "PolicyTableUpdate" },"files/ptu.json")

  EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMICALL("BasicCommunication.SystemRequest"):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Stop()
  StopSDL()
end

return Test
