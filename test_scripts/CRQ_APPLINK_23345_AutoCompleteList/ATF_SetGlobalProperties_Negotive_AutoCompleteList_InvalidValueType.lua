---Verification Criteria---
---SDL must respond with INVALID_DATA and "success":"false--
---"autoCompleteList" is  wrong type--

Test = require('connecttest')


function Test:AutoCompleteList_IS_WrongType()
  --TC_12
  --mobile side: sending SetGlobalProperties request
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
        autoCompleteList = 5
      }
    })
  --mobile side: expect SetGlobalProperties response
     :Do(function(_,data)
        EXPECT_RESPONSE(cid, { success = false, resultCode = "INVALID_DATA" })
    end)
   --mobile side: expecting OnHashChange notification
     EXPECT_NOTIFICATION("OnHashChange") 
     :Times(0)
end


--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

Test["ForceKill"] = function (self)
os.execute("ps aux | grep smart | awk \'{print $2}\' | xargs kill -9")
os.execute("sleep 1")
return Test
end


