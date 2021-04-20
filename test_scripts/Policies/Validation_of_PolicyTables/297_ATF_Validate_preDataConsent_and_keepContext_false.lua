---------------------------------------------------------------------------------------------
-- Requirement summary:
--      [Policies] DISALLOWED: "pre_DataConsent" policies and "keep_context" validation
--
-- Description:
--    Validation of "keep_context" section in case "keep_context:false" and "pre_DataConsent" policies are assigned to the application
--     1. Used preconditions:
--        SDL and HMI are started
--        Overwrite preloaded PT(with "keep_context"=false in "pre_DataConsent")
--
--     2. Performed steps
--        Send RPC with soft button with KEEP_CONTEXT SystemAction
--
-- Expected result:
--     PoliciesManager must validate "keep_context" section, SDL must reject RPC->
--     respond (resultCode:DISALLOWED, success:false) to mobile application
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/Base4InPreDataConsent_preloaded_pt.json")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Send_Alert_check_disallowed_keep_context()
  local RequestIDAlert = self.mobileSession:SendRPC("Alert",
  {
    alertText1 = "alertText1",
    ttsChunks =
    {
      {
        text = "TTSChunk",
        type = "TEXT",
      },
    },
    duration = 3000,
    softButtons =
    {
      {
        type = "IMAGE",
        image =

        {
          value = "icon.png",
          imageType = "STATIC",
        },
        softButtonID = 1171,
        systemAction = "KEEP_CONTEXT",
      },
    },
  })
  EXPECT_RESPONSE(RequestIDAlert, { success = false, resultCode = "DISALLOWED" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
