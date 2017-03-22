--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetGlobalProperties] SDL respond <success = false, resultCode = "GENERIC_ERROR"> to mobile app
--
-- Description:
-- Case when mobile send SetGlobalProperties request, SDL tranfer SetGlobalProperties request with <autoCompleteList> param to HMI,
-- HMI send invalid respond, and SDL respond with <resultCode = GENERIC_ERROR> to mobile app.
--
-- Performed steps:
-- 1. Register Application.
-- 2. Mobile send RPC SetGlobalProperties with <autoCompleteList>.
-- 3. HMI send invalid response on SDL
--
-- Expected result:
-- SDL respond <success = false, resultCode = "GENERIC_ERROR"> to mobile app
----------------------------------------------------------------------------------------------
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
function Test:TestStep_AutoCompleteList_InvalidResponse_from_HMI()
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
       self.hmiConnection:Send('"id":'..data.id..',"jsonrpc":"2.0","result":{"code":0,"method""UI.SetGlobalProperties"}}')
    end)
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from system"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
