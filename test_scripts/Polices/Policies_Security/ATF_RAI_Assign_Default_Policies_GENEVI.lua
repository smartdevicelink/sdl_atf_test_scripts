----  Name of requirement that is covered.
----[F-S] SDL must re-assign "default" policies to app in case "default" policies was updated via PolicyTable update--
---- After PTU SDL must assign new default policies for App


--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]  
Test = require('connecttest')
local mobile_session = require('mobile_session')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
NewTestSuiteNumber = 0
require('user_modules/AppTypes')

--[[ Local preparing ]]
commonSteps:DeleteLogsFileAndPolicyTable()

local function policyUpdate(self)
  local pathToSnaphot = nil
  EXPECT_HMICALL ("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      pathToSnaphot = data.params.file
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.PolicyUpdate", "SUCCESS", {})
    end)
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS,{result = {code = 0, method = "SDL.GetURLS", urls = {url = "http://policies.telematics.ford.com/api/policies"}}})
  :Do(function(_,data)
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
  :Do(function(_,data)
      local CorIdSystemRequest = self.mobileSession:SendRPC ("SystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "sdl_snapshot.json"
        },
        pathToSnaphot
      )
      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_,data)
          self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
        end)
      EXPECT_RESPONSE(CorIdSystemRequest, {success = true, resultCode = "SUCCESS"})
      :Do(function(_,data)
          --Copy of JSON file in /tmp/fs/mp/images/ivsu_cache/
          --Example: os.execute("cp /home/anikolaev/OpenSDL_AUTOMATION/test_run/files/ptu.json /tmp/fs/mp/images/ivsu_cache/")
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
            {
              policyfile = "/tmp/fs/mp/images/ivsu_cache/ptu.json"
            })
        end)
      :Do(function(_,data)
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
        end)
    end)
end
--[[ Preconditions ]]  
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Pre_MoveSystemInUpToDateStatus()
  policyUpdate(self, "/tmp/fs/mp/images/ivsu_cache/ptu.json")
end
 

function Test:Pre_OpenNewSession()
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
end

function Test:Pre_RAI_InNewSession()
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

  local corId = self.mobileSession2:SendRPC("RegisterAppInterface", registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = "Media Application" }})
  self.mobileSession2:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  self.mobileSession2:ExpectNotification("OnPermissionsChange")
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test Case")
--Copy prepared JSON file with ALLOWED RPC ListFiles, in /tmp/fs/mp/images/ivsu_cache/ - and use it.
--Example: os.execute("cp /home/anikolaev/OpenSDL_AUTOMATION/test_run/files/PTU_NewPolicy_GENEVI.json /tmp/fs/mp/images/ivsu_cache/") 
function Test:AssignNewDefaultPoicies()
   policyUpdate(self, "/tmp/fs/mp/images/ivsu_cache/PTU_NewPolicy_GENEVI.json")
end

function Test:SendRPCForCheckNewDefaultPolicies()
  local cid = self.mobileSession2:SendRPC("ListFiles", {})
  self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

-- --[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

Test["ForceKill"] = function (self)
os.execute("ps aux | grep smart | awk \'{print $2}\' | xargs kill -9")
os.execute("sleep 1")

return Test
end