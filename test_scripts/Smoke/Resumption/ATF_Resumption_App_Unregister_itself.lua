--  Requirement summary:
--  [Data Resumption] Application data must not be resumed
--
--  Description:
--  Check that no resumption occurs if App unregister itself gracefully.

--  1. Used precondition
--  App is registered and activated on HMI.

--  2. Performed steps
--  Exit from SPT
--  Start SPT again, Find Apps
--
--  Expected behavior:
--  1. SPT sends UnregisterAppInterface and EndSession to SDL.
--     SPT register in usual way, no resumption occurs
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.isMediaApplication = true

-- [[ Required Shared Libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonStepsResumption = require('user_modules/shared_testcases/commonStepsResumption')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

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

function Test:Add_Command_And_Put_File()
  local correlation_id = self.mobileSession:SendRPC("AddCommand", { cmdID = 1, vrCommands = {"OnlyVRCommand"}})
  local on_hmi_call = EXPECT_HMICALL("VR.AddCommand", {cmdID = 1, type = "Command",
                      vrCommands = {"OnlyVRCommand"}})
  on_hmi_call:Do(function(_, data)
    self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  EXPECT_RESPONSE(correlation_id, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHashChange"):Do(function(_, data)
    self.currentHashID = data.payload.hashID
  end)

  local cid = self.mobileSession:SendRPC(
    "PutFile", {
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = true,
      systemFile = false,
    }, "files/icon.png")
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("No resumption if App unregister itself")

function Test:Unregister_App()
  local cid = self.mobileSession:SendRPC("UnregisterAppInterface", default_app_params)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false,
                   appID = self.applications[default_app_params]})
end

function Test:Register_And_No_Resume_App()
  commonStepsResumption:RegisterApp(default_app_params, commonStepsResumption.ExpectNoResumeApp, false)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test
