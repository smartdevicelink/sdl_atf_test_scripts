---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [RegisterAppInterface] DISALLOWED app`s nickname does not match ones listed in Policy Table
--
-- Description:
-- PoliciesManager must disallow the app`s registration IN CASE the app`s nickname does not match those listed in Policy Table under the appID this app registers with
-- 1. Used preconditions:
-- a) First SDL life cycle with loaded permissions for specific appId and nickname for it
-- 2. Performed steps
-- a) Register app with appName which not present nickNames list
--
-- Expected result:
-- a) SDL->app: RegisterAppInterface(DISALLOWED, success:false)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Local Functions ]]
local function BackupPreloaded()
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
end

local function RestorePreloadedPT()
  os.execute('rm ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
end

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
function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.Precondition_DeleteLogsAndPolicyTable()
  commonSteps:DeleteLogsFiles()
  commonSteps:DeletePolicyTable()
end

function Test.Precondition_Backup_sdl_preloaded_pt()
  BackupPreloaded()
end

function Test.Precondition_Set_NickName_Permissions_For_Specific_AppId()
  SetNickNameForSpecificApp()
end

function Test.Precondition_StartSDL_FirstLifeCycle()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
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

function Test.Precondition_RestorePreloadedPT()
  RestorePreloadedPT()
end

--[[ Test ]]

function Test:TestStep_Register_DefaultApp()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
end

function Test:Precondition_StartSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:TestStep_Register_App_Which_Name_Not_Listad_In_PT_DISALLOWED()
  local CorIdRAI = self.mobileSession2:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
        majorVersion = 3,
        minorVersion = 0
      },
      appName = "AnotherAppName",
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
  self.mobileSession2:ExpectResponse(CorIdRAI, { success = false, resultCode = "DISALLOWED"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
