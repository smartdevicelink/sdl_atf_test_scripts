---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GeneralResultCode] DISALLOWED. A request comes with appID which has "null" permissions in Policy Table
-- [RegisterAppInterface] Allow only RegisterAppInterface for the application with NULL policies
--
-- Description:
-- In case PolicyTable has "<appID>": "null" in the Local PolicyTable for the specified application with appID,
-- PoliciesManager must return DISALLOWED resultCode and success:"false" to any RPC requested by such <appID> app.
-- Performed steps
-- Pre_step. Add in sdl_preloaded_pt application id with NULL policy
-- 1. MOB-SDL - Open new session and register application in this session
-- 2. MOB-SDL - send the list of RPCs
-- 3. SDL responce, success = false, resultCode = "DISALLOWED"
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local json = require("modules/json")
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local ptu_table

--[[ Local Functions ]]
local function ptsToTable(pts_f)
  local f = io.open(pts_f, "r")
  local content = f:read("*all")
  f:close()
  return json.decode(content)
end

local function updatePTU(ptu)
  if ptu.policy_table.consumer_friendly_messages.messages then
    ptu.policy_table.consumer_friendly_messages.messages = nil
  end
  ptu.policy_table.module_config.preloaded_pt = nil
  ptu.policy_table.device_data = nil
  ptu.policy_table.module_meta = nil
  ptu.policy_table.usage_and_error_counts = nil
  ptu.policy_table.app_policies["0000001"] = { keep_context = false, steal_focus = false, priority = "NONE", default_hmi = "NONE" }
  ptu.policy_table.app_policies["0000001"]["groups"] = { "Base-4", "Base-6" }
  ptu.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  --
  ptu.policy_table.app_policies["123abc"] = json.null
  ptu.policy_table.vehicle_data = nil
end

local function storePTUInFile(ptu, ptu_file_name)
  local f = io.open(ptu_file_name, "w")
  f:write(json.encode(ptu))
  f:close()
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ActivateApp()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"] })
  EXPECT_HMIRESPONSE(requestId1)
  :Do(function(_, data1)
      if data1.result.isSDLAllowed ~= true then
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(requestId2)
        :Do(function()
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })
            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_, data2)
                self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
              end)
            :Times(1)
          end)
      end
    end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_, d)
      ptu_table = ptsToTable(d.params.file)
    end)
end

function Test:PTU()
  local policy_file_name = "PolicyTableUpdate"
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local ptu_file_name = os.tmpname()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name})
      updatePTU(ptu_table)
      storePTUInFile(ptu_table, ptu_file_name)
      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function()
          local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name}, ptu_file_name)
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_, d)
              self.hmiConnection:SendResponse(d.id, "BasicCommunication.SystemRequest", "SUCCESS", { })
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. "/" .. policy_file_name })
            end)
          EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)
  os.remove(ptu_file_name)
end

function Test:Pecondition_StartNewSession()
  self.mobileSession2 = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:Pecondition_RegisterNewApp()
  config.application2.registerAppInterfaceParams.appName = "App_test"
  config.application2.registerAppInterfaceParams.fullAppID = "123abc"
  local correlationId = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  -- self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", systemContext = "MAIN", audioStreamingState = "NOT_AUDIBLE" })
  self.mobileSession2:ExpectResponse(correlationId, { success = true })
end

-- [[ Test ]]
commonFunctions:newTestCasesGroup("Test")

for _, v in pairs({ "Alert", "EndAudioPassThru", "Show" }) do
  Test[v .. "_DISALLOWED"] = function(self)
    local correlationId = self.mobileSession2:SendRPC(v, {})
    self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
  end
end

function Test:AddCommand_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "AddCommand",
    {
      cmdID = 1,
      vrCommands = { "vrCommands_12" },
      menuParams = {position = 1, menuName ="Command 1"}
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:DeleteCommand_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "DeleteCommand",
    {
      cmdID = 1
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:Slider_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "Slider",
    {
      numTicks = 3,
      position = 2,
      sliderHeader ="sliderHeader",
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:ScrollableMessage_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "ScrollableMessage",
    {
      scrollableMessageBody = "abc"
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:PerformAudioPassThru_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "PerformAudioPassThru",
    {
      samplingRate ="8KHZ",
      maxDuration = 2000,
      bitsPerSample ="8_BIT",
      audioType ="PCM",
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:Speak_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "Speak",
    {
      ttsChunks = {
        {
          text ="a",
          type ="TEXT"
        }
      }
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:SubscribeButton_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "SubscribeButton",
    {
      buttonName = "PRESET_0"
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:PerformInteraction_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "PerformInteraction",
    {
      initialText = "StartPerformInteraction",
      initialPrompt = {
        {
          text = "Makeyourchoice",
          type = "TEXT",
        }
      },
      interactionMode = "BOTH",
      interactionChoiceSetIDList = {2},
      helpPrompt = {
        {
          text = "Choosethevarianton",
          type = "TEXT",
        }
      },
      interactionLayout = "ICON_ONLY"
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:CreateInteractionChoiceSet_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "CreateInteractionChoiceSet",
    {
      interactionChoiceSetID = 1002,
      choiceSet =
      {

        {
          choiceID = 1002,
          menuName ="Choice1002",
          vrCommands =
          {
            "Choice1002",
          }
        }
      }
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:DeleteInteractionChoiceSet_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "DeleteInteractionChoiceSet",
    {
      interactionChoiceSetID = 1002
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:AddSubMenu_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "AddSubMenu",
    {
      menuID = 1000,
      menuName = "SubMenupositive"
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:DeleteSubMenu_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "DeleteSubMenu",
    {
      menuID = 1000
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:SetMediaClockTimer_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "SetMediaClockTimer",
    {
      updateMode = "COUNTDOWN"

    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:PutFile_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "PutFile",
    {
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = false,
      systemFile = false
    }, "files/icon.png" )
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:ListFiles_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "ListFiles", {})
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:ChangeRegistration_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "ChangeRegistration",
    {
      language = "EN-US",
      hmiDisplayLanguage ="EN-US"
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:SetAppIcon_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "SetAppIcon",
    {
      syncFileName = "icon.png"
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:DeleteFile_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "DeleteFile",
    {
      syncFileName ="icon.png"
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:SetGlobalProperties_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "SetGlobalProperties",
    {
      menuTitle = "Menu Title"
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:ResetGlobalProperties_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "ResetGlobalProperties",

    {
      properties =
      {
        "VRHELPTITLE",
        "MENUNAME",
        "MENUICON",
        "KEYBOARDPROPERTIES",
        "VRHELPITEMS",
        "HELPPROMPT",
        "TIMEOUTPROMPT"
      }
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:SetDisplayLayout_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "SetDisplayLayout",
    {
      displayLayout = "ONSCREEN_PRESETS"
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:SystemRequest_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC( "SystemRequest",
    {
      requestType = "NAVIGATION",
      fileName = "icon.png"
    })
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

function Test:UnregisterAppInterface_DISALLOWED()
  local correlationId = self.mobileSession2:SendRPC("UnregisterAppInterface", {})
  self.mobileSession2:ExpectResponse(correlationId, { success = false, resultCode = "DISALLOWED" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
