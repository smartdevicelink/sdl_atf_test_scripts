----------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetGlobalProperties] SDL must transfer request in case of valid "autoCompleteList" param 
--
-- Description:
-- Case when mobile send SetGlobalProperties request, SDL tranfer SetGlobalProperties_request with <autoCompleteList> value in array is lower bound param to HMI,
-- and respond with <SUCCESS> to mobile app
--
-- Performed steps:
-- 1. Register Application.
-- 2. Mobile send RPC SetGlobalProperties with <autoCompleteList>  array is lower bound.
-- 3. HMI respond <SUCCESS>
--
-- Expected result:
-- SDL respond <success = true, resultCode = "SUCCESS"> to mobile app
----------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_AutoCompleteList_Array_Is_LowerBound()
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties =
      {
        keyboardLayout = "QWERTY",
        keypressMode = "SINGLE_KEYPRESS",
        limitedCharacterList =
        {
          "a"
        },
        language = "EN-US",
        autoCompleteText = "Text_1, Text_2",
        autoCompleteList = {"T"}
      }
    })
  EXPECT_HMICALL("UI.SetGlobalProperties", 
     {
      keyboardProperties =
      {
        keyboardLayout = "QWERTY",
        keypressMode = "SINGLE_KEYPRESS",
        limitedCharacterList =
        {
          "a"
        },
        language = "EN-US",
        autoCompleteList = {"T"}
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
 EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange") 
   :Times(1)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
