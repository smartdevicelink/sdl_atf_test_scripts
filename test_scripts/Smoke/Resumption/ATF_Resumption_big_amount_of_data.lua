--  Requirement summary:
--  [Data Resumption]: Data Persistance
--
--  Description:
--  Check that SDL perform resumption with a big amount of data
--  after unexpected disconnect.
--
--  1. Used precondition
--  App is registered and activated on HMI.
--  20 SubMenus, 20 commands, 20 choice sets are added successfully.
--
--  2. Performed steps
--  Turn off transport.
--  Turn on transport.
--
--  Expected behavior:
--  1. App is unregistered successfully.
--     App is registered successfully,  SDL sends OnAppRegistered on HMI with "resumeVrGrammars"=true.
--     SDL resumes all app's data and sends BC.ActivateApp to HMI. App gets FULL HMI Level
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.isMediaApplication = true

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonStepsResumption = require('user_modules/shared_testcases/commonStepsResumption')
local mobile_session = require('mobile_session')

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- [[Local variables]]
local default_app_params = config.application1.registerAppInterfaceParams

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

function Test:StartSDL_With_One_Activated_App()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
          self:startSession():Do(function ()
            commonFunctions:userPrint(35, "App is registered")
            commonSteps:ActivateAppInSpecificLevel(self, self.applications[default_app_params.appName])
            EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL",audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
            commonFunctions:userPrint(35, "App is activated")
          end)
        end)
      end)
    end)
  end)
end

function Test:AddCommand()
  for i = 1, 20 do
    self.mobileSession:SendRPC("AddCommand", { cmdID = i, vrCommands = {"VRCommand" .. tostring(i)}})
  end
  local on_hmi_call = EXPECT_HMICALL("VR.AddCommand"):Times(20)
  on_hmi_call:Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_RESPONSE("AddCommand", { success = true, resultCode = "SUCCESS" }):Times(20)
  EXPECT_NOTIFICATION("OnHashChange"):Do(function(_, data)
    self.currentHashID = data.payload.hashID
  end):Times(20)
end

function Test:AddSubMenu()
  for i = 1, 20 do
    self.mobileSession:SendRPC("AddSubMenu", { menuID = i, position = 500,
                menuName = "SubMenu" .. tostring(i)})
  end
  local on_hmi_call = EXPECT_HMICALL("UI.AddSubMenu"):Times(20)
  on_hmi_call:Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_RESPONSE("AddSubMenu", { success = true, resultCode = "SUCCESS" }):Times(20)
  EXPECT_NOTIFICATION("OnHashChange"):Do(function(_, data)
    self.currentHashID = data.payload.hashID
  end):Times(20)
end

function Test:AddChoiceSet()
  for i = 1, 20 do
    self.mobileSession:SendRPC("CreateInteractionChoiceSet", {interactionChoiceSetID = i,
        choiceSet = { { choiceID = i, menuName = "Choice" .. tostring(i), vrCommands = { "VrChoice" .. tostring(i)}}}})
  end
    local on_hmi_call = EXPECT_HMICALL("VR.AddCommand"):Times(20)
    on_hmi_call:Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE("CreateInteractionChoiceSet", { success = true, resultCode = "SUCCESS" }):Times(20)
    EXPECT_NOTIFICATION("OnHashChange"):Do(function(_, data)
      self.currentHashID = data.payload.hashID
    end):Times(20)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Transport unexpected disconnect. App resume at FULL level")

function Test:Close_Session()
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = true,
    appID = self.applications[default_app_params]})
  self.mobileSession:Stop()
end

function Test:Register_And_Resume_App_And_Data()
  local mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobileSession:StartRPC()
  on_rpc_service_started:Do(function()
    config.application1.registerAppInterfaceParams.hashID = self.currentHashID
    Test:expect_Resumption_Data()
    commonStepsResumption:RegisterApp(default_app_params, commonStepsResumption.ExpectResumeAppFULL, true)
  end)
end

function Test:expect_Resumption_Data()
  local on_ui_sub_menu_added = EXPECT_HMICALL("UI.AddSubMenu"):Times(20)
  on_ui_sub_menu_added:Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS")
  end)
  on_ui_sub_menu_added:ValidIf(function(_,data)
    if data.params.menuParams.position == 500 then
      if data.params.appID == default_app_params.hmi_app_id then
        return true
      else
        commonFunctions:userPrint(31, "App is registered with wrong appID " )
        return false
      end
    end
  end)
  local is_command_received = 20
  local is_choice_received = 20
  local on_vr_commands_added = EXPECT_HMICALL("VR.AddCommand"):Times(40)
  on_vr_commands_added:Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS")
  end)
  on_vr_commands_added:ValidIf(function(_,data)
    if (data.params.type == "Command" and is_command_received ~= 0) then
      if (data.params.appID == default_app_params.hmi_app_id) then
        is_command_received = is_command_received - 1
        return true
      else
        commonFunctions:userPrint(31, "Received the same notification or App is registered with wrong appID")
        return false
      end
    elseif (data.params.type == "Choice" and is_choice_received ~= 0) then
      if (data.params.appID == default_app_params.hmi_app_id) then
        is_choice_received = is_choice_received - 1
        return true
      else
        commonFunctions:userPrint(31, "Received the same notification or App is registered with wrong appID")
        return false
      end
    end
  end)
   self.mobileSession:ExpectNotification("OnHashChange")
end

function Test:OnCommand()
  self.hmiConnection:SendNotification("UI.OnCommand",{ cmdID = 20, appID = default_app_params.hmi_app_id})
  EXPECT_NOTIFICATION("OnCommand", {cmdID = 20, triggerSource= "MENU"})
end

function Test:PerformInteraction()
  self.mobileSession:SendRPC("PerformInteraction",{
                            initialText = "StartPerformInteraction",
                            initialPrompt = {
                              { text = "Makeyourchoice", type = "TEXT"}},
                            interactionMode = "BOTH",
                            interactionChoiceSetIDList = { 20 },
                            timeout = 5000
                          })
  EXPECT_HMICALL("VR.PerformInteraction", {appID = default_app_params.hmi_app_id}):Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {choiceID = 20})
  end)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test