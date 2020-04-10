---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and "app_registration_language_gui" update
--
-- Description:
-- Policy Manager must update appropriate application "app_registration_language_gui"
-- section of Local PolicyTable with the value of "hmiDisplayLanguageDesired" parameter
-- got via RegisterAppInterface() on application registering.

-- Pre-conditions:
-- a. SDL and HMI are started
-- b. system language is "en-us"

-- Steps:
-- 1. app -> SDL: RegisterAppinterface ("hmiDisplayLanguageDesired" = "en-us")
-- 2. SDL -> app: RegisterAppInterface (SUCCESS)
-- 3. SDL -> HMI: OnAppRegistered

-- Expected:
-- 4. PolciesManager writes <languageDesired> to "app_registration_language_gui" field at LocalPT
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require('json')
local Preconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()
Preconditions:BackupFile("smartDeviceLink.ini")
commonFunctions:write_parameter_to_smart_device_link_ini("HMICapabilitiesCacheFile", "")

--[[ General Settings for configuration ]]
Test = require('connecttest')
local mobile_session = require('mobile_session')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Common variables ]]

--local HMIAppID
-- Basic PTU file
local basic_ptu_file = "files/ptu.json"
-- PTU for first app
local ptu_first_app_registered = "files/ptu1app.json"
local HMIAppID
local language_desired = "EN-US"
-- Basic applications. Using in Register tests
local application1 =
{
  registerAppInterfaceParams =
  {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 0
    },
    appName = "Test Application",
    isMediaApplication = true,
    languageDesired = language_desired,
    hmiDisplayLanguageDesired = language_desired,
    appHMIType = { "NAVIGATION" },
    appID = "0000001",
    fullAppID = "0000001",
    deviceInfo =
    {
      os = "Android",
      carrier = "Megafon",
      firmwareRev = "Name: Linux, Version: 3.4.0-perf",
      osVersion = "4.4.2",
      maxNumberRFCOMMPorts = 1
    }
  }
}

-- Prepare parameters for app to save it in json file
local function PrepareJsonPTU1(name, new_ptufile)
  local json_app = [[ {
    "keep_context": false,
    "steal_focus": false,
    "priority": "NONE",
    "default_hmi": "NONE",
    "groups": [
    "Base-4"
    ],
    "RequestType":[
    "TRAFFIC_MESSAGE_CHANNEL",
    "PROPRIETARY",
    "HTTP",
    "QUERY_APPS"
    ]
  }]]
  local app = json.decode(json_app)
  testCasesForPolicyTable:AddApplicationToPTJsonFile(basic_ptu_file, new_ptufile, name, app)
end

--[[Preconditions]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test.Precondition_StopSDL()
  StopSDL()
end
function Test.Precondition_StartSDL()
  StartSDL(config.pathToSDL, config.ExitOnCrash)
end

function Test:Precondition_initHMI()
  self:initHMI()
end

function Test:Precondition_initHMI_onReady()
  self:initHMI_onReady()
end

function Test:Precondition_ConnectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
end

function Test.Precondition_PreparePTData()
  PrepareJsonPTU1(application1.registerAppInterfaceParams.fullAppID, ptu_first_app_registered)
end

function Test:RegisterFirstApp()
  self.mobileSession:StartService(7)
  :Do(function (_,_)
      local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", application1.registerAppInterfaceParams)

      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          HMIAppID = data.params.application.appID
        end)
      EXPECT_RESPONSE(correlationId, { success = true })
      EXPECT_NOTIFICATION("OnPermissionsChange")
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", { status = "UPDATE_NEEDED" }, { status = "UPDATING" }):Times(2)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function Test:CheckDB_app_registration_language_gui()
  local db_path = config.pathToSDL.."storage/policy.sqlite"
  local sql_query = "SELECT app_registration_language_gui FROM app_level WHERE application_id = '0000001'"
  local exp_result = {language_desired}
  if commonFunctions:is_db_contains(db_path, sql_query, exp_result) == false then
    self:FailTestCase("DB doesn't include expected value")
  end
end

function Test.Precondition_PreparePTData()
  PrepareJsonPTU1(application1.registerAppInterfaceParams.fullAppID, ptu_first_app_registered)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:ActivateAppInFULLLevel()
  commonSteps:ActivateAppInSpecificLevel(self,HMIAppID,"FULL")
end

function Test:InitiatePTUForGetSnapshot()
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId,{result = {code = 0, method = "SDL.GetPolicyConfigurationData"} } )
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"})
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function(_,_)
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate", appID = self.applications[application1.registerAppInterfaceParams.appName]},
            ptu_first_app_registered)
          EXPECT_HMICALL("BasicCommunication.SystemRequest",{ requestType = "PROPRIETARY", fileName = SystemFilesPath.."/PolicyTableUpdate" })
          :Do(function(_,_data1)
              self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = SystemFilesPath.."/PolicyTableUpdate"})
            end)
          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)
end

function Test:CheckDB_app_registration_language_gui()
  local db_path = config.pathToSDL.."storage/policy.sqlite"
  local sql_query = "SELECT app_registration_language_gui FROM app_level WHERE application_id = '0000001'"
  local exp_result = {language_desired}
  if commonFunctions:is_db_contains(db_path, sql_query, exp_result) == false then
    self:FailTestCase("DB doesn't include expected value")
  end
end

function Test:CheckValueFromPTAfterSecondRegistration()
  local snapshot_path = "/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json"

  if(commonSteps:file_exists(snapshot_path)) then
    local snapshot = assert(io.open(snapshot_path, "r"))
    local fileContent = snapshot:read("*all")
    snapshot.close()
    local snapshot_table = json.decode(fileContent)
    local actual_value = snapshot_table["policy_table"]["usage_and_error_counts"]["app_level"]["0000001"]["app_registration_language_gui"]
    if actual_value ~= language_desired then
      self:FailTestCase("Unexpected value in sdl_snapshot.json is :" .. tostring(actual_value))
    end
  else
    self:FailTestCase("sdl_snapshot.json is not created")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_RemovePTUfiles()
  os.remove(ptu_first_app_registered)
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

function Test.RestoreIniFile()
  Preconditions:RestoreFile("smartDeviceLink.ini")
end

return Test
