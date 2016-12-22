---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU] Trigger: days
--
-- Description:
-- If the difference between current system time value_2 and system time value_1 when the previous
-- UpdatedPollicyTable was applied is equal or greater than to the value of "exchange_after_x_days"
-- field ("module_config" section) of policies database SDL must trigger a PolicyTableUpdate sequence
-- 1. Used preconditions:
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- The date previous PTU was received is 01.01.2016
-- the value in PT "module_config"->"'exchange_after_x_days '"is set to 150
-- 2. Performed steps:
-- SDL gets the current date 06.06.2016, it's more than 150 days after the last PTU
--
-- Expected result:
-- SDL initiates PTU: SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- PTS is created by SDL: SDL-> HMI: SDL.PolicyUpdate() //PTU sequence started
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
--ToDo: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require ('user_modules/shared_testcases/commonSteps')
local testCasesForPolicyTableSnapshot = require ('user_modules/shared_testcases/testCasesForPolicyTableSnapshot')
local commonTestCases = require ('user_modules/shared_testcases/commonTestCases')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Local Variables ]]
local exchangeDays = testCasesForPolicyTableSnapshot:get_data_from_Preloaded_PT("module_config.exchange_after_x_days")
local currentSystemDaysAfterEpoch

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")

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
CreatePTUFromExisted()
--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require("user_modules/AppTypes")
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")


function Test:Precondition_Update_Policy_With_Exchange_After_X_Days_Value()
  currentSystemDaysAfterEpoch = getSystemDaysAfterEpoch()
  
  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "HTTP", fileName = "PolicyTableUpdate", },"files/tmp_PTU.json")
  
  EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMICALL("BasicCommunication.SystemRequest"):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status="UP_TO_DATE"})
end

function Test.Precondition_StopSDL()
  StopSDL()
end

function Test.Precondition_SetExchangedXDaysInDB()
  setPtExchangedXDaysAfterEpochInDB(currentSystemDaysAfterEpoch - exchangeDays)
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
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface",
    {
      syncMsgVersion =
      {
        majorVersion = 3,
        minorVersion = 0
      },
      appName = "Test Application",
      isMediaApplication = true,
      languageDesired = "EN-US",
      hmiDisplayLanguageDesired = "EN-US",
      appID = "0000001",
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
        appName = "Test Application",
        policyAppID = "0000001",
        isMediaApplication = true,
        hmiDisplayLanguageDesired = "EN-US",
        deviceInfo =
        {
          name = "127.0.0.1",
          id = config.deviceMAC,
          transportType = "WIFI",
          isSDLAllowed = true
        }
      }
    })
  EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
  
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate"):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status="UPDATE_NEEDED"})
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "HTTP"})
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status="UPDATING"})
end

--[[ Postcondition ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_DeleteTmpPTU()
  DeleteTmpPTU()
end

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
