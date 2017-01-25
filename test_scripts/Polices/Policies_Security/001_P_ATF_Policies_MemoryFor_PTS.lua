-- UNREADY---
-- Iliana as I understand, we need create a function witch will be return How much memory Policy Manager have.
-- I have problems with it. I just send sdl_preloaded json size near 1 mb, and done PTU with it. Please help me with this function for check avaliable memory.
-- Thanks a lot. Please rename attached ptu_1mb.json and copy this file on this way /tmp/fs/mp/images/ivsu_cache/,
-- And for run SDL use attached sdl_preloaded_pt.
--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Requirement summary:
-- [General] Policies enough memory for PTS

-- Description:
-- Before sending PTS via OnSystemRequest to mobile app, SDL checks to have available more than 1 Mbytes of allocated memory RAM.
-- Policies Manager must have enough memory to hold a Policy Table Snapshot in memory.
--

-- Performed steps
-- 1. MOB-SDL - register application
-- 2. SDL - start PTU
-- 3. Before OnSystemRequest SDL checks to have available more than 1 Mbytes of allocated memory RAM
-- 3. Finish PTU.

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[General Precondition before ATF start]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_GeneralSDLbehaviour_PTsize_1mb()
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

  :Do(function(_,_)
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

      EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
            {
              policyfile = "/tmp/fs/mp/images/ivsu_cache/ptu.json"
            })
        end)
      :Do(function(_,_)
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
Test["StopSDL"] = function()
  commonFunctions:userPrint(33, "Postcondition")
  StopSDL()
end
