-----------------------------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [SetGlobalProperties] SDL respond <success = false, resultCode = "DISALLOWED"> to mobile app.
--
-- Description:
-- Case when SDL doesn’t transfer not allowed "SetGlobalProperties" request with valid "autoCompleteList" param to HMI
-- respond with result code "DISALLOWED" to mobile app.
--
-- Performed steps:
-- 1. Register Application.
-- 2. Mobile send RPC SetGlobalProperties with <autoCompleteList>.
-- 
-- Expected result:
-- SDL respond <success = false, resultCode = "DISALLOWED"> to mobile app
-----------------------------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

--[[ Local Variables ]]
local registerAppInterfaceParams =
  {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 0
    },
    appName = "Media Application",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = {"NAVIGATION"},
    appID = "MyTestApp",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  }

--[[ Local Functions ]]
local function UpdatePreloadedJson_DisallowSetGlobalPropertiesRPC()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") 
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = nil
  end

  data.policy_table.functional_groupings["Base-4"].rpcs["SetGlobalProperties"] = nil 

  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end


--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.Precondition_DeleteLogsAndPolicyTable()
commonSteps:DeleteLogsFileAndPolicyTable()
end

function Test.Precondition_Backup_preloadedPT()
  commonPreconditions:BackupFile("sdl_preloaded_pt.json")
end

function Test.Precondition_DisallowSetGlobalProperties()
  UpdatePreloadedJson_DisallowSetGlobalPropertiesRPC()
end

function Test:Precondition_StartSDL_With_DISALLOWED_SetGlobalProperties()
  StartSDL(config.pathToSDL, config.ExitOnCrash, self)
end

function Test:Precondition_initHMI()
  self:initHMI()
end

function Test:Precondition_initHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile()
  self:connectMobile()
end

function Test:Precondition_CreateSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[Test]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_RegisterApplication()
 local corId = self.mobileSession:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
end

function Test:TestStep_SetGlobalProperties_resultCode_DISALLOWED()
     local cid = self.mobileSession:SendRPC("SetGlobalProperties",
        {
          menuTitle = "Menu Title",
          timeoutPrompt = 
          {
            {
              text = "Timeout prompt",
              type = "PRE_RECORDED" 
            }
          },
          vrHelp = 
          {
            {
              position = 1,
              image = 
              {
                value = "action.png",
                imageType = "DYNAMIC"
              },
              text = "VR help item"
            }
          },
          menuIcon = 
          {
            value = "action.png",
            imageType = "DYNAMIC"
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
       EXPECT_RESPONSE(cid, {success = false, resultCode = "DISALLOWED"})
      end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Restore_preloaded()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end 

function Test.Postcondition_SDLStop()
  StopSDL()
end
