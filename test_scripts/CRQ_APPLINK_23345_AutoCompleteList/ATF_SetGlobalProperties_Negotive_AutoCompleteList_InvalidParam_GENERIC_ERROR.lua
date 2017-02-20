----Verification criteria:----
----SDL must cut_off invalid param and responce GENERIC_ERROR on mobile app, 
----HMI send responce on SDL with invalid value of valid param and other valid params with valid values.------

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
-- hmi side: send responce with fake value of param
 :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.metod, "SUCCESS", 
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
           autoCompleteList = 5
       }
    })
    end)
 --mobile side: expect response
  :Do(function(_,data)
      if data.params.autoCompleteList == nil then
        EXPECT_RESPONSE(cid, {success = false, resultCode = "GENERIC_ERROR"})
      return true
    elseif
       return false
    end)
end

+--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

Test["ForceKill"] = function (self)
os.execute("ps aux | grep smart | awk \'{print $2}\' | xargs kill -9")
os.execute("sleep 1")
return Test

end


