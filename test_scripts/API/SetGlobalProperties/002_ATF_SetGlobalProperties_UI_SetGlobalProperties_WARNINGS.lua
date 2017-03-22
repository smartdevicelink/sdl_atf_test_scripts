---------------------------------------------------------------------------------------------
-- Requirement summary:
-- SDL must send WARNINGS (success:true) to mobile app in case HMI respond WARNINGS at least to one HMI-portions
--
-- Description:
-- test is intended to check that SDL sends WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one component of RPC
-- in this test case when UI.SetGlobalProperties gets WARNINGS and TTS.SetGlobalProperties gets ANY successfull result code is checked
--
-- 1. Used preconditions: App is registered and activated SUCCESSFULLY
-- 2. Performed steps:
-- MOB -> SDL: sends SetGlobalProperties
-- HMI -> SDL: VR.SetGlobalProperties (WARNINGS), TTS.SetGlobalProperties (cyclically checked cases fo result codes SUCCESS, WARNINGS, WRONG_LANGUAGE, RETRY, SAVED)
--
-- Expected result:
-- SDL -> HMI: resends UI.SetGlobalProperties and TTS.SetGlobalProperties
-- SDL -> MOB: SetGlobalProperties (resultcode: WARNINGS, success: true)
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
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

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

local resultCodes = {"SUCCESS", "WARNINGS", "WRONG_LANGUAGE", "RETRY", "SAVED"}

for i=1,#resultCodes do
  Test["TestStep_SetGlobalProperties_UI_SGP_WARNINGS_and_VR_SGP_"..resultCodes[i]] = function(self)
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
      helpPrompt = {{ text = "Help prompt", type = "TEXT"}},
      vrHelpTitle = "VR help title",
      keyboardProperties = { keyboardLayout = "QWERTY", language = "EN-US" }
    })

    EXPECT_HMICALL("TTS.SetGlobalProperties",
    {
      timeoutPrompt = {{ text = "Timeout prompt", type = "TEXT"}},
      helpPrompt = {{ text = "Help prompt", type = "TEXT"}},
      appID = self.applications[config.application1.registerAppInterfaceParams.appName]
    })
    :Do(function(_,data) self.hmiConnection:SendResponse(data.id, "TTS.SetGlobalProperties", resultCodes[i], {}) end)

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
      menuIcon = { imageType = "DYNAMIC"},
      keyboardProperties = { keyboardLayout = "QWERTY", language = "EN-US"},
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

    EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS"})
    EXPECT_NOTIFICATION("OnHashChange")
  end
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