---------------------------------------------------------------------------------------------
-- Name of requirement that is covered.
--[PolicyTableUpdate] SDL must re-assign "default" policies to app in case "default" policies was updated via PolicyTable update--
--
-- Description
-- PoliciesManager must:
-- re-assign updated "default" policies to this app
-- In case Policies Manager assigns the "default" policies to app AND the value of "default" policies was updated in case of PolicyTable update
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
--local mobile_session = require('mobile_session')

--[[ Local Variables ]]
local binaryData = "files/jsons/Policies/build_options/ptu_14740.json"
--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_MOVE_SYSTEM_TO_UP_TO_DATE()
  commonFunctions:check_ptu_sequence_partly(self, binaryData, "ptu_14740.json")
end
function Test:SendRPCForCheckNewDefaultPolicies_DISALLOWED()
  local ReqCid = self.mobileSession:SendRPC("Alert", {})
  self.mobileSession:ExpectResponse(ReqCid, { success = false, resultCode = "DISALLOWED" })
end
function Test:SendRPCForCheckNewDefaultPolicies_SUCCESS()
  local RequestCid = self.mobileSession:SendRPC("ListFiles",{})
  self.mobileSession:ExpectResponse(RequestCid, { success = true, resultCode = "SUCCESS" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
