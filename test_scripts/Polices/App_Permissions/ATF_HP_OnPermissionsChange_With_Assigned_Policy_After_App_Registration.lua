---------------------------------------------------------------------------------------------
-- Description:
-- In case the application successfully registers to SDL SDL must send OnPermissionsChange (<assigned policies>) to such application.
-- Preconditions:
-- 1. Delete policy.sqlite file, app_info.dat files
-- 2. Replace sdl_preloaded_pt.json file where specified "pre_DataConsent" section and group for it.
--
-- Requirement summary:
-- app -> SDL: RegisterAppInterface_request (appID=, appName=<appName>, params):
-- SDL -> app: RegisterAppInterface_response
-- SDL -> app: OnPermissionsChange (<current permissions>)
--
-- Actions:
-- appID->SDL: RegisterAppInterface(parameters)
--
-- Expected:
-- 1. SDL -> app: RegisterAppInterface_response
-- 2. SDL -> app: OnPermissionsChange (<permissions assigned in pre_DataConsent group>)
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Local Functions ]]
local function BackupPreloaded()
  os.execute('cp ' .. config.pathToSDL .. 'sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json')
  os.execute('rm ' .. config.pathToSDL .. 'policy.sqlite')
end

local function RestorePreloadedPT()
  os.execute('rm ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
  os.execute('cp ' .. config.pathToSDL .. 'backup_sdl_preloaded_pt.json' .. ' ' .. config.pathToSDL .. 'sdl_preloaded_pt.json')
end

local function SetPermissionsForPre_DataConsent()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = {rpcs = null}
  end
  -- set for group in pre_DataConsent section permissions with RPCs and HMI levels for them
  data.policy_table.functional_groupings[data.policy_table.app_policies.pre_DataConsent.groups[1]] = {rpcs = {
      OnHMIStatus =
      {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}},
      OnPermissionsChange =
      {hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}},
      Show =
      {hmi_levels = {"BACKGROUND", "FULL", "LIMITED", "NONE"}},
  }}
  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end

--[[ Precondition ]]
local function Precondition()

  commonFunctions:userPrint(34, "-- Precondition --")

  function Test:StopSDL()
    StopSDL()
  end

  --ToDo: shall be removed when issue: "SDL doesn't stop at execution ATF function StopSDL()" is fixed
  function Test:SDLForceStop()
    commonFunctions:SDLForceStop()
  end

  function Test:DeleteLogsAndPolicyTable()
    commonSteps:DeleteLogsFiles()
    commonSteps:DeletePolicyTable()
  end

  function Test:Backup_sdl_preloaded_pt()
    BackupPreloaded()
  end

  function Test:SetPermissionsForPre_DataConsent()
    SetPermissionsForPre_DataConsent()
  end

  function Test:StartSDL_FirstLifeCycle()
    StartSDL(config.pathToSDL, config.ExitOnCrash)
  end

  function Test:InitHMI_FirstLifeCycle()
    self:initHMI()
  end

  function Test:InitHMI_onReady_FirstLifeCycle()
    self:initHMI_onReady()
  end

  function Test:ConnectMobile_FirstLifeCycle()
    self:connectMobile()
  end

  function Test:StartSession()
    self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
    self.mobileSession:StartService(7)
  end

  function Test:RestorePreloadedPT()
    RestorePreloadedPT()
  end

end
Precondition()

--[[ Test ]]
function Test:Step1_Register_App_And_Check_Its_Permissions_In_OnPermissionsChange()

  commonFunctions:userPrint(34, "-- Test --")
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
  --hmi side: expected BasicCommunication.OnAppRegistered
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
          name = "127.0.0.1",
          id = config.deviceMAC,
          transportType = "WIFI",
          isSDLAllowed = false
        }
      }
    })
  :Do(function(_,data)
      self.applications["SPT"] = data.params.application.appID
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  EXPECT_NOTIFICATION("OnPermissionsChange", {})
  :ValidIf(function(_,data)
      -- Permissions based on preloaded_pt file
      --ToDo: (vikhrov) develop functions for extracting permissions for specific groups and compare it with permissionItem from OnPermissionsChange
      local Permitted_data = { {
          hmiPermissions = {allowed = {"BACKGROUND", "FULL", "LIMITED", "NONE"}, userDisallowed = {}},
          rpcName = "OnHMIStatus",
          parameterPermissions = {allowed = {}, userDisallowed = {}},
        },
        {
          rpcName = "OnPermissionsChange",
          hmiPermissions = {userDisallowed = {}, allowed = {"BACKGROUND", "FULL", "LIMITED", "NONE"}},
          parameterPermissions = {allowed = {}, userDisallowed = {}}
        },
        {
          hmiPermissions = {allowed = {"BACKGROUND", "FULL", "LIMITED", "NONE"}, userDisallowed = {}},
          rpcName = "Show",
          parameterPermissions = {allowed = {}, userDisallowed = {}}
      }}

      if commonFunctions:is_table_equal(data.payload.permissionItem, Permitted_data) then
        return true
      else
        return false
      end
    end)
end

function Test:Step2_Check_RPC_From_OnPermissionsChange_Allowance()

  local CorIdRAI = self.mobileSession:SendRPC("Show",
    {
      mediaClock = "00:00:01",
      mainField1 = "Show1"
    })
  EXPECT_HMICALL("UI.Show", {}):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, "UI.Show", "SUCCESS", { })
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
end

function Test:Step2_Check_Disallowed_RPC()
  local cid = self.mobileSession:SendRPC("AddSubMenu",
    {
      menuID = 1000,
      position = 500,
      menuName ="SubMenupositive"
    })
  EXPECT_RESPONSE(cid, { success = false, resultCode = "DISALLOWED" })
end

--[[ Postcondition ]]
--ToDo: shall be removed when issue: "SDL doesn't stop at execution ATF function StopSDL()" is fixed
function Test:SDLForceStop()
  commonFunctions:userPrint(34, "-- Postcondition --")
  commonFunctions:SDLForceStop()
end
