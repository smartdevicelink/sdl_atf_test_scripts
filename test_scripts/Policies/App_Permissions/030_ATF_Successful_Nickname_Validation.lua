--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] Successful nickname validation
--
-- Note: SDL must build with EXTENDED_POLICY flag
--
-- Description:
-- In case the application sends RegisterAppInterface request with
-- a) the "appName" value that is listed in this app's specific policies
-- b) other valid parameters SDL must: successfully register such application: RegisterAppInterface_response (<applicable resultCode>, success: true)
-- 1. Used preconditions:
-- a) First SDL life cycle with loaded permissions for specific appId and nickname
-- 2. Performed steps
-- a) Register app with name listed in policy table for this app
--
-- Expected result:
-- a) RegisterAppInterface_response (<applicable resultCode>, success: true)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Local Functions ]]
local function SetNickNameForSpecificApp()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = nil
  end
  data.policy_table.app_policies["1234567"] = {
        keep_context = false,
        steal_focus = false,
        priority = "NONE",
        default_hmi = "NONE",
        groups = {"Base-4"},
        nicknames = {"SPT"}
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
  commonPreconditions:BackupFile("sdl_preloaded_pt.json")
end
function Test:Precondition_Set_NickName_Permissions_For_Specific_AppId()
  SetNickNameForSpecificApp(self)
end

function Test:Precondition_StartSDL_FirstLifeCycle()
   StartSDL(config.pathToSDL, config.ExitOnCrash, self)
end

function Test:Precondition_InitHMI_FirstLifeCycle()
  self:initHMI()
end

function Test:Precondition_InitHMI_onReady_FirstLifeCycle()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile_FirstLifeCycle()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end


--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Register_App_With_Name_Listed_In_LPT()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
        majorVersion = 3,
        minorVersion = 0
      },
      appName = "SPT",
      isMediaApplication = true,
      languageDesired = "EN-US",
      hmiDisplayLanguageDesired = "EN-US",
      appID = "1234567",
      deviceInfo =
      {
        os = "Android",
        carrier = "Megafon",
        firmwareRev = "Name: Linux, Version: 3.4.0-perf",
        osVersion = "4.4.2",
        maxNumberRFCOMMPorts = 1
      }
    })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
    {
      application =
      {
        appName = "SPT",
        policyAppID = "1234567",
        isMediaApplication = true,
        hmiDisplayLanguageDesired = "EN-US",
        deviceInfo =
        {
          name = utils.getDeviceName(),
          id = utils.getDeviceMAC(),
          transportType = utils.getDeviceTransportType(),
          isSDLAllowed = false
        }
      }
    })
  EXPECT_RESPONSE(CorIdRAI, {success = true, resultCode = "SUCCESS"})
end


--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
function Test.Postcondition_Restore_preloaded()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
