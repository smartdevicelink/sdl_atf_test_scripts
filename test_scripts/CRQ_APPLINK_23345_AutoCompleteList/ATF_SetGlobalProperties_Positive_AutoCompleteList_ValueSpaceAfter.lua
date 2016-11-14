---Verification Criteria---
---SDL must respond with SUCCESS and "success":"true"--
---Mobile send SetGlobalProperties, AutoCompleteList param with spaces after values to HMI---
---HMI send responce with result code "success"--

Test = require('connecttest')


function Test:AutoCompleteList_SpaceAfter()
  --mobile side: sending SetGlobalProperties request
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
        autoCompleteList = {"SpaceAfter ", "SpaceAfter "}
      }
    })
  --hmi side: expect UI.SetGlobalProperties request
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
        autoCompleteList = {"SpaceAfter ", "SpaceAfter "}
      }
    })
  :Do(function(_,data)
       self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  --mobile side: expect SetGlobalProperties response
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
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



