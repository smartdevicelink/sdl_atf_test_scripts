---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] PoliciesManager changes status to “UPDATING”
-- [HMI API] OnStatusUpdate
--
-- Description:
-- PoliciesManager must change the status to “UPDATING” and notify HMI with
-- OnStatusUpdate("UPDATING") right after SnapshotPT is sent out to to mobile
-- app via OnSystemRequest() RPC.
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: EXTERNAL_PROPRIETARY" flag
-- Application is registered. Device is not consented
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- HMI->SDL: BasicCommunication.OnSystemRequest ('url', requestType:PROPRIETARY, appID="default")
-- SDL->app: OnSystemRequest ('url', requestType:PROPRIETARY, fileType="JSON", appID)
-- 2. Performed steps
--
-- Expected result:
-- SDL->HMI: SDL.OnStatusUpdate(UPDATING) right after SDL->app: OnSystemRequest
---------------------------------------------------------------------------------------------

--[[ General configuration parameters ]]
config.deviceMAC = "12ca17b49af2289436f303e0166030a21e525d266e209267433801a8fd4071a0"

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
testCasesForPolicyTable.Delete_Policy_table_snapshot()

--ToDo: shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('cardinalities')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")
function Test:Precondition_trigger_getting_device_consent()
  testCasesForPolicyTable:trigger_getting_device_consent(self, config.application1.registerAppInterfaceParams.appName, config.deviceMAC)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:TestStep_PoliciesManager_changes_status_UPDATING()
  local SystemFilesPath = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath")

  local RequestId_GetUrls = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
  EXPECT_HMIRESPONSE(RequestId_GetUrls,{result = {code = 0, method = "SDL.GetURLS" } } )
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",{ requestType = "PROPRIETARY", fileName = "PolicyTableUpdate"})
      EXPECT_HMINOTIFICATION("SDL.OnStatusUpdate", {status = "UPDATING"})
      EXPECT_NOTIFICATION("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function()
          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            {requestType = "PROPRIETARY", fileName = "PolicyTableUpdate", appID = config.application1.registerAppInterfaceParams.appID}, "files/ptu.json")
          EXPECT_HMICALL("BasicCommunication.SystemRequest",{ requestType = "PROPRIETARY", fileName = SystemFilesPath.."/PolicyTableUpdate" })
          :Do(function(_,_data1)
              self.hmiConnection:SendResponse(_data1.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
            end)
          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
