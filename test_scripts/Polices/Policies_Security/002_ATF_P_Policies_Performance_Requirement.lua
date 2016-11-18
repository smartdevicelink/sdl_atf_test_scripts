----  Name of requirement that is covered.
----- [General] Policies performance requirement
----  Mobile app is not blocked for other operations while waiting response from backend for updated Policy Table)


--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]  
local mobile_session = require('mobile_session')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
NewTestSuiteNumber = 0
require('user_modules/AppTypes')

--[[ Local preparing ]]
commonSteps:DeleteLogsFileAndPolicyTable()
Test = require('connecttest')

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
   local CorIdAlert = self.mobileSession:SendRPC("Alert",{}) 
   EXPECT_RESPONSE(CorIdAlert, {success = false, resultCode = "DISALLOWED" })
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
--[[ Test Case]]
commonFunctions:newTestCasesGroup("Test Case")
function Test:Initiate_PTU_with_AlertRPC_Before_SystemRequest()
  policyUpdate(self, "/tmp/fs/mp/images/ivsu_cache/ptu.json")
end
 
--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

Test["ForceKill"] = function (self)
os.execute("ps aux | grep smart | awk \'{print $2}\' | xargs kill -9")
os.execute("sleep 1")

return Test
end
