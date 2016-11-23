----- -[General] Policies performance requirement
-----  Communication of Policy manager and mobile device must not make discernible difference in system operation.
-----  Execution of any other operation between SDL and mobile app is possible and has no discernibly more latency. 
-----  (Assumption: here is assumed that mobile app sends PTS(Policy Table Snapshot) and receives PTU(Policy Table Update) from backend in separate thread, 
------  i.e. mobile app is not blocked for other operations while waiting response from backend for updated Policy Table)
-- Description:
-- 1. SDL started PTU
-- 2. Mobile waiting response from backend, in that time sent RPC
-- Expected result
-- SDL must correctly finish the PTU


--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]  
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')


--[[ General Precondition before ATF start]]
-- Copy attached ptu.json in /tmp/fs/mp/images/ivsu_cache
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')

--[[ Local Functions ]]
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
function Test:Initiate_PTU_with_AlertRPC_Before_SystemRequest()
commonFunctions:userPrint(33, "================= Test_Case ====================")
  policyUpdate(self, "/tmp/fs/mp/images/ivsu_cache/ptu.json")
end
 
 --[[ Postconditions ]]
Test["StopSDL"] = function()
commonFunctions:userPrint(33, "================= Postcondition ================")
    StopSDL()
  end
