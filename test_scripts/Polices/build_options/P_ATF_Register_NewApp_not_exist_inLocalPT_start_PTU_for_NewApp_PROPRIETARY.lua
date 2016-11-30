-- Requirement summary:
-- [PolicyTableUpdate] New application has registered and doesn't yet exist in Local PT during PTU in progress
--
-- Note: Rename attached ptu_prop.json at ptu.json, and copy on this way: /tmp/fs/mp/images/ivsu_cache/, for line 111 and for line 121
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
-- 4. Check that both AppIds are present in Data Base.
--
-- Expected result:
-- 1. PoliciesManager validates the updated PT (policyFile) e.i. verifyes, saves the updated fields and everything that is defined with related requirements)
-- 2. On validation success: SDL->HMI:OnStatusUpdate("UP_TO_DATE")
-- 3. SDL replaces the following sections of the Local Policy Table with the corresponding sections from PTU: module_config, functional_groupings, app_policies
-- 4. app_2 added to Local PT during PT Exchange process left after merge in LocalPT (not being lost on merge)
-- 5. SDL creates the new snapshot and initiates the new PTU for the app_2 Policies obtaining: SDL-> HMI: SDL.PolicyUpdate()//new PTU sequence started
-------------------------------------------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local mobile_session = require('mobile_session')

--[[ Local Variables ]]
--NewTestSuiteNumber = 0

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

--[[ General Precondition before ATF start]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup ("Preconditions")
function Test:Precondition_PolicyUpdateStarted()
  local pathToSnaphot = nil
  EXPECT_HMICALL ("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      pathToSnaphot = data.params.file
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.PolicyUpdate", "SUCCESS", {})
    end)
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {url = "http://policies.telematics.ford.com/api/policies"}}})
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          url = "http://policies.telematics.ford.com/api/policies",
          appID = self.applications ["Test Application"],
          fileName = "sdl_snapshot.json"
        },
        pathToSnaphot
      )
    end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
end

function Test:Precondition_OpenNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup ("Test")
function Test:TestStep_RegisterApplication_In_NewSession()
  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
end

function Test:TestStep_FinishPTU_For_FirstApplication()
  local CorIdSystemRequest = self.mobileSession:SendRPC ("SystemRequest",
    {
      requestType = "PROPRIETARY",
      fileName = "ptu.json"
    },
    "/tmp/fs/mp/images/ivsu_cache/ptu.json"
  )
  EXPECT_HMICALL("BasicCommunication.SystemRequest")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
    end)
  EXPECT_RESPONSE(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
  :Do(function(_,_)
      os.execute("cp /home/anikolaev/OpenSDL_AUTOMATION/test_run/files/ptu.json /tmp/fs/mp/images/ivsu_cache/")
      self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
        {
          policyfile = "/tmp/fs/mp/images/ivsu_cache/ptu.json"
        })
    end)
  :Do(function(_,_)
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
    end)
end

function Test:TestStep_CheckThatAppID_Present_In_DataBase()
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

function Test:TestStep_Start_New_PolicyUpdate_For_SecondApplication()
  local pathToSnaphot = nil
  EXPECT_HMICALL ("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      pathToSnaphot = data.params.file
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.PolicyUpdate", "SUCCESS", {})
    end)
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {url = "http://policies.telematics.ford.com/api/policies"}}})
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          url = "http://policies.telematics.ford.com/api/policies",
          appID = self.applications ["MyTestApp"],
          fileName = "sdl_snapshot.json"
        },
        pathToSnaphot
      )
    end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
  :Do(function(_,_)
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"})
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
Test["StopSDL"] = function()
  StopSDL()
end

