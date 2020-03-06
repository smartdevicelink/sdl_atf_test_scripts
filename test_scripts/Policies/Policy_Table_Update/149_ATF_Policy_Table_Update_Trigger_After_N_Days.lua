---------------------------------------------------------------------------------------------
-- Requirement summary:
-- Request PTU - after "N" days
--
-- Description:
-- The policies manager must request an update to its local policy table after "N" days only if the system provided time is available.
-- 1. Used preconditions:
-- a) device an app with app_ID is running is consented
-- b) application is running on SDL
-- c) The date previous PTU was received is 01.01.2016
-- d) the value in PT "module_config"->"'exchange_after_x_days '":150
-- 2. Performed steps:
-- a) SDL gets the current date 06.06.2016, it's more than 150 days after the last PTU
--
-- Expected result:
-- a) SDL initiates PTU:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- PTS is created by SDL:
-- SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General configuration parameters ]]
--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require ('user_modules/shared_testcases/testCasesForPolicyTable')
local utils = require ('user_modules/utils')

--[[ Local Variables ]]
local exchangeDays = 30
local currentSystemDaysAfterEpoch

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--[[ Local Functions ]]
local function CreatePTUFromExisted()
  os.execute('cp files/ptu_general.json files/tmp_PTU.json')
end

local function DeleteTmpPTU()
  os.execute('rm files/tmp_PTU.json')
end

local function getSystemDaysAfterEpoch()
  return math.floor(os.time()/86400)
end

local function setPtExchangedXDaysAfterEpochInDB(daysAfterEpochFromPTS)
  local pathToDB = config.pathToSDL .. "storage/policy.sqlite"
  local DBQuery = 'sqlite3 ' .. pathToDB .. ' \"UPDATE module_meta SET pt_exchanged_x_days_after_epoch = ' .. daysAfterEpochFromPTS .. ' WHERE rowid = 1;\"'
  os.execute(DBQuery)
  os.execute(" sleep 1 ")
end

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test.Preconditions_Set_Exchange_After_X_Days_For_PTU()
  CreatePTUFromExisted()
end

function Test:Precondition_Activate_App_Consent_Device()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", {appID = self.applications["Test Application"]})
  EXPECT_HMIRESPONSE(RequestId, {result = {code = 0, isSDLAllowed = false}, method = "SDL.ActivateApp"})
  :Do(function(_,_)
      local RequestIdGetUserFriendlyMessage = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetUserFriendlyMessage,{result = {code = 0, method = "SDL.GetUserFriendlyMessage"}})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_,data1)
              self.hmiConnection:SendResponse(data1.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
              EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN"})
            end)
        end)
    end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function(_,data2)
      self.hmiConnection:SendResponse(data2.id, data2.method, "SUCCESS", {})
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"}):Times(2)
end

function Test:Precondition_Update_Policy_With_Exchange_After_X_Days_Value()
  currentSystemDaysAfterEpoch = getSystemDaysAfterEpoch()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId)
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{requestType = "PROPRIETARY", fileName = "filename"})
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", {fileName = "PolicyTableUpdate", requestType = "PROPRIETARY"}, "files/tmp_PTU.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data1)

              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/PolicyTableUpdate"})
              self.hmiConnection:SendResponse(data1.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
              EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
            end)
        end)
    end)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
end

function Test:Precondition_ExitApplication()
  self.hmiConnection:SendNotification("BasicCommunication.OnExitApplication", {appID = self.applications[config.application1.registerAppInterfaceParams.appName], reason = "USER_EXIT"})
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})
end

function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.SetExchangedXDaysInDB()
  setPtExchangedXDaysAfterEpochInDB(currentSystemDaysAfterEpoch - exchangeDays - 1)
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

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Register_App_And_Check_That_PTU_Triggered()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName}})
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate",{status = "UPDATE_NEEDED"})
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
end

--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_DeleteTmpPTU()
  DeleteTmpPTU()
end

function Test.Postcondition_StopSDL()
  StopSDL()
end
