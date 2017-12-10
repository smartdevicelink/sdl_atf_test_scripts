--  Requirement summary:
--  [RegisterAppInterface] SUCCESS
--  [RegisterAppInterface] RegisterAppInterface and HMILevel
--  [UnregisterAppInterface] Unregistering an application
--
--  Description:
--  Check that it is able to reregister App within current connection.
--
--  1. Used precondition
--  SDL, HMI are running on system.
--  Mobile device is connected to system.
--  Application with appID is registered on SDL.
--
--  2. Performed steps
--  app->SDL: UnregisterAppInterface(params)
--  appID->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL->appID: (SUCCESS, success:true):UnregisterAppInterface()
--     SDL->HMI: OnAppUnregistered(hmi_appID, unexpectedDisсonnect:false)
--  2. SDL successfully registers application and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--  3. SDL assignes HMILevel after application registering:
--     SDL->appID: OnHMIStatus(HMlLevel, audioStreamingState, systemContext)
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
local default_app_params = config.application1.registerAppInterfaceParams

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

function Test:Start_SDL_With_One_Registered_App()
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
          end)
        end)
      end)
    end)
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Unregister_App()
  local cid = self.mobileSession:SendRPC("UnregisterAppInterface", default_app_params)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false,
                   appID = self.applications[default_app_params.appName]})
end

function Test:Reregister_Application()
  local correlation_id = self.mobileSession:SendRPC("RegisterAppInterface", default_app_params)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = default_app_params.appName}})

  EXPECT_RESPONSE(correlation_id, {success = true, resultCode = "SUCCESS"}):Do(function()
    EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end)
  EXPECT_NOTIFICATION("OnPermissionsChange")
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test