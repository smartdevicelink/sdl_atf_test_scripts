--  Requirement summary:
--  [Policies] Master Reset
--
-- Description:
-- On Master Reset, Policy Manager must revert Local Policy Table
-- to the Preload Policy Table.
--
-- 1. Used preconditions
-- SDL and HMI are running
-- App is registered
--
-- 2. Performed steps
-- Perform Master Reset
-- HMI sends OnExitAllApplications with reason MASTER_RESET
--
-- Expected result:
-- 1. SDL clear all Apps folder, app_info.dat file and shut down
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')
local SDL = require('SDL')
local commonTestCases = require("user_modules/shared_testcases/commonTestCases")

--[[ Local Variables ]]
-- Hash id of AddCommand before MASTER_RESET
local hash_id = nil
local default_app_name = config.application1.registerAppInterfaceParams.appName

--[[ General Settings for configuration ]]
Test = require('user_modules/dummy_connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
commonSteps:DeletePolicyTable()
commonSteps:DeleteLogsFiles()

function Test:StartSDL_With_One_Registered_App()
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

function Test:Activate_App_And_Put_File()
  local function addCommand()
    local cid = self.mobileSession:SendRPC("AddCommand",{ cmdID = 1005,
                vrCommands = { "OnlyVRCommand"}
                })
    EXPECT_HMICALL("VR.AddCommand", {cmdID = 1005, type = "Command",
                   vrCommands = {"OnlyVRCommand"}}):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    EXPECT_NOTIFICATION("OnHashChange"):Do(function(_, data)
      hash_id = data.payload.hashID
    end)
  end

  commonSteps:ActivateAppInSpecificLevel(self, self.applications[default_app_name])
  local on_hmi_full = EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
  on_hmi_full:Do(function()
    local cid = self.mobileSession:SendRPC(
    "PutFile", {
      syncFileName = "icon.png",
      fileType = "GRAPHIC_PNG",
      persistentFile = true,
      systemFile = false,
    }, "files/icon.png")
    EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS" })
    addCommand()
  end)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Check that SDL finish it's work properly by MASTER_RESET")

function Test:ShutDown_MASTER_RESET()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitAllApplications",
    { reason = "MASTER_RESET" })
  EXPECT_NOTIFICATION("OnAppInterfaceUnregistered", { reason = "MASTER_RESET" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Do(function()
      SDL:DeleteFile()
    end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
      SDL:StopSDL()
    end)
end

--- Start SDL again then add mobile connection
function Test:Restart_SDL_And_Add_Mobile_Connection()
  self:runSDL()
  commonFunctions:waitForSDLStart(self):Do(function()
    self:initHMI():Do(function()
      commonFunctions:userPrint(35, "HMI initialized")
      self:initHMI_onReady():Do(function ()
        commonFunctions:userPrint(35, "HMI is ready")
        self:connectMobile():Do(function ()
          commonFunctions:userPrint(35, "Mobile Connected")
        end)
      end)
    end)
  end)
end

--- Check SDL will not resume application when the same application registers.
function Test:Check_Application_Not_Resume_When_Register_Again()
  local mobile_session1 = mobile_session.MobileSession(self, self.mobileConnection)
  local on_rpc_service_started = mobile_session1:StartRPC()

  on_rpc_service_started:Do(function()
    local rai_params =  config.application1.registerAppInterfaceParams
    rai_params.hashID = hash_id

    local cid = self.mobileSession:SendRPC("RegisterAppInterface",rai_params)
    local on_app_registered = self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "RESUME_FAILED" })

    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = {appName = default_app_name} })

    EXPECT_HMICALL("BasicCommunication.UpdateAppList"):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
    end)

    EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE",
      audioStreamingState = "NOT_AUDIBLE"})

    on_app_registered:Do(function()
      local cid1 = self.mobileSession:SendRPC("ListFiles", {})
      EXPECT_RESPONSE(cid1, { success = true, resultCode = "SUCCESS" }) :ValidIf (function(_,data)
        return not data.payload.filenames
      end)
      EXPECT_HMICALL("BasicCommunication.ActivateApp"):Times(0)
      EXPECT_HMICALL("VR.AddCommand"):Times(0)
    end)
  end)
  commonTestCases:DelayedExp(3000)
end

-- [[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postcondition")
function Test.Stop_SDL()
  StopSDL()
end

return Test
