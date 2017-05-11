--------------------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetGlobalProperties] SDL must transfer request to HMI in case "autoCompleteList" param omited in request from mobile app
--
-- Description:
-- Case when SDL tranfer SetGlobalProperties_request without <autoCompleteList> param to HMI and
-- respond with <success = true, resultCode = "SUCCESS"> to mobile app
--
-- Performed steps:
-- 1. Register Application.
-- 2. Mobile send RPC SetGlobalProperties without <autoCompleteList> param
--
-- Expected result:
-- SDL respond <success = true, resultCode = "SUCCESS"> to mobile app
--------------------------------------------------------------------------------------------------------------
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
function Test:SetGlobalProperties_Without_autoCompleteList()
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
        autoCompleteText = "Text_1, Text_2",
      }
    })
  :Do(function(_,data)
    if (data.params.autoCompleteList == nil) then
        self.hmiConnection:SendResponse (data.id, data.method, "SUCCESS", {})
      return true
    else
      return false
  end
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
