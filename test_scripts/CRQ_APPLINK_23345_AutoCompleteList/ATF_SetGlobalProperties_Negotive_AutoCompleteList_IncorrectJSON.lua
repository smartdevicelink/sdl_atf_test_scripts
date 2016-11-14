---Verification Criteria---
---SDL must respond with INVALID_DATA and "success":"false--
---Application sent request to SDL with wrong syntax in JSON--
 
Test = require('connecttest')

function Test:AutoCompleteList_IncorrectJSON()
--mobile side: send request
  local msg =
  {
    serviceType = 7,
    frameInfo = 0,
    rpcType = 0,
    rpcFunctionId = 7,
    rpcCorrelationId = self.mobileSession.correlationId,
    payload = '{"initialText""StartPerformInteraction","interactionMode":"VR_ONLY","interactionChoiceSetIDList":[100,200,300],"ttsChunks":[{"text":"SpeakFirst","type":"TEXT"},{"text":"SpeakSecond","type":"TEXT"}],"timeout":5000,"vrHelp":[{"text":"NewVRHelpv","position":1,"image":{"value":"icon.png","imageType":"STATIC"}},{"text":"NewVRHelpvv","position":2,"image":{"value":"icon.png","imageType":"STATIC"}},{"text":"NewVRHelpvvv","position":3,"image":{"value":"icon.png","imageType":"STATIC"}}],"timeoutPrompt":[{"text":"Timeoutv","type":"TEXT"},{"text":"Timeoutvv","type":"TEXT"}],"initialPrompt":[{"text":"Makeyourchoice","type":"TEXT"}],"interactionLayout":"ICON_ONLY","helpPrompt":[{"text":"HelpPromptv","type":"TEXT"},{"text":"HelpPromptvv","type":"TEXT"}]}'
  }
  self.mobileSession:Send(msg)
  EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
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










