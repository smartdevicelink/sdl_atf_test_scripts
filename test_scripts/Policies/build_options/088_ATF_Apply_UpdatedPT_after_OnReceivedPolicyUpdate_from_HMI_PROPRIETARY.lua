---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PTU-Proprietary] Transfer SystemRequest_response from HMI to mobile app
--
-- Description:
-- 1. Used preconditions: SDL is built with "DEXTENDED_POLICY: PROPRIETARY" flag. Trigger for PTU occurs
-- 2. Performed steps:
-- MOB->SDL: SystemRequest(PROPRIETARY, filename)
-- HMI->SDL: BasicCommunication.SystemRequest (<resultCode>)
-- HMI->SDL: SDL.OnReceivedPolicyUpdate (policyFile)
--
-- Expected result:
-- SDL->MOB: BasicCommunication.SystemRequest (<result code from HMI responce)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require("mobile_session")
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFiles()
commonSteps:DeletePolicyTable()

--[[ Local Variables ]]
local testData = {
  fileName = "PTUpdate",
  requestType = "PROPRIETARY",
  ivsuPath = "/tmp/fs/mp/images/ivsu_cache/"
}

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require('user_modules/AppTypes')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
end

function Test:StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

function Test:RAI()
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", { application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(
    function()
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
    end)
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Update_Policy()
  local policy_file_path = commonFunctions:read_parameter_from_smart_device_link_ini("SystemFilesPath") .. "/"

  local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
      { policyType = "module_config", property = "endpoints" })
  EXPECT_HMIRESPONSE(requestId, { result = { code = 0, method = "SDL.GetPolicyConfigurationData" } })
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", {requestType = "PROPRIETARY", fileName = policy_file_path .. "sdl_snapshot.json"})
      EXPECT_NOTIFICATION("OnSystemRequest", { requestType = "PROPRIETARY" })
      :Do(function(_,d1)
          if not (d1.binaryData ~= nil and string.len(d1.binaryData) > 0) then
            self:FailTestCase("PTS was not sent to Mobile in payload of OnSystemRequest")
          end

          local CorIdSystemRequest = self.mobileSession:SendRPC("SystemRequest",
            {
              fileName = testData.fileName,
              requestType = "PROPRIETARY"
            }, "files/ptu.json")

          EXPECT_HMICALL("BasicCommunication.SystemRequest")
          :Do(function(_,data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.SystemRequest", "SUCCESS", {})
              self.hmiConnection:SendNotification("SDL.OnReceivedPolicyUpdate", { policyfile = testData.ivsuPath .. "/" .. testData.fileName })
            end)

          EXPECT_RESPONSE(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_ForceStopSDL()
  StopSDL()
end

return Test
