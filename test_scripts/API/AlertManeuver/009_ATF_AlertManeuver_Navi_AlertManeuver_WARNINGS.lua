---------------------------------------------------------------------------------------------
-- Requirement summary:
-- SDL must send WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one HMI-portions
--
-- Description:
-- test is intended to check that SDL sends WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one HMI-portions
-- in this particular test it is checked case when HMI sends WARNINGS to TTS.Speak and ANY successfull result code to Navi.AlertManeuver
--
-- 1. Used preconditions:
-- App is registered and activated SUCCESSFULLY
-- 2. Performed steps:
-- MOB -> SDL: AlertManeuver
-- HMI -> SDL: TTS.Speak (WARNINGS), Navi.AlertManeuver (cyclically checked cases for result codes SUCCESS, WARNINGS, WRONG_LANGUAGE, RETRY, SAVED)
--
-- Expected result:
-- SDL -> HMI: resends AlertManeuver
-- SDL -> MOB: AlertManeuver (result code: WARNINGS, success: true)
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
testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"},"AlertManeuver")

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

commonSteps:PutFile("Precondition_PutFile", "icon.png")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

local resultCodes = {"SUCCESS", "WARNINGS", "WRONG_LANGUAGE", "RETRY", "SAVED"}

for i=1,#resultCodes do
  Test["TestStep__AlertManeuver_Navi_AlertManeuver_WARNINGS_TTS_Apeak_"..resultCodes[i]] = function(self)
    local cor_id_alertmaneuver = self.mobileSession:SendRPC("AlertManeuver",
    {ttsChunks =
        {{
          text ="FirstAlert",
          type ="TEXT",
        },
        {
          text ="SecondAlert",
          type ="TEXT",
      }},
      softButtons =
        {{
          type = "BOTH",
          text = "Close",
          image =
          {
            value = "icon.png",
            imageType = "DYNAMIC",
          },
          isHighlighted = true,
          softButtonID = 821,
          systemAction = "DEFAULT_ACTION",
      }}
    })

    EXPECT_HMICALL("Navigation.AlertManeuver",
    {
      softButtons =
        {{
          type = "BOTH",
          text = "Close",
          image = { imageType = "DYNAMIC"},
          isHighlighted = true,
          softButtonID = 821,
          systemAction = "DEFAULT_ACTION",
      }},
      appID = self.applications[config.application1.registerAppInterfaceParams.appName]
    })
    :ValidIf(function(_,data)
      local value_Icon = storagePath .. "icon.png"
      if (string.match(data.params.softButtons[1].image.value, "%S*" .. "("..string.sub(storagePath, 2).."icon.png)" .. "$") == nil ) then
        print("\27[31m value of menuIcon is WRONG. Expected: ~".. value_Icon .. "; Real: " .. data.params.softButtons[1].image.value .. "\27[0m")
        return false
      else
        return true
      end
    end)
    :Do(function(_,data) self.hmiConnection:SendResponse(data.id, "Navigation.AlertManeuver", resultCodes[i], { }) end)

    EXPECT_HMICALL("TTS.Speak",
    {ttsChunks =
        {{
        text ="FirstAlert", type ="TEXT"},
      {text ="SecondAlert", type ="TEXT"}},
      speakType = "ALERT_MANEUVER",
      appID = self.applications[config.application1.registerAppInterfaceParams.appName]
    })
    :Do(function(_,data)
      self.hmiConnection:SendNotification("TTS.Started",{ })
      local function ttsSpeakResponse()
        self.hmiConnection:SendResponse (data.id, data.method, "WARNINGS", {})
      end
      RUN_AFTER(ttsSpeakResponse, 1000)
    end)

    EXPECT_RESPONSE(cor_id_alertmaneuver, { success = true, resultCode = "WARNINGS"})
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