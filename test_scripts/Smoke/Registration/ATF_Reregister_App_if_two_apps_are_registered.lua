--  Requirement summary:
--  [RegisterAppInterface] SUCCESS
--  [RegisterAppInterface] RegisterAppInterface and HMILevel
--  [UnregisterAppInterface] Unregistering an application
--
--  Description:
--  Check that it is able to reregister App if several Apps are registered.
--
--  1. Used precondition
--  SDL, HMI are running on system.
--  Mobile device is connected to system.
--  2 Apps are registered.
--
--  2. Performed steps
--  app_1->SDL: UnregisterAppInterface(params)
--  appID_1->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL->appID_1: (SUCCESS, success:true):UnregisterAppInterface()
--     SDL->HMI: OnAppUnregistered(hmi_appID_1, unexpectedDisсonnect:false)
--     app_2 still registered.
--  2. SDL successfully registers app_1 and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID_1: SUCCESS, success:"true":RegisterAppInterface()
--  3. SDL assignes HMILevel after application registering:
--     SDL->appID_1: OnHMIStatus(HMlLevel, audioStreamingState, systemContext)
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

-- [[Local variables]]
local default_app_params1 = config.application1.registerAppInterfaceParams

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

function Test:Start_SDL_With_One_Activated_App()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
          self:startSession():Do(function ()
            commonFunctions:userPrint(35, "First app is registered")
          end)
        end)
      end)
    end)
  end)
end

commonSteps:precondition_AddNewSession()
commonSteps:RegisterTheSecondMediaApp()

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Unregister_App()
  local cid = self.mobileSession:SendRPC("UnregisterAppInterface", default_app_params1)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false,
                   appID = self.applications[default_app_params1.appName]})
end

function Test:Reregister_Application()
  local cid = self.mobileSession:SendRPC("RegisterAppInterface", default_app_params1)
  self.mobileSession:ExpectResponse(cid, { success = true })

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = {appName = default_app_params1.appName} })

  EXPECT_HMICALL("BasicCommunication.UpdateAppList"):Do(function(_,data)
    self.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
  end)
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
  EXPECT_NOTIFICATION("OnPermissionsChange", {})
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test
