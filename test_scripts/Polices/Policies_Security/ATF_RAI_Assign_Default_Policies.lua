---------------------------------------------------------------------------------------------
-----------------------------Required Shared Libraries---------------------------------------
---------------------------------------------------------------------------------------------
local mobile_session = require('mobile_session')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"
local storagePath = config.pathToSDL .. config.application1.registerAppInterfaceParams.appID.. "_" .. config.deviceMAC.. "/"

commonFunctions:userPrint(33, "================= Precondition ==================")
Test = require('connecttest')

function Test:AssignDefaultPoliciesForApplication()
  commonFunctions:userPrint(33, "================= Test Case ======================")
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  local pathToSnaphot = nil
  EXPECT_HMICALL ("BasicCommunication.PolicyUpdate")
  :Do(function(_,data)
      pathToSnaphot = data.params.file
      self.hmiConnection:SendResponse(data.id, "BasicCommunication.PolicyUpdate", "SUCCESS", {})
    end)
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
          os.execute("cp /home/anikolaev/OpenSDL_AUTOMATION/test_run/files/ptu.json /tmp/fs/mp/images/ivsu_cache/")
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

function Test:Check_DefaultPoliciesForApp()
   local PolicyDBPath = nil
  if commonSteps:file_exists(tostring(config.pathToSDL) .. "/policy.sqlite") == true then
    PolicyDBPath = tostring(config.pathToSDL) .. "/policy.sqlite"
  end
  if commonSteps:file_exists(tostring(config.pathToSDL) .. "/policy.sqlite") == false then
    commonFunctions:userPrint(31, "policy.sqlite file is not found")
    self:FailTestCase("PolicyTable is not avaliable" .. tostring(PolicyDBPath))
  end
  os.execute(" sleep 2 ")
  local defaultGroup = "sqlite3 " .. tostring(PolicyDBPath) .. " \"SELECT functional_group_id FROM app_group WHERE application_id = 'default'\""
  local aHandle = assert( io.popen( defaultGroup, 'r'))
  local defaultGroupValue = aHandle:read( '*l' )
  local defaultAppGroup = "sqlite3 " .. tostring(PolicyDBPath) .. " \"SELECT functional_group_id FROM app_group WHERE application_id = '"..tostring(config.application1.registerAppInterfaceParams.appID).."'\""
  local bHandle = assert( io.popen( defaultAppGroup, 'r'))
  local defaultAppGroupValue = bHandle:read( '*l' )
if defaultAppGroupValue == nil then
      os.execute(" sleep 200 ")
      defaultAppGroupValue = bHandle:read( '*l' )
     self:FailTestCase("Value in DB is unexpected value " .. tostring(defaultAppGroupValue))
  elseif 
     defaultGroupValue ~= defaultAppGroupValue then
    self:FailTestCase("Value in DB is unexpected value " .. tostring(defaultAppGroupValue))
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

Test["ForceKill"] = function (self)
os.execute("ps aux | grep smart | awk \'{print $2}\' | xargs kill -9")
os.execute("sleep 1")

return Test
end
