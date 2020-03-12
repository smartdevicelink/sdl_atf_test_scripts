---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate]: SDL must NOT send OnSDLConsentNeeded to HMI in case PTU was triggered manually and no concented devices were found
--
-- Description:
-- PTU is triggered by user, SDL generates PoliciesSnapshot and one unconsented device with registered app is found
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- DeleteLogsFileAndPolicyTable
-- Close default connection
-- Connect unconsented device (isSDLAllowed = false)
-- Register app
--
-- 2. Performed steps
-- User presses button on HMI to request PTU ->
-- HMI -> SDL: SDL.UpdateSDL_request
-- SDL -> HMI: SDL.UpdateSDL_response(UPDATE_NEEDED)
-- SDL generates Policies Snapshot
-- SDL check that there no consented devices connected (one un-consented devices connected)
--
-- Expected result:
-- SDL must NOT send the PoliciesSnapshot over OnSystemRequest to any of the apps,
-- SDL must NOT send the OnSDLConsentNeeded to HMI
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:PTU_requested_through_HMI()
  local RequestIdUpdateSDL = self.hmiConnection:SendRequest("SDL.UpdateSDL")
  EXPECT_HMIRESPONSE(RequestIdUpdateSDL,{result = {code = 0, method = "SDL.UpdateSDL", result = "UPDATE_NEEDED" }})

  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATING" })
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = "dummyfile" })
    end)

  EXPECT_HMINOTIFICATION("SDL.OnSDLConsentNeeded"):Times(0)
  self.mobileSession:ExpectRequest("OnSystemRequest"):Times(0)
  commonTestCases:DelayedExp(11000)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
