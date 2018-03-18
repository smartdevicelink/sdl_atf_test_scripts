-- Requirement summary:
-- [PolicyTableUpdate] New application has registered and doesn't yet exist in Local PT during PTU in progress
--
-- Note: Copy attached ptu.json on this way: /tmp/fs/mp/images/ivsu_cache/, for line 111 and for line 121
--
-- Description:
-- PoliciesManager must add the appID of the newly registered app to the Local PT in case
-- such appID does not yet exist in Local PT and PoliciesManager has sent the PT Snapshot and has not received the PT Update yet.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
-- Performed steps
-- 1. MOB-SDL - Register Application default.
-- 2. PTU in progress. PoliciesManager has sent the PT Snapshot and has not received the PT Update yet
-- 3. MOB-SDL - app_2 -> SDL:RegisterAppInterface
-- 4. SDL send UP_TO_DATE for first application
--
-- Expected result:
-- 1. PoliciesManager validates the updated PT (policyFile) e.i. verifyes, saves the updated fields and everything that is defined with related requirements)
-- 2. On validation success: SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- 3. SDL replaces the following sections of the Local Policy Table with the corresponding sections from PTU: module_config, functional_groupings, app_policies
-- 4. app_2 added to Local PT during PT Exchange process left after merge in LocalPT (not being lost on merge)
-------------------------------------------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
Test = require('connecttest')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
require('cardinalities')
require('user_modules/AppTypes')
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
  appID = "mytestapp",
  deviceInfo =
  {
    os = "Android",
    carrier = "Megafon",
    firmwareRev = "Name: Linux, Version: 3.4.0-perf",
    osVersion = "4.4.2",
    maxNumberRFCOMMPorts = 1
  }
}

--[[ General Precondition before ATF start]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup ("Preconditions")
function Test:Precondition_PolicyUpdateStarted()
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS, {
    result = {
      code = 0,
      method = "SDL.GetURLS",
      urls = {
        { url = commonFunctions.getURLs("0x07")[1] }
      }
    }
  })
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          url = commonFunctions.getURLs("0x07")[1],
          appID = self.applications ["Test Application"],
          fileName = "sdl_snapshot.json"
        })
    end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
end

function Test:Precondition_OpenNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup ("Test")
function Test:TestStep_RAI_NewSession()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
end

function Test:TestStep_FinishPTU_ForAppId1()
  local CorIdSystemRequest = self.mobileSession:SendRPC ("SystemRequest",
    {
      requestType = "PROPRIETARY",
      fileName = "ptu.json"
    },
    "files/ptu.json"
  )
  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
    end)
  EXPECT_RESPONSE(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
  :Do(function(_,_)
      self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = "/tmp/fs/mp/images/ivsu_cache/ptu.json" })
      -- PTU will be restarted because of new AppID is registered
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}, {status = "UPDATE_NEEDED"})
    end)
end

function Test:TestStep_CheckThatAppID_Present_In_DataBase()
  local PolicyDBPath = nil
  if commonSteps:file_exists(tostring(config.pathToSDL) .. "/storage/policy.sqlite") == true then
    PolicyDBPath = tostring(config.pathToSDL) .. "/storage/policy.sqlite"
  else
    commonFunctions:userPrint(31, "policy.sqlite file is not found")
    self:FailTestCase("PolicyTable is not avaliable " .. tostring(PolicyDBPath))
  end
  local select_value = "SELECT id FROM application WHERE id = '"..tostring(registerAppInterfaceParams.appID).."'"
  local result = commonFunctions:is_db_contains(PolicyDBPath, select_value, {tostring(registerAppInterfaceParams.appID)})
  if result == false then
    self:FailTestCase("DB doesn't contain special id")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_StopSDL()
  StopSDL()
end

return Test
