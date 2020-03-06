---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU-Proprietary] Transfer SystemRequest from mobile app to HMI
--
-- Description:
-- 1. Used preconditions: SDL is built with "DEXTENDED_POLICY: ON" flag. Trigger for PTU occurs
-- 2. Performed steps:
-- MOB->SDL: SystemRequest(PROPRIETARY, filename)
-- SDL->HMI: BasicCommunication.SystemRequest (PROPRIETARY, filename, appID)
--
-- Expected result:
-- SDL must send BasicCommunication.SystemRequest (<path to UpdatedPT>, PROPRIETARY, params) to HMI
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ Local Variables ]]
local BasicCommunicationSystemRequestData
local testData = {
  fileName = "PTUpdate",
  requestType = "PROPRIETARY",
  ivsuPath = "/tmp/fs/mp/images/ivsu_cache/"
}

--[[ General Settings for configuration ]]
Test = require('connecttest')
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Update_Policy()
  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId, { result = { code = 0, method = "SDL.GetPolicyConfigurationData" }})
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {requestType = "PROPRIETARY", fileName = testData.fileName})
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function()
          self.mobileSession:SendRPC("SystemRequest",
            {
              fileName = testData.fileName,
              requestType = "PROPRIETARY"
            }, "files/ptu.json")
          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              BasicCommunicationSystemRequestData = data
            end)
        end)
    end)
end

function Test:TestStep_Check_BC_SystemRequest()
  local filePath = testData.ivsuPath .. testData.fileName
  if BasicCommunicationSystemRequestData.params.fileName ~= filePath or
  BasicCommunicationSystemRequestData.params.requestType ~= testData.requestType then
    self.FailTestCase("Data of BC.SystemRequest is incorrect")
  end
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_ForceStopSDL()
  StopSDL()
end

return Test
