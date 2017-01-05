----Verification criteria:----
----SDL respond with "GENERIC_ERROR, success:false" in case HMI does NOT respond during <DefaultTimeout>------
------------------------------------------------------------------------------------------------------------------------
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

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function  Test:SetGlobalProperties_WithFakeParam_from_HMI()
  --mobile side send SetGlobalProperties request
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
--hmi side: Default timeout, SDL recieved GENERIC_ERROR
EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
