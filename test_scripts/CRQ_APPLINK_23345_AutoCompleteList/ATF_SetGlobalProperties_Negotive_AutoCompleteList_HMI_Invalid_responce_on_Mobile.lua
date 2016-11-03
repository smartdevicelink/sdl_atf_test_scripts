----Verification criteria:----
----SDL must responce GENERIC_ERROR on mobile app, if HMI send invalid responce on SDL.

Test = require('connecttest')

function Test:AutoCompleteList_ResponseDataNotExist_Wrong_json_From_HMI()
  --mobile side: sending SetGlobalProperties request
  cid = self.mobileSession:SendRPC("SetGlobalProperties",
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
        autoCompleteList = {"List_1, List_2", "List_1, List_2"}
      }
    })
  :Do(function(_,data)
       self.hmiConnection:Send('"id":'..data.id..',"jsonrpc":"2.0","result":{"code":0,"method""UI.SetGlobalProperties"}}')
    end)
  --mobile side: expect SetGlobalProperties response
  EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR", info = "Invalid message received from system"})
end

+--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

Test["ForceKill"] = function (self)
os.execute("ps aux | grep smart | awk \'{print $2}\' | xargs kill -9")
os.execute("sleep 1")
return Test
end

