--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetGlobalProperties] SDL respond <success = false, resultCode = "INVALID_DATA"> to mobile app
--
-- Description:
-- Case when mobile send SetGlobalProperties request, with <autoCompleteList> 
-- size of array is out of upper bound, SDL respond with <INVALID_DATA> to mobile app. 
--
-- Performed steps:
-- 1. Register Application.
-- 2. Mobile send RPC SetGlobalProperties with <autoCompleteList> size of array is out of upper bound.
--
-- Expected result:
-- SDL respond <success = false, resultCode = "INVALID_DATA"> to mobile app
---------------------------------------------------------------------------------------------
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

--[[ Local Variables ]]
 local outUpperBoundValue = 101
 local autoCompleteList_outUpper = {}
  for i=1, outUpperBoundValue do
   autoCompleteList_outUpper[i] = "TestList_101"
 end

--[[ Test ]]
function Test:AutoCompleteList_Array_IsOut_of_UpperBound()
 local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      keyboardProperties =
      {
        keyboardLayout = "qwerty",
        keypressMode = "single_keypress",
        limitedCharacterList =
        {
          "a"
        },
        language = "EN-US",
        autoCompleteText = "Text_1, Text_2",
        autoCompleteList = autoCompleteList_outUpper
      }
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
