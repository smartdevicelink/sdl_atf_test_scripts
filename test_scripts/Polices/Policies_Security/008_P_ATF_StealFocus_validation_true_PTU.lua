-- Requirement summary:
-- [[Policies]] <app_id> policies and "steal_focus" validation.

-- Description:
-- In case the <app id> policies are assigned to the application, PoliciesManager must validate "steal_focus" section and in case "steal_focus:true",
-- PoliciesManager must allow SDL to pass the RPC that contains the soft button with STEAL_FOCUS SystemAction.
-- Note: in sdl_preloaded_pt. json, should be "steal_focus:true".
-- Note: in ptu.json, should be "steal_focus:true".

-- 1. RunSDL. InitHMI. InitHMI_onReady. ConnectMobile. StartSession.
-- 2. Run/Finish PTU.
-- 3. Activiate Application for allow sendRPC Alert
-- 4. MOB-SDL: SendRPC with soft button, STEAL_FOCUS in SystemAction
-- Expected result
-- SDL must response: success = true, resultCode = "SUCCESS
--------------------------------------------------------------------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General Precondition before ATF start]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')

--[[ Local Functions ]]
local function SendOnSystemContext(self, ctx)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = ctx })
end

local function policyUpdate(self)
  local pathToSnaphot = nil
  EXPECT_HMICALL ("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      pathToSnaphot = data.params.file
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.PolicyUpdate", "SUCCESS", {})
    end)
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {url = "http://policies.telematics.ford.com/api/policies"}}})
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          url = "http://policies.telematics.ford.com/api/policies",
          appID = self.applications ["Test Application"],
          fileName = "sdl_snapshot.json"
        },
        pathToSnaphot
      )
    end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
  :Do(function(_,_)
      local CorIdSystemRequest = self.mobileSession:SendRPC ("SystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "sdl_snapshot.json"
        },
        pathToSnaphot
      )
      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
        end)
      EXPECT_RESPONSE(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
            {
              policyfile = "/tmp/fs/mp/images/ivsu_cache/ptu.json"
            })
        end)
      :Do(function(_,_)
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
        end)
    end)
end

--[[Test]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PTU_ASSIGN_Default_Policies()
  policyUpdate(self, "/tmp/fs/mp/images/ivsu_cache/ptu.json")
end

function Test:TestStep_ActivateApplication()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId)
  :Do(function(_,data)
      if data.result.isSDLAllowed ~= true then
        RequestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
        EXPECT_HMIRESPONSE(RequestId)
        :Do(function(_,_)
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_,_)
                self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              end)
            :Times(2)
          end)
      end
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
end

function Test:TestStep_SendRPC_with_StealFocus_ValueTrue()
  local CorIdAlert = self.mobileSession:SendRPC("Alert",
    {
      alertText1 = "alertText1",
      alertText2 = "alertText2",
      alertText3 = "alertText3",
      ttsChunks =
      {
        {
          text = "TTSChunk",
          type = "TEXT",
        }
      },
      duration = 5000,
      playTone = true,
      progressIndicator = true,
      softButtons =
      {
        {
          type = "IMAGE",
          image =
          {
            value = "icon.png",
            imageType = "STATIC",
          },
          softButtonID = 5,
          systemAction = "STEAL_FOCUS",
        },
      }

    })
  local AlertId
  EXPECT_HMICALL("UI.Alert",
    {
      appID = self.applications["Test Application"],
      alertStrings =
      {
        {fieldName = "alertText1", fieldText = "alertText1"},
        {fieldName = "alertText2", fieldText = "alertText2"},
        {fieldName = "alertText3", fieldText = "alertText3"}
      },
      alertType = "BOTH",
      duration = 0,
      progressIndicator = true,
      softButtons =
      {
        {
          type = "IMAGE",
          softButtonID = 5,
          systemAction = "STEAL_FOCUS",
        },
      }
    })
  :Do(function(_,data)
      SendOnSystemContext(self,"ALERT")
      AlertId = data.id
      local function alertResponse()
        self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })
        SendOnSystemContext(self,"MAIN")
      end
      RUN_AFTER(alertResponse, 3000)
    end)
  local SpeakId
  EXPECT_HMICALL("TTS.Speak",
    {
      ttsChunks =
      {
        {
          text = "TTSChunk",
          type = "TEXT"
        }
      },
      speakType = "ALERT",
      playTone = true
    })
  :Do(function(_,data)
      self.hmiConnection:SendNotification("TTS.Started")
      SpeakId = data.id
      local function speakResponse()
        self.hmiConnection:SendResponse(SpeakId, "TTS.Speak", "SUCCESS", { })
        self.hmiConnection:SendNotification("TTS.Stopped")
      end
      RUN_AFTER(speakResponse, 2000)

    end)
  :ValidIf(function(_,data)
      if #data.params.ttsChunks == 1 then
        return true
      else
        print("ttsChunks array in TTS.Speak request has wrong element number. Expected 1")
        return false
      end
    end)
  EXPECT_RESPONSE(CorIdAlert, {success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
Test["StopSDL"] = function()
  StopSDL()
end
