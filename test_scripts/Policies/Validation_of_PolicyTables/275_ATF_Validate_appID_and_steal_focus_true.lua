---------------------------------------------------------------------------------------------
-- Requirement summary:
--      [Policies] <app id> policies and "steal_focus" validation
--
-- Description:
--    Validation of "steal_focus" section in case "steal_focus:true" and <app id> spolicies are assigned to the application
--     1. Used preconditions:
--        SDL and HMI are started
--        Overwrite preloaded PT(with "steal_focus"=true in <app id>)
--        Connect device
--        Add session
--        Activate registered app
--
--     2. Performed steps
--        Send RPC with soft button with STEAL_FOCUS SystemAction
--
-- Expected result:
--     PoliciesManager must validate "steal_focus" section->
--     PoliciesManager must allow SDL to pass RPC
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--[ToDo: should be removed when fixed: "ATF does not stop HB timers by closing session and connection"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

--[[ Local Functions ]]
local function Backup_preloaded()
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
end

local function Restore_preloaded()
  os.execute('rm ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
end

local function Set_steal_focus_true_for_appId_policies()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = nil
  end
  data.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = true,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4"}
  }
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
  Backup_preloaded()
end

function Test.Precondition_Set_steal_focus_true_for_appId()
  Set_steal_focus_true_for_appId_policies()
end

function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_InitHMI()
  self:initHMI()
end

function Test:Precondition_InitHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_Connect_device()
  self:connectMobile()
end

function Test:Precondition_Register_app()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
    local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
        self.HMIAppID = data.params.application.appID
      end)
    self.mobileSession:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
    self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end)
end

function Test:Precondition_Activate_app()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.HMIAppID})
  EXPECT_HMIRESPONSE(RequestId,{})
  :Do(function(_,data)
    if data.result.isSDLAllowed ~= true then
      local RequestIdGetMes = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
      {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetMes)
      :Do(function()
        self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
        {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
        EXPECT_HMICALL("BasicCommunication.ActivateApp")
        :Do(function(_,data1)
          self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
        end)
      end)
    end
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Send_Alert_check_allowed_steal_focus()
  local CorIdAlert = self.mobileSession:SendRPC("Alert",
  {
    alertText1 = "alertText1",
    softButtons =
    {
      {
        type = "IMAGE",
        image =

        {
          value = "icon.png",
          imageType = "STATIC",
        },
        softButtonID = 1171,
        systemAction = "STEAL_FOCUS",
      },
    },

  })
  local AlertId
  EXPECT_HMICALL("UI.Alert",
  {
    alertStrings = {{fieldName = "alertText1", fieldText = "alertText1"}}, softButtons =
    {
      {
        type = "IMAGE",
        image =
        {
          value = "icon.png",
          imageType = "STATIC",
        },
        softButtonID = 1171,
        systemAction = "STEAL_FOCUS",
      },
    }
  })
  :Do(function(_,data)
  self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "ALERT" })
  AlertId = data.id
  local function alertResponse()
    self.hmiConnection:SendResponse(AlertId, "UI.Alert", "SUCCESS", { })
    self.hmiConnection:SendNotification("UI.OnSystemContext",{ appID = self.applications["Test Application"], systemContext = "MAIN" })
  end
  RUN_AFTER(alertResponse, 3000)
  end)
  EXPECT_RESPONSE(CorIdAlert, { success = true, resultCode = "SUCCESS" })
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Restore_preloaded()
  Restore_preloaded()
end

function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
