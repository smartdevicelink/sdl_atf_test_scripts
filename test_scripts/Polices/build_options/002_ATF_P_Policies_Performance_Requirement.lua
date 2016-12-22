-- Requirement summary:
-- [General] Policies performance requirement
--
-- Communication of Policy manager and mobile device must not make discernible difference in system operation.
-- Execution of any other operation between SDL and mobile app is possible and has no discernibly more latency.
--(Assumption: here is assumed that mobile app sends PTS(Policy Table Snapshot) and receives PTU(Policy Table Update) from backend in separate thread,
-- i.e. mobile app is not blocked for other operations while waiting response from backend for updated Policy Table)
--
-- Description:
-- 1. SDL started PTU
-- 2. Mobile waiting response from backend, in that time sent RPC
-- Expected result
-- SDL must correctly finish the PTU

-----------------------------------------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General Precondition before ATF start]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require('connecttest')

--[[ Local Functions ]]
local function policyUpdateWithRCP_Before_SystemRequest(self)
  local pathToSnaphot = "files/ptu.json"
  local RequestIdGetURLS = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestIdGetURLS)
  :Do(function(_,_)
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        {
          requestType = "PROPRIETARY",
          appID = self.applications ["Test Application"],
          fileName = "PTU"
        }
      )
    end)
  EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY" })
  :Do(function(_,_)
      local CorIdSystemRequest = self.mobileSession:SendRPC ("SystemRequest",
        {
          requestType = "PROPRIETARY",
          fileName = "PTU"
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
      :Do(function(_,_)
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate",
            {
              policyfile = "/tmp/fs/mp/images/ivsu_cache/PTU"
            })
        end)
      :Do(function(_,_)
          EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UP_TO_DATE"})
        end)
    end)
end

--[[Test]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_Initiate_PTU_with_AlertRPC_Before_SystemRequest()
  policyUpdateWithRCP_Before_SystemRequest(self)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test:Postcondition_Force_Stop_SDL()
  commonFunctions:SDLForceStop(self)
end

return Test

