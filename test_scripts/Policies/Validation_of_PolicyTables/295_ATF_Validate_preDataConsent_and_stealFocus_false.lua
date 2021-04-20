---------------------------------------------------------------------------------------------
-- Requirement summary:
--      [Policies] DISALLOWED: "pre_DataConsent" policies and "steal_focus" validation
--
-- Description:
--    Validation of "steal_focus" section in case "steal_focus:false" and <app id> policies are assigned to the application
--     1. Used preconditions:
--        SDL and HMI are started
--        Overwrite preloaded PT(with "steal_focus"=false in "pre_DataConsent")
--
--     2. Performed steps
--        Send RPC with soft button with STEAL_FOCUS SystemAction
--
-- Expected result:
--     PoliciesManager must validate "steal_focus" section, SDL must reject RPC->
--     respond (resultCode:DISALLOWED, success:false) to mobile application
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/Base4InPreDataConsent_preloaded_pt.json")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Send_Alert_check_disallowed_steal_focus()
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
        systemAction = "STEAL_FOCUS",
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
