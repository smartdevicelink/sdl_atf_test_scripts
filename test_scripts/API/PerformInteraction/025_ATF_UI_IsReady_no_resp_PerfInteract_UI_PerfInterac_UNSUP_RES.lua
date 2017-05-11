---------------------------------------------------------------------------------------------
-- Requirement summary:
-- SDL must send WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one HMI-portions
-- [UI Interface] HMI does NOT respond to IsReady and mobile app sends RPC that must be splitted
--
-- Description:
-- test is intended to check that SDL sends WARNINGS (success:true) to mobile app in case HMI respond WARNINGS to at least one HMI-portions
-- in this particular test it is checked case when UI.PerformInteraction gets UNSUPPORTED_RESOURCE and VR.PerformInteraction gets WARNINGS from HMI
--
-- 1. Used preconditions:
-- HMI does not respond to UI.IsReady
-- App is registered and activated SUCCESSFULLY
-- 2. Performed steps:
-- MOB -> SDL: sends PerformInteraction
-- HMI -> SDL: UI.PerformInteraction (UNSUPPORTED_RESOURCE), VR.PerformInteraction (WARNINGS)
--
-- Expected result:
-- SDL -> HMI: resends VR.PerformInteraction and UI.PerformInteraction
-- SDL -> MOB: PerformInteraction (result code: UNSUPPORTED_RESOURCE, success: true)
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

--[[ Local Variables ]]
local ServerAddress = commonFunctions:read_parameter_from_smart_device_link_ini("ServerAddress")

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
testCasesForPolicyTable:precondition_updatePolicy_AllowFunctionInHmiLeves({"BACKGROUND", "FULL", "LIMITED"},"PerformInteraction")

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

commonSteps:PutFile("Precondition_PutFile", "icon.png")

function Test:Precondition_CreateInteractionChoiceSet()
  local cid = self.mobileSession:SendRPC("CreateInteractionChoiceSet",
  {
    interactionChoiceSetID = 1001,
      choiceSet = {{
        choiceID = 1001,
        menuName ="Choice1001",
        vrCommands = { "Choice1001" },
        image = { value ="icon.png", imageType ="DYNAMIC" },
    }}
  })

  EXPECT_HMICALL("VR.AddCommand",
  {
    cmdID = 1001,
    appID = self.applications[config.application1.registerAppInterfaceParams.appName],
    type = "Choice",
    vrCommands = {"Choice1001"}
  })
  :Do(function(_,data2)
    self.hmiConnection:SendResponse(data2.id, "VR.AddCommand", "SUCCESS", {})
  end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_UI_PerformInteraction_UNSUPPORTED_RESOURCE()
  local cor_id = self.mobileSession:SendRPC("PerformInteraction",
    {
      initialText = "StartPerformInteraction",
      initialPrompt = {{ text = "Makeyourchoice", type = "TEXT" }},
      interactionMode = "BOTH",
      interactionChoiceSetIDList = {1001},
      timeout = 5000
    })

    EXPECT_HMICALL("VR.PerformInteraction",
    {
      initialPrompt = {{ text = "Makeyourchoice", type = "TEXT" }},
      timeout = 5000,
      appID = self.applications[config.application1.registerAppInterfaceParams.appName]
    })
    :Do(function(_,data3)
      self.hmiConnection:SendNotification("TTS.Started")
      self.hmiConnection:SendNotification("VR.Started")
      self.hmiConnection:SendResponse(data3.id, "VR.PerformInteraction", "WARNINGS", {choiceID = 1001})
      self.hmiConnection:SendNotification("TTS.Stopped")
      self.hmiConnection:SendNotification("VR.Stopped")
    end)

    EXPECT_HMICALL("UI.PerformInteraction",
    {
      initialText = {fieldName = "initialInteractionText", fieldText = "StartPerformInteraction" },
      timeout = 5000,
      appID = self.applications[config.application1.registerAppInterfaceParams.appName]
    })
    :Do(function(_,data4)
      local function SendOnSystemContext(Input_SystemContext)
        self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications[config.application1.registerAppInterfaceParams.appName], systemContext = Input_SystemContext})
      end
      local function uiResponse()
        self.hmiConnection:SendError(data4.id, "UI.PerformInteraction", "UNSUPPORTED_RESOURCE", "unsupported resource")
        SendOnSystemContext ("VRSESSION")
        SendOnSystemContext ("MAIN")
      end
      RUN_AFTER(uiResponse, 10)
    end)

  EXPECT_RESPONSE(cor_id, { success = true, resultCode = "UNSUPPORTED_RESOURCE", info = "unsupported resource"} )
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
