 -----  Name of requirement that is covered-----
 ----- [Security]: SDL behavior in case 'certificates' field is empty
 ----- Description:
 ----- Certificate have empty value in sdl_preloaded_pt JSON of module_config section
 ----- Expected result------
 ----- SDL must continue working as assigned.
-------------------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--[ToDo: should be removed when fixed: "ATF does not stop HB timers by closing session and connection"
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')


--[[ Local Functions ]]
local registerAppInterfaceParams =
  {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 0
    },
    appName = "Media Application",
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = {"NAVIGATION"},
    appID = "MyTestApp",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  }

local function UpdatePreloadedJson_CertificateValue_Empty()
  local pathToFile = config.pathToSDL .. 'sdl_preloaded_pt.json'
  local file = io.open(pathToFile, "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local json = require("modules/json")
  local data = json.decode(json_data)

  if data.policy_table.functional_groupings["DataConsent-2"] then
    data.policy_table.functional_groupings["DataConsent-2"] = nil
  end

  data.policy_table.module_config.certificate = ""

  data = json.encode(data)
  file = io.open(pathToFile, "w")
  file:write(data)
  file:close()
end


--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
local mobile_session = require('mobile_session')
require('user_modules/AppTypes')

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

function Test.Precondition_Set_Certificate_Value()
  UpdatePreloadedJson_CertificateValue_Empty()
end

--[[Test]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_StartSDL_With_Empty_Certificate()
  StartSDL(config.pathToSDL, config.ExitOnCrash, self)
end

function Test:TestStep_initHMI()
  self:initHMI()
end

function Test:TestStep_initHMI_onReady()
  self:initHMI_onReady()
end

function Test:TestStep_ConnectMobile()
  self:connectMobile()
end

function Test:TestStep_CreateSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:TestStep_RegisterApplication()
 local corId = self.mobileSession:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end
function Test.Postcondition_Restore_preloaded()
  commonPreconditions:RestoreFile("sdl_preloaded_pt.json")
end

return Test
