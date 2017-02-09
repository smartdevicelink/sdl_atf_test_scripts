--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetGlobalProperties] Conditions for SDL respond <success = false, resultCode = "GENERIC_ERROR"> to mobile app
--
-- Description:
-- Case when SDL tranfer SetGlobalProperties_request with <autoCompleteList> param to HMI, HMI doesn't respond,
-- SDL respond with <GENERIC_ERROR> to mobile app
--
-- Performed steps:
-- 1. Register Application.
-- 2. Mobile send RPC SetGlobalProperties with <autoCompleteList> 
-- 3. HMI does NOT respond during <DefaultTimeout>
--
-- Expected result:
-- SDL respond <success = false, resultCode = "GENERIC_ERROR"> to mobile app
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

--[[Local Veriables]]
local iTimeout = 10000

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:SetGlobalProperties_RequestWithoutUIResponsesFromHMI()
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
    {
      menuTitle = "Menu Title",
      timeoutPrompt = 
       {
         {
           text = "Timeout prompt",
           type = "TEXT"
          }
        },
      vrHelp = 
       {
         {
           position = 1,
           text = "VR help item"
         }
       },
        helpPrompt = 
        {
          {
            text = "Help prompt",
            type = "TEXT"
          }
        },
        vrHelpTitle = "VR help title",
        keyboardProperties = 
        {
          keyboardLayout = "QWERTY",
          keypressMode = "SINGLE_KEYPRESS",
          limitedCharacterList = 
          {
            "a"
          },
          language = "EN-US",
          autoCompleteText = "Daemon, Freedom",
          autoCompleteList = {"List_1, List_2", "List_1, List_2"}
        }
      })
      --hmi side: expect TTS.SetGlobalProperties request
      EXPECT_HMICALL("TTS.SetGlobalProperties",
      {
        timeoutPrompt = 
        {
          {
            text = "Timeout prompt",
            type = "TEXT"
          }
        },
        helpPrompt = 
        {
          {
            text = "Help prompt",
            type = "TEXT"
          }
        }
      })
      :Timeout(iTimeout)
    EXPECT_HMICALL("UI.SetGlobalProperties",
      {
        menuTitle = "Menu Title",
        vrHelp = 
        {
          {
            position = 1,
            text = "VR help item"
          }
        },
        vrHelpTitle = "VR help title",
        keyboardProperties = 
        {
          keyboardLayout = "QWERTY",
          keypressMode = "SINGLE_KEYPRESS",
          language = "EN-US",
          autoCompleteList = {"List_1, List_2", "List_1, List_2"}
        }
      })
      :Timeout(iTimeout)
      :Do(function(_,_)
        --hmi side: sending UI.SetGlobalProperties response
        --self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)    
      --mobile side: expect SetGlobalProperties response
      EXPECT_RESPONSE(cid, { success = false, resultCode = "GENERIC_ERROR", info = nil})
      :Timeout(12000)
  end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end