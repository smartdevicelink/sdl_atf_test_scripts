---Verification Criteria---
---SDL must respond with SUCCESS and "success":"true"--
---"autoCompleteList" array is upper bound--

Test = require('connecttest')

function Test:AutoCompleteList_Array_Is_UpperBound()
 --TC_04
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
        autoCompleteList = {"TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
                           "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
                           "TestList_100","TestList_100"}
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
        autoCompleteList ={"TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
                           "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
			   "TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100","TestList_100",
                           "TestList_100","TestList_100"}
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




