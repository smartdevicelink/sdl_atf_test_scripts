---------------------------------------------------------------------------------------------
-- Requirement summary:
-- SDL must send WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one HMI-portions
-- [TTS Interface] HMI does NOT respond to IsReady and mobile app sends RPC that must be splitted
--
-- Description:
-- test is intended to check that SDL sends UNSUPPORTED_RESOURCE (success:true) to mobile app in case HMI respond: WARNINGS one HMI-portion and UNSUPPORTED_RESOURCE to another one
-- in this particular case check that SDL sends 'UNSUPPORTED_RESOURCE, success:true' + '*info: <message_from_HMI>* in case it gets
-- TTS.SetGlobalProperties (UNSUPPORTED_RESOURCE), UI.SetGlobalProperties (WARNINGS) grom HMI
--
-- 1. Used preconditions:
-- HMI does not respond to TTS.IsReady
-- App is registered and activated SUCCESSFULLY
-- 2. Performed steps:
-- MOB -> SDL: sends SetGlobalProperties
-- HMI -> SDL: TTS.SetGlobalProperties (UNSUPPORTED_RESOURCE), UI.SetGlobalProperties (WARNINGS)
--
-- Expected result:
-- SDL -> HMI: resends TTS.SetGlobalProperties and UI.SetGlobalProperties
-- SDL -> MOB: SetGlobalProperties (result code: UNSUPPORTED_RESOURCE, success: true)
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
-- ToDo (vvvakulenko): remove after issue "ATF does not stop HB timers by closing session and connection" is resolved
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForTTS_IsReady = require('user_modules/IsReady_Template/testCasesForTTS_IsReady')
local mobile_session = require('mobile_session')
config.SDLStoragePath = commonPreconditions:GetPathToSDL() .. "storage/"

--[[ Local Variables ]]
local storagePath = config.SDLStoragePath..config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"
local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"},"SetGlobalProperties")

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_initHMI')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_InitHMI_OnReady()
  testCasesForTTS_IsReady.InitHMI_onReady_without_TTS_IsReady(self, 1)
  EXPECT_HMICALL("TTS.IsReady")
  -- Do not send HMI response of TTS.IsReady
end

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

commonSteps:RegisterAppInterface("Precondition_RegisterAppInterface")

function Test:Precondition_ActivationApp()
  local request_id = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications[config.application1.registerAppInterfaceParams.appName]})
  EXPECT_HMIRESPONSE(request_id)
  :Do(function(_,data)
    if (data.result.isSDLAllowed ~= true) then
      local request_id1 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(request_id1)
      :Do(function(_,_)
        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = ServerAddress}})
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data1)
          self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
      end)
    end
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
end

commonSteps:PutFile("Precondition_PutFile", "action.png")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_SetGlobalProperties_WARNINGS_to_UI_SGP_and_UNSUPPORTED_RESOURCE_to_TTS_SGP()
  local cid = self.mobileSession:SendRPC("SetGlobalProperties",
  {
    menuTitle = "Menu Title",
    timeoutPrompt = {{ text = "Timeout prompt", type = "TEXT" }},
    vrHelp =
      {{
        position = 1,
        image = { value = "action.png", imageType = "DYNAMIC"},
        text = "VR help item"
    }},
    menuIcon = { value = "action.png", imageType = "DYNAMIC" },
    helpPrompt = {{ text = "Help prompt", type = "TEXT" }},
    vrHelpTitle = "VR help title",
    keyboardProperties = { keyboardLayout = "QWERTY", language = "EN-US"}
  })

  EXPECT_HMICALL("TTS.SetGlobalProperties",
  {
    timeoutPrompt = {{ text = "Timeout prompt", type = "TEXT" }},
    helpPrompt = {{ text = "Help prompt", type = "TEXT" }},
    appID = self.applications[config.application1.registerAppInterfaceParams.appName]
  })
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, "TTS.SetGlobalProperties", "UNSUPPORTED_RESOURCE", {info = "unsupported resource"}) end)

  EXPECT_HMICALL("UI.SetGlobalProperties",
  {
    vrHelpTitle = "VR help title",
    vrHelp = {{ position = 1, text = "VR help item" }},
    menuTitle = "Menu Title",
    menuIcon = { imageType = "DYNAMIC"},
    keyboardProperties = { keyboardLayout = "QWERTY", language = "EN-US" },
    appID = self.applications[config.application1.registerAppInterfaceParams.appName]
  })
  :ValidIf(function(_,data)
    local value_Icon = storagePath .. "action.png"
    if (string.match(data.params.menuIcon.value, "%S*" .. "("..string.sub(storagePath, 2).."action.png)" .. "$") == nil ) then
      print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.menuIcon.value .. "\27[0m")
      return false
    else
      return true
    end
  end)
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, "UI.SetGlobalProperties", "WARNINGS", {}) end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "unsupported resource"})
  EXPECT_NOTIFICATION("OnHashChange")
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_preloaded_file()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
