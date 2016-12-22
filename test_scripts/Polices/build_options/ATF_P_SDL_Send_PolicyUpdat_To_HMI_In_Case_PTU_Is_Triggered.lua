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

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Local Variables ]]
local timeoutAfterXSeconds = 50
local secondsBetweenRetries = {2, 5, 200}
local pathToIni = config.pathToSDL .. "smartDeviceLink.ini"
-- ToDo (ovikhrov): After clarification parameter can be changed to "PathToSnapshot"
local parameterName = "SystemFilesPath"

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')

--[[ Local Functions ]]
local function getValueFromIniFile(pathToIni, parameterName)
  local f = assert(io.open(pathToIni, "r"))
  local fileContent = f:read("*all")
    local ParameterValue 
      ParameterValue = string.match(fileContent, parameterName .. " =.- (.-)\n")
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
          name = "127.0.0.1",
          id = config.deviceMAC,
          transportType = "WIFI",
          isSDLAllowed = false
        }
      }
    })
  :Do(function(_,data)
      local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = data.params.application.appID})
      EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
      :Do(function(_,_)
          local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
          EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
          :Do(function(_,_)
              self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = config.deviceMAC, name = "127.0.0.1"}})
              EXPECT_HMICALL("BasicCommunication.ActivateApp")
              :Do(function(_,data1)
                  self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
                  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
                end)
            end)
        end)
    end)
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate", {timeout = timeoutAfterXSeconds, retry = secondsBetweenRetries, file = getValueFromIniFile(pathToIni, parameterName) .. "/sdl_snapshot.json"})
   :Do(function(_,_)
    end)
end

--[[ Postconditions ]]
function Test.Postcondition_SDLStop()
  StopSDL()
end
function Test.Postcondition_Restore_preloaded()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end 