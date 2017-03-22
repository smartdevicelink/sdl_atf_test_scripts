---------------------------------------------------------------------------------------------
-- Requirement summary:
-- SDL must send WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one HMI-portions
--
-- Description:
-- test is intended to check that SDL sends UNSUPPORTED_RESOURCE (success:true) to mobile app in case HMI respond: WARNINGS one HMI-portion and UNSUPPORTED_RESOURCE to another one
-- in particular test it is checked case when TTS.SetGlobalProperties with WARNINGS and to UI.SetGlobalProperties with UNSUPPORTED_RESOURCE (success:true)
--
-- 1. Used preconditions:
-- HMI does not respond to UI.IsReady
-- App is registered and activated SUCCESSFULLY
-- 2. Performed steps:
-- MOB -> SDL: sends SetGlobalProperties
-- HMI -> SDL: UI.SetGlobalProperties (UNSUPPORTED_RESOURCE), TTS.SetGlobalProperties (WARNINGS)
--
-- Expected result:
-- SDL -> HMI: resends UI.SetGlobalProperties and TTS.SetGlobalProperties
-- SDL -> MOB: SetGlobalProperties (resultcode: UNSUPPORTED_RESOURCE, success: true)
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
local testCasesForUI_IsReady = require('user_modules/IsReady_Template/testCasesForUI_IsReady')
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
  testCasesForUI_IsReady.InitHMI_onReady_without_UI_IsReady(self, 1)
  EXPECT_HMICALL("UI.IsReady")
  -- Do not send HMI response of UI.IsReady
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

function Test:TestStep_SetGlobalProperties_WARNINGS_to_TTS_SGP_and_UNSUPPORTED_RESOURCE_to_UI_SGP()
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
    menuIcon = { value = "action.png", imageType = "DYNAMIC"},
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
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, "TTS.SetGlobalProperties", "WARNINGS", {}) end)

  EXPECT_HMICALL("UI.SetGlobalProperties",
  {
    vrHelpTitle = "VR help title",
    vrHelp =
      {{
        position = 1,
        image = { imageType = "DYNAMIC"},
        text = "VR help item"
    }},
    menuTitle = "Menu Title",
    menuIcon = { imageType = "DYNAMIC" },
    keyboardProperties = { keyboardLayout = "QWERTY", language = "EN-US"},
    appID = self.applications[config.application1.registerAppInterfaceParams.appName]
  })
  :ValidIf(function(_,data)
    local value_Icon = storagePath .. "action.png"
    if (string.match(data.params.vrHelp[1].image.value, "%S*" .. "("..string.sub(storagePath, 2).."action.png)" .. "$") == nil ) then
      print("\27[31m value of vrHelp.Image is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.vrHelp[1].image.value .. "\27[0m")
      return false
    else
      return true
    end
  end)
  :Do(function(_,data) self.hmiConnection:SendResponse(data.id, "UI.SetGlobalProperties", "UNSUPPORTED_RESOURCE", {info = "unsupported resource"}) end)

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