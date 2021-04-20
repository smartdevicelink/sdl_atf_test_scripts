---------------------------------------------------------------------------------------------
-- Requirement summary:
--      [Policies] "pre_DataConsent" policies and "keep_context" validation
--
-- Description:
--    Validation of "keep_context" section in case "keep_context:true" and "pre_DataConsent" policies are assigned to the application
--     1. Used preconditions:
--        SDL and HMI are started
--        Overwrite preloaded PT(with "keep_context"=true in "pre_DataConsent")
--
--     2. Performed steps
--        Send RPC with soft button with KEEP_CONTEXT SystemAction
--
-- Expected result:
--     PoliciesManager must validate "keep_context" section->
--     PoliciesManager must allow SDL to pass RPC
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Preconditions ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
testCasesForPolicyTable:Precondition_updatePolicy_By_overwriting_preloaded_pt("files/KeepContextTrue_preloaded_pt.json")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Send_Alert_check_allowed_keep_context()
  local CorIdAlert = self.mobileSession:SendRPC("Alert",
  {
    alertText1 = "alertText1",
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
  local AlertId
  EXPECT_HMICALL("UI.Alert",
  {
    alertStrings = {{fieldName = "alertText1", fieldText = "alertText1"}}, softButtons =
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
    }
  })
  :Do(function(_,data)
    self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "ALERT" })
    AlertId = data.id
    local function alertResponse()
      self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })
      self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
    end
    RUN_AFTER(alertResponse, 3000)
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {}):Times(2)
  EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
