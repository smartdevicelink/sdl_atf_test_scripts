---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [GetStatusUpdate] Request from HMI
--
-- Description:
-- SDL must respond with the current update status code to HMI
-- In case HMI needs to find out current status of PTU and sends GetStatusRequest to SDL
--
-- Preconditions:
-- 1. Register app 123_xyz.
--
-- Steps:
-- 1. Allow SDL due to activation of app 123_xyz
-- 2. HMI -> SDL: Send GetStatusUpdate() and verify status of response
-- 3. Verify that PTU sequence is started
-- 4. HMI -> SDL: Send GetStatusUpdate() and verify status of response
-- 5. Verify that PTU sequence is finished
-- 6. HMI -> SDL: Send GetStatusUpdate() and verify status of response
--
-- Expected result:
-- 2. Status: UPDATE_NEEDED
-- 4. Status: UPDATING
-- 6. Status: UP_TO_DATE
---------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("connecttest")
require("user_modules/AppTypes")

-- --[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:Test_1_UPDATE_NEEDED()
  local requestId1 = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.applications["Test Application"] })
  EXPECT_HMIRESPONSE(requestId1)
  :Do(function(_, data1)
      if data1.result.isSDLAllowed ~= true then
        local requestId2 = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage",
          { language = "EN-US", messageCodes = { "DataConsent" } })
        EXPECT_HMIRESPONSE(requestId2)
        :Do(function()
            self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
              { allowed = true, source = "GUI", device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() } })

            local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
            EXPECT_HMIRESPONSE(reqId, { status = "UPDATE_NEEDED" })

            EXPECT_HMICALL("BasicCommunication.ActivateApp")
            :Do(function(_, data2)
                self.hmiConnection:SendResponse(data2.id,"BasicCommunication.ActivateApp", "SUCCESS", { })
              end)
          end)
      end
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", { hmiLevel = "FULL" })
end

function Test:Test_2_UPDATING()
  local policy_file_path = "/tmp/fs/mp/images/ivsu_cache/"
  local policy_file_name = "PolicyTableUpdate"
  local ptu_file = "files/ptu_general.json"
  local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(requestId)
  self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_name})
  EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
  :Do(function()
      local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
      EXPECT_HMIRESPONSE(reqId, { status = "UPDATING" })
      local corIdSystemRequest = self.mobileSession:SendRPC("SystemRequest", { requestType = "PROPRIETARY", fileName = policy_file_name }, ptu_file)
      EXPECT_HMICALL("BasicCommunication.SystemRequest")
      :Do(function(_, data)
          self.hmiConnection:SendResponse(data.id, "BasicCommunication.SystemRequest", "SUCCESS", {})
          self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = policy_file_path .. policy_file_name })
        end)
      EXPECT_RESPONSE(corIdSystemRequest, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          requestId = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", { language = "EN-US", messageCodes = { "StatusUpToDate" }})
          EXPECT_HMIRESPONSE(requestId)
        end)
    end)
end

function Test:Test_3_UP_TO_DATE()
  local reqId = self.hmiConnection:SendRequest("SDL.GetStatusUpdate")
  EXPECT_HMIRESPONSE(reqId, {status = "UP_TO_DATE"})
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
