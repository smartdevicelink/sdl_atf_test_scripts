---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetGlobalProperties] SDL omit "autoCompleteText" param at request to HMI
--
-- Description:
-- Case when mobile send SetGlobalProperties request, SDL must tranfer SetGlobalProperties_request with <autoCompleteList> param and without (omited) <autoCompleteText> 
-- param to HMI, and respond with <SUCCESS> to mobile app
--
-- Performed steps:
-- 1. Register Application.
-- 2. Mobile send RPC SetGlobalProperties with <autoCompleteList> and <autoCompleteText>
-- 3. HMI respond without <AutoCompleteText>
--
-- Expected result:
-- SDL transfered RPC on HMI without autoCompleteText param and responce with <SUCCESS> to mobile app
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
function Test:Check_SDL_omit_AutoCompleteText()
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
        autoCompleteList = {"List_1, List_2", "List_1, List_2"}
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
        autoCompleteList = {"List_1, List_2", "List_1, List_2"}
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
   end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
