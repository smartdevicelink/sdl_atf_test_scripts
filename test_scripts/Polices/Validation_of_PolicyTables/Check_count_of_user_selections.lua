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

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')
local mobile_session = require('mobile_session')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Local variables ]]
local HMIAppID

local application1 =
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
    appID = "0000001", --ID different
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

local application2 =
{
  registerAppInterfaceParams =
  {
    syncMsgVersion =
    {
      majorVersion = 3,
      minorVersion = 0
    },
    appName = "Test Application", -- the same name in application1
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
  self.mobileSession:StartService(7)
end

function Test:Precondition_RegisterApp()
  local CorIdRAI = self.mobileSession:SendRPC("RegisterAppInterface", application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(function(_,data)
      HMIAppID = data.params.application.appID
      EXPECT_RESPONSE(CorIdRAI, { success = true, resultCode = "SUCCESS"})
    end)
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

function Test.TestStep2_ActivateAppInSpecificLevel()
  commonSteps:ActivateAppInSpecificLevel(Test,HMIAppID)
end

function Test.Wait()
  os.execute("sleep 3")
end

function Test:TestStep2_Check_count_of_rejections_duplicate_name_incremented_in_PT()
  local appID = "0000003"
  local query = "select count_of_rejections_duplicate_name from app_level where application_id = '" .. appID .. "'"
  local CountOfRejectionsDuplicateName = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", query)[1]
  if CountOfRejectionsDuplicateName == '1' then
    return true
  else
    self:FailTestCase("Wrong count_of_rejections_duplicate_name. Expected: " .. 1 .. ", Actual: " .. CountOfRejectionsDuplicateName)
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
