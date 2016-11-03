----Verification criteria:----
----SDL respond with "GENERIC_ERROR, success:false" in case HMI does NOT respond during <DefaultTimeout>------

Test = require('connecttest')

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
        autoCompleteText = "Text_1, Text_2"
        autoCompleteList = {"List_1, List_2", "List_1, List_2"}
      }
    })
 --hmi side: expect UI.SetGlobalProperties request
	EXPECT_HMICALL ("UI.SetGlobalProperties", 
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
-- expect responce from HMI side---
--hmi side: Default timeout, SDL recieved GENERIC_ERROR
EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
end

+--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

Test["ForceKill"] = function (self)
os.execute("ps aux | grep smart | awk \'{print $2}\' | xargs kill -9")
os.execute("sleep 1")

return Test
end
