---------------------------------------------------------------------------------------------
-- Requirement summary:
-- Send BC.PolicyUpdate to HMI in case PTU is triggered
--
-- Description:
-- In case SDL is built with "-DEXTENDED_POLICY: ON" flag, and PolicyTableUpdate is triggered SDL must
-- send BasicCommunication.PolicyUpdate ( <path to SnapshotPolicyTable>, <timeout from policies>, <set of retry timeouts>) to HMI.
-- reset the flag "UPDATE_NEEDED" to "UPDATING" (by sending OnStatusUpdate to HMI)
-- 1. Used preconditions:
-- a) Stop SDL and set preloaded file with timeout from policies and set of retry timeouts
-- b) Start SDL as new life cycle
-- 2. Performed steps
-- a) Register, activate and consent app
--
-- Expected result:
-- a) SDL send BasicCommunication.PolicyUpdate ( <path to SnapshotPolicyTable>, <timeout from policies>, <set of retry timeouts>) to HMI.
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ Local Variables ]]
local timeoutAfterXSeconds = 50
local secondsBetweenRetries = {2, 5, 200}
local pathToIni = config.pathToSDL .. "/smartDeviceLink.ini"
-- ToDo (ovikhrov): After clarification parameter can be changed to "PathToSnapshot"
local parameterName = "SystemFilesPath"

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Local Functions ]]
local function getValueFromIniFile(path_to_ini, parameter_name)
  local f = assert(io.open(path_to_ini, "r"))
  local fileContent = f:read("*all")
  local ParameterValue
  ParameterValue = string.match(fileContent, parameter_name .. " =.- (.-)\n")
  f:close()
  return ParameterValue
end

local function SetModuleconfigForPreDataConsent(timeout, retries)
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = nil
  end
  data.policy_table.module_config.timeout_after_x_seconds = timeout
  data.policy_table.module_config.seconds_between_retries = retries

  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end

--[[ Preconditions ]]
function Test:Precondition_StopSDL()
  StopSDL(self)
end

--ToDo: shall be removed when issue: "SDL doesn't stop at execution ATF function StopSDL()" is fixed
function Test:Precondition_SDLForceStop()
  commonFunctions:SDLForceStop(self)
end

function Test:Precondition_DeleteLogsAndPolicyTable()
  commonSteps:DeleteLogsFiles(self)
  commonSteps:DeletePolicyTable(self)
end

function Test.Precondition_Backup_preloadedPT()
  commonPreconditions:BackupFile("sdl_preloaded_pt.json")
end

function Test:Precondition_SetP_Module_Config_Values_ForPre_DataConsent()
  SetModuleconfigForPreDataConsent(timeoutAfterXSeconds, secondsBetweenRetries, self)
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
function Test:TestStep_Register_App_And_Check_PolicyUpdate()

  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"})
  :Times(2)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate",
    {timeout = timeoutAfterXSeconds, retry = secondsBetweenRetries, file = getValueFromIniFile(pathToIni, parameterName) .. "/sdl_snapshot.json"})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Postconditions ]]
function Test.Postcondition_SDLStop()
  StopSDL()
end
function Test.Postcondition_Restore_preloaded()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end
