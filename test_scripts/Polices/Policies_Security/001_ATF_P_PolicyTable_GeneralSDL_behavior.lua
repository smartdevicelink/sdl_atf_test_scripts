----  Name of requirement that is covered.
----- [General] Policies enough memory for PTS
----  Policies Manager must have enough memory to hold a Policy Table Snapshot in memory.

--------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local mobile_session = require('mobile_session')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Local preparing ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ Preconditions ]]
commonFunctions:userPrint(33, "================= Precondition ==================")
Test = require('connecttest')

--[[Test Case]]
function Test:GeneralSDLbehaviour_PTsize_1mb()
commonFunctions:userPrint(33, "================= Test Case ======================")
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
  --hmi side: sending SystemRequest response
   self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
 end)
  EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
 :Do(function(_,data)
 --Copy of JSON file size near 1_MB in /tmp/fs/mp/images/ivsu_cache/
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

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

Test["ForceKill"] = function (self)
os.execute("ps aux | grep smart | awk \'{print $2}\' | xargs kill -9")
os.execute("sleep 1")

return Test
end
