---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] "usage_and_error_counts" and "count_of_rejections_duplicate_name" update
--
-- Description:
-- In case application registers with the name already registered on SDL now,
-- Policy Manager must increment "count_of_rejections_duplicate_name" section value
-- of Local Policy Table for the corresponding application.

-- a. SDL and HMI are started
-- b. app_1 with <abc> name successfully registers and running on SDL

-- Steps:
-- 1. app_2 -> SDL; RegisterAppInterface (appName: <abc>)
-- 2. SDL -> app_2: RegisterAppInterface (DUPLICATE_NAME)

-- Expected:
-- 3. PoliciesMananger increments "count_of_rejections_duplicate_name" filed at PolicyTable
---------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local json = require('json')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
local mobile_session = require('mobile_session')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Local variables ]]
local HMIAppID
local basic_ptu_file = "files/ptu.json"
local ptu_first_app_registered = "files/ptu1app.json"

local application2 =
{
  registerAppInterfaceParams =
  {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 0
    },
    appName = "Test Application", -- the same name in config.application1
    isMediaApplication = true,
    languageDesired = 'EN-US',
    hmiDisplayLanguageDesired = 'EN-US',
    appHMIType = { "NAVIGATION" },
    appID = "0000003", --ID different
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
    "Base-4", "Location-1"
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

function Test.Precondition_DeleteLogsAndPolicyTable()
  commonSteps:DeleteLogsFiles()
  commonSteps:DeletePolicyTable()
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
  PrepareJsonPTU1(config.application1.registerAppInterfaceParams.appID, ptu_first_app_registered)
end

function Test:Precondition_RegisterFirstApp()
  self.mobileSession:StartService(7)
  :Do(function (_,_)
  local correlationId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
  HMIAppID = data.params.application.appID
  end)
  EXPECT_RESPONSE(correlationId, { success = true })
  EXPECT_NOTIFICATION("OnPermissionsChange")
  end)
end

function Test.Precondition_PreparePTData()
  PrepareJsonPTU1(config.application1.registerAppInterfaceParams.appID, ptu_first_app_registered)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep1_RegisterSecondApp_DuplicateData()
  self.mobileSession1 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession1:StartService(7)
  :Do(function (_,_)
  local correlationId = self.mobileSession1:SendRPC("RegisterAppInterface", application2.registerAppInterfaceParams)
  self.mobileSession1:ExpectResponse(correlationId, { success = false, resultCode = "DUPLICATE_NAME" })
  end)
end

function Test:TestStep2_ActivateAppInSpecificLevel()
  commonSteps:ActivateAppInSpecificLevel(self,HMIAppID,"FULL")
end

function Test:TestStep3_InitiatePTUForGetSnapshot()
  testCasesForPolicyTable:updatePolicyInDifferentSessions(Test, ptu_first_app_registered,
  config.application1.registerAppInterfaceParams.appName, self.mobileSession)
end

function Test:TestStep2_Check_count_of_rejections_duplicate_name_incremented_in_PT()
  local appID = "0000003"
  local file = io.open("/tmp/fs/mp/images/ivsu_cache/sdl_snapshot.json", "r")
  local json_data = file:read("*all") -- may be abbreviated to "*a";
  file:close()
  local data = json.decode(json_data)
  local CountOfRejectionsDuplicateName = data.policy_table.usage_and_error_counts.app_level[appID].count_of_rejections_duplicate_name
  if CountOfRejectionsDuplicateName == 1 then
    return true
  else
    self:FailTestCase("Wrong count_of_run_attempts_while_revoked. Expected: " .. 1 .. ", Actual: " .. CountOfRejectionsDuplicateName)
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
