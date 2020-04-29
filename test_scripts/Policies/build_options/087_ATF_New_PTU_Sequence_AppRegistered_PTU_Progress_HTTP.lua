-------------------------------------------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] New PTU sequence initiation (app registering during PTU being in progress)
--
-- Description:
--PoliciesManager must initiate a new PTU sequence right after the previous PTUpdate is received,
--validated and applied IN CASE a new app with appID that does not yet exist in Local PT registeres
--while PoliciesManager has sent the PT Snapshot and has not received the PT Update yet.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Performed steps
-- 1. MOB-SDL - Register Application default.
-- 2. PTU in progress. PoliciesManager has sent the PT Snapshot and has not received the PT Update yet
-- 3. MOB-SDL - app_2 -> SDL:RegisterAppInterface
-- 4. Check that both AppIds are present in Data Base.
--
-- Expected result:
-- 1. PoliciesManager validates the updated PT (policyFile) e.i. verifyes, saves the updated fields and everything that is defined with related requirements)
-- 2. On validation success: SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- 3. SDL replaces the following sections of the Local Policy Table with the corresponding
-- sections from PTU:module_config, functional_groupings, app_policies
-- 4. app_2 added to Local PT during PT Exchange process left after merge in LocalPT (not being lost on merge)
-- 5. SDL creates the new snapshot and initiates the new PTU for the app_2 Policies obtaining: SDL-> HMI: SDL.PolicyUpdate()//new PTU sequence started
-------------------------------------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local mobile_session = require('mobile_session')

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

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup ("Preconditions")
function Test:Precondition_OpenNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:Precondition_RAI_NewSession()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup ("Test")
function Test:TestStep_PoliciesManager_changes_UP_TO_DATE()
  assert(commonFunctions:File_exists("files/ptu.json"))
  local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
    { requestType = "HTTP", fileName = "PolicyTableUpdate" },"files/ptu.json")

  EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
  EXPECT_HMICALL("BasicCommunication.SystemRequest"):Times(0)
  EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}, {status = "UPDATE_NEEDED"}, {status = "UPDATING"})
  :Times(3)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Stop()
  StopSDL()
end

return Test
