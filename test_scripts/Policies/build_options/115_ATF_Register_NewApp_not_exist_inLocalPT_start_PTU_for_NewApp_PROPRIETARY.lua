-- Requirement summary:
-- [PolicyTableUpdate] New application has registered and doesn't yet exist in Local PT during PTU in progress
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
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

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
  appHMIType = {"MEDIA"},
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
Test = require('user_modules/connecttest_resumption')

function Test:Precondition_connectMobile()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup ("Preconditions")
function Test:Precondition_RegisterApp_trigger()
  local CorIdRegister = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName }})
  EXPECT_RESPONSE(CorIdRegister, { success = true, resultCode = "SUCCESS" })
  EXPECT_NOTIFICATION("OnHMIStatus", { systemContext = "MAIN", hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE"})

  EXPECT_HMICALL ("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.PolicyUpdate", "SUCCESS", {})
    end)

  EXPECT_NOTIFICATION("OnSystemRequest")--, {requestType = "LOCK_SCREEN_ICON_URL"} )
  :ValidIf(function(_,data)
      if(data.payload.requestType ~= "LOCK_SCREEN_ICON_URL") then
        commonFunctions:printError("requestType should be PROPRIETARY")
        return false
      end
      return true
    end)
end

function Test:Precondition_PolicyUpdateStarted()

  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId, { result = { code = 0, method = "SDL.GetPolicyConfigurationData" }})
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          appID = self.applications ["Test Application"],
          fileName = policy_file_path .. "sdl_snapshot.json"
        }
      )
    end)
  EXPECT_NOTIFICATION("OnSystemRequest")
  :Do(function(_, data)
      if not (data.binaryData ~= nil and string.len(data.binaryData) > 0) then
        self:FailTestCase("PTS was not sent to Mobile in payload of OnSystemRequest")
      end
    end)
  :ValidIf(function(_,data)
      if(data.payload.requestType ~= "PROPRIETARY") then
        commonFunctions:printError("requestType should be PROPRIETARY")
        return false
      end
      return true
    end)
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
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"}, {status = "UPDATE_NEEDED"}):Times(2)
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
  local AppId_2 = "sqlite3 " .. tostring(PolicyDBPath) .. " \"SELECT id FROM application WHERE id = '"..tostring(registerAppInterfaceParams.fullAppID).."'\""
  local bHandle = assert( io.popen(AppId_2, 'r'))
  local AppIdValue_2 = bHandle:read( '*all')
  if AppIdValue_2 == nil then
    self:FailTestCase("Value in DB is unexpected value " .. tostring(AppIdValue_2))
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_SDLStop()
  StopSDL()
end

return Test
