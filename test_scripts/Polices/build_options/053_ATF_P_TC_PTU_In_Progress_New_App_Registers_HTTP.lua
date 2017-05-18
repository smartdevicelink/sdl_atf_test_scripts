-- UNREADY:
--function Test:TestStep_CheckThatAppID_SecondApp_Present_In_DataBase
---------------------------------------------------------------------------------------------
-- Requirements summary:
--[PolicyTableUpdate] New application has registered and doesn't yet exist in Local PT
-- during PTU in progress
--
-- Description:
--PoliciesManager must add the appID of the newly registered app to the Local PT
--in case such appID does not yet exist in Local PT and PoliciesManager has sent the PT Snapshot
--and has not received the PT Update yet.

-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- App 1 is registered.
-- App 2 NOT yet registered on SDL and doesn't yet exist in LocalPT
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- 2. Performed steps
-- app_2->SDL:RegisterAppInterface()
--
-- Expected result:
-- SDL->App 2: SUCCESS:RegsterAppInterface()
-- SDL adds application with App 2 data into LocalPT according to general rules
-- of adding app data into LocalPT
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

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

--[[ Test ]]
commonFunctions:newTestCasesGroup ("Test")
function Test:TestStep_OpenNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:TestStep_RAI_NewSession()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
end

function Test:TestStep_CheckThatAppID_SecondApp_Present_In_DataBase()
  local PolicyDBPath = nil
  if commonSteps:file_exists(tostring(config.pathToSDL) .. "/storage/policy.sqlite") == true then
    PolicyDBPath = tostring(config.pathToSDL) .. "/storage/policy.sqlite"
  end
  if commonSteps:file_exists(tostring(config.pathToSDL) .. "/storage/policy.sqlite") == false then
    commonFunctions:userPrint(31, "policy.sqlite file is not found")
    self:FailTestCase("PolicyTable is not avaliable" .. tostring(PolicyDBPath))
  end
  os.execute(" sleep 2 ")
  local AppId_2 = "sqlite3 " .. tostring(PolicyDBPath) .. "\"SELECT id FROM application WHERE id = '"..tostring(registerAppInterfaceParams.appID).."'\""
  local bHandle = assert( io.popen(AppId_2, 'r'))
  local AppIdValue_2 = bHandle:read( '*l' )
  if AppIdValue_2 == nil then
    self:FailTestCase("Value in DB is unexpected value " .. tostring(AppIdValue_2))
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Stop()
  StopSDL()
end

return Test