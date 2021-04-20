--------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] Case-insensitivity of appName
--
-- Description:
-- SDL must be case-insensetive when comparing the value of "appName" received within
-- RegisterAppInterface against the value(s) of "nicknames" section for the corresponding appID provided by the application.
-- 1. Used preconditions:
-- a) First SDL life cycle with loaded permissions for specific appId and nickname for it in lower case
-- 2. Performed steps
-- a) Register app with appName which present nickNames list but in upper case
--
-- Expected result:
-- a) SDL->appID: SUCCESS: RegisterAppInterface()
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

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
require('user_modules/AppTypes')
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
    nicknames = {"spt"}
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

function Test.Postcondition_Restore_preloaded()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Register_App_Which_Name_Case_Differs_Than_NickName_In_PT_SUCCESS()
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
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
