---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GENERIC_ERROR]: SDL behavior in case HMI sends invalid response AND SDL must transfer this response to mobile app
-- [PerformAudioPassThru] Speak (<errorCode>) + UI.PerformAudioPassThru (SUCCESS)
-- [HMI RPC validation]: SDL must send GENERIC_ERROR to mobile app in case SDL cuts off fake params from RPC and this RPC becomes invalid
-- [HMI API] UI.PerformAudioPassThru request/response
-- [HMI API] TTS.Speak request/response
-- [Mobile API] PerformAudioPassThru request/response
-- [HMI_API] [MOBILE_API] The "audioPassThruIcon" param at "ImageFieldName" struct
--
-- Description:
-- In case HMI sends invalid response by any reason that SDL must transfer it to mobile app
-- (possible reasons to invalidate response include: mandatory params are missing, params out of bounds, invalid json, incorrect combination of params or
-- SDL has cut fake parameters from response)
-- SDL must: respond GENERIC_ERROR (success:false, <info>) to mobile app
-- (info: "Invalid message received from vehicle" - if invalid response sent from HMI)
--
-- 1. Used preconditions
-- 1.1. PerformAudioPassThru RPC is allowed by policy
-- 1.2. All params used in PerformAudioPassThru_request are present and within bounds
-- 1.3. AudioPassThruIcon exists at apps sub-directory of AppStorageFolder (value from ini file)
--
-- 2. Performed steps
-- Send PerformAudioPassThru (audioPassThruIcon, other params)
-- HMI sends invalid response
--
-- Expected result:
-- SDL sends UI.PerformAudioPassThru (audioPassThruIcon, other params) to HMI
-- SDL sends TTS.Speak to HMI
-- SDL sends to mobile PerformAudioPassThru (GENERIC_ERROR, success:false, info) if invalid HMI response sent to UI.PerformAudioPassThru part or 
-- SDL sends to mobile PerformAudioPassThru (WARNINGS, success:true) if invalid HMI response sent to TTS.Speak part
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPostconditions = require('user_modules/shared_testcases/commonPreconditions')
local testCasesForPerformAudioPassThru = require('user_modules/shared_testcases/testCasesForPerformAudioPassThru')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ Local variables ]]
local invalid_data = {
  {value = 123, descr = "wrongtype"},
  {value = "TESTING" , descr = "nonexisting_enum"},
  {value = "", descr = "missing"}
}

--[[Local functions]]

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
config.defaultProtocolVersion = 2

testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"},"PerformAudioPassThru")

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

commonSteps:PutFile("Precondition_PutFile_With_Icon", "icon.png")

function Test:Precondition_Check_audioPassThruIcon_Existence()
  testCasesForPerformAudioPassThru.Check_audioPassThruIcon_Existence(self, "icon.png")
end

function Test:Precondition_ActivateApp()
  testCasesForPerformAudioPassThru:ActivateAppDiffPolicyFlag(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
for i =1, #invalid_data do
  Test["TestStep_GENERIC_ERROR_PerformAudioPassThru_UI_HMI_replies_" .. invalid_data[i].descr] = function(self)
    local CorIdPerformAudioPassThru= self.mobileSession:SendRPC("PerformAudioPassThru",
      {
        initialPrompt = {{text = "Makeyourchoice",type = "TEXT"}},
        audioPassThruDisplayText1 = "DisplayText1",
        audioPassThruDisplayText2 = "DisplayText2",
        samplingRate = "16KHZ",
        maxDuration = 2000,
        bitsPerSample = "8_BIT",
        audioType = "PCM",
        muteAudio = true,
        audioPassThruIcon =
        {
          value = "icon.png",
          imageType = "STATIC"
        }
      })
    EXPECT_HMICALL("TTS.Speak",
      {
        speakType = "AUDIO_PASS_THRU",
        ttsChunks = {{text = "Makeyourchoice", type = "TEXT"}},
        appID = self.applications[config.application1.registerAppInterfaceParams.appName]
      })
    :Do(function(_,data)
        self.hmiConnection:SendNotification("TTS.Started",{})

        local function ttsSpeakResponse()
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS")
          self.hmiConnection:SendNotification("TTS.Stopped")
        end
        RUN_AFTER(ttsSpeakResponse, 1000)
    end)

    EXPECT_HMICALL("UI.PerformAudioPassThru",
      {
        appID = self.applications[config.application1.registerAppInterfaceParams.appName],
        audioPassThruDisplayTexts = {
          {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
          {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},
        },
        maxDuration = 2000,
        muteAudio = true,
        audioPassThruIcon =
        {
          imageType = "STATIC",
          value = "icon.png"
        }
      })
    :Do(function(_,data)
        self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"UI.PerformAudioPassThru", "code":"'..tostring(invalid_data[i].value)..'"}}')
    end)

    if
    (self.appHMITypes["NAVIGATION"] == true) or
    (self.appHMITypes["COMMUNICATION"] == true) or
    (self.isMediaApplication == true) then

      EXPECT_NOTIFICATION("OnHMIStatus",
        {hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Times(2)
    else
      EXPECT_NOTIFICATION("OnHMIStatus"):Times(0)
    end

    self.mobileSession:ExpectResponse(CorIdPerformAudioPassThru, {success = false, resultCode = "GENERIC_ERROR", info ="Invalid message received from vehicle" })
    EXPECT_NOTIFICATION("OnHashChange",{}):Times(0)
  end
end

for i =1, #invalid_data do
  Test["TestStep_WARNINGS_PerformAudioPassThru_TTS_HMI_replies_" .. invalid_data[i].descr] = function(self)
    local CorIdPerformAudioPassThru= self.mobileSession:SendRPC("PerformAudioPassThru",
      {
        initialPrompt = {{text = "Makeyourchoice",type = "TEXT"}},
        audioPassThruDisplayText1 = "DisplayText1",
        audioPassThruDisplayText2 = "DisplayText2",
        samplingRate = "16KHZ",
        maxDuration = 2000,
        bitsPerSample = "8_BIT",
        audioType = "PCM",
        muteAudio = true,
        audioPassThruIcon =
        {
          value = "icon.png",
          imageType = "STATIC"
        }
      })
    EXPECT_HMICALL("TTS.Speak",
      {
        speakType = "AUDIO_PASS_THRU",
        ttsChunks = {{text = "Makeyourchoice", type = "TEXT"}},
        appID = self.applications[config.application1.registerAppInterfaceParams.appName]
      })
    :Do(function(_,data)
        self.hmiConnection:SendNotification("TTS.Started",{})

        local function ttsSpeakResponse()
          self.hmiConnection:Send('{"id":'..tostring(data.id)..',"jsonrpc":"2.0","result":{"method":"TTS.Speak", "code":"'..tostring(invalid_data[i].value)..'"}}')
          self.hmiConnection:SendNotification("TTS.Stopped")
        end

        RUN_AFTER(ttsSpeakResponse, 1000)
    end)

    EXPECT_HMICALL("UI.PerformAudioPassThru",
      {
        appID = self.applications[config.application1.registerAppInterfaceParams.appName],
        audioPassThruDisplayTexts = {
          {fieldName = "audioPassThruDisplayText1", fieldText = "DisplayText1"},
          {fieldName = "audioPassThruDisplayText2", fieldText = "DisplayText2"},
        },
        maxDuration = 2000,
        muteAudio = true,
        audioPassThruIcon =
        {
          imageType = "STATIC",
          value = "icon.png"
        }
      })
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, "UI.PerformAudioPassThru", "SUCCESS", {})
      end)

    if
    (self.appHMITypes["NAVIGATION"] == true) or
    (self.appHMITypes["COMMUNICATION"] == true) or
    (self.isMediaApplication == true) then

      EXPECT_NOTIFICATION("OnHMIStatus",
        {hmiLevel = "FULL", audioStreamingState = "ATTENUATED", systemContext = "MAIN"},
        {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
      :Times(2)
    else
      EXPECT_NOTIFICATION("OnHMIStatus"):Times(0)
    end

    self.mobileSession:ExpectResponse(CorIdPerformAudioPassThru, {success = true, resultCode = "WARNINGS"})
    EXPECT_NOTIFICATION("OnHashChange",{}):Times(0)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_preloaded_pt_File()
  commonPostconditions:RestoreFile("sdl_preloaded_pt.json")
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
