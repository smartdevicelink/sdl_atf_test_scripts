-----------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetGlobalProperties] SDL respond <success = false, resultCode = "INVALID_DATA"> to mobile app
--
-- Description:
-- Case when mobile send request with incorrect JSON file with correct value of <autoCompleteList>, SDL send respond 
-- with result_code = "INVALID_DATA" to mobile.
-- 
-- Performed steps:
-- 1. Register Application.
-- 2. Mobile send request to SDL with incorrect json.
--
-- Expected result:
-- SDL respond <success = false, resultCode = "INVALID_DATA"> to mobile app
----------------------------------------------------------------------------------------
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
function Test:AutoCompleteList_IncorrectJSON()
  local msg =
  {
    serviceType = 7,
    frameInfo = 0,
    rpcType = 0,
    rpcFunctionId = 7,
    rpcCorrelationId = self.mobileSession.correlationId,
    payload = '{"initialText""StartPerformInteraction","interactionMode":"VR_ONLY","interactionChoiceSetIDList":[100,200,300],"ttsChunks":[{"text":"SpeakFirst","type":"TEXT"},{"text":"SpeakSecond","type":"TEXT"}],"timeout":5000,"vrHelp":[{"text":"NewVRHelpv","position":1,"image":{"value":"icon.png","imageType":"STATIC"}},{"text":"NewVRHelpvv","position":2,"image":{"value":"icon.png","imageType":"STATIC"}},{"text":"NewVRHelpvvv","position":3,"image":{"value":"icon.png","imageType":"STATIC"}}],"timeoutPrompt":[{"text":"Timeoutv","type":"TEXT"},{"text":"Timeoutvv","type":"TEXT"}],"initialPrompt":[{"text":"Makeyourchoice","type":"TEXT"}],"autoCompleteList"=,"interactionLayout":"ICON_ONLY","helpPrompt":[{"text":"HelpPromptv","type":"TEXT"},{"text":"HelpPromptvv","type":"TEXT"}]}'
  }
  self.mobileSession:Send(msg)
  EXPECT_RESPONSE(self.mobileSession.correlationId, { success = false, resultCode = "INVALID_DATA" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
