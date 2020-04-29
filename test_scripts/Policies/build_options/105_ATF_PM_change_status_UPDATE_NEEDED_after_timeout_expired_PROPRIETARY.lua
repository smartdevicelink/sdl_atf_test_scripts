---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate][GENIVI] PoliciesManager changes status to “UPDATE_NEEDED”
--
-- Description:
-- SDL should request PTU in case new application is registered and is not listed in PT
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: PROPRIETARY" flag
-- Connect mobile phone over WiFi.
-- 2. Performed steps
-- Register new application
-- SDL-> <app ID> ->OnSystemRequest(params, url, )
-- Timeout expires
--
-- Expected result:
--SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "PROPRIETARY" } } })

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local mobile_session = require('mobile_session')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')

--[[ Local Functions ]]
local function timestamp()
  local f = io.popen("date +%s%3N")
  local o = f:read("*all")
  f:close()
  return (o:gsub("\n", ""))
end

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

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

--[[ Test ]]
commonFunctions:newTestCasesGroup ("Test")

function Test:RAI_PTU()
  local corId = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
  :Do(
    function()
      EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
      :Do(
        function(_, d)
          self.hmiConnection:SendResponse(d.id, d.method, "SUCCESS", { })
          local requestId = self.hmiConnection:SendRequest("SDL.GetPolicyConfigurationData",
              { policyType = "module_config", property = "endpoints" })
          EXPECT_HMIRESPONSE(requestId)
          :Do(
            function()
              self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest", { requestType = "PROPRIETARY", fileName = "PTU" })
              self.mobileSession:ExpectNotification("OnSystemRequest", { requestType = "PROPRIETARY" })
              :DoOnce(
                function()
                  local OnSystemRequest_time = timestamp()
                  print("OnSystemRequest: " .. tostring(OnSystemRequest_time))
                  EXPECT_HMINOTIFICATION ("SDL.OnStatusUpdate", {status = "UPDATE_NEEDED"}, {status = "UPDATING"})
                  :ValidIf(
                    function()
                      local OnStatusUpdate_time = timestamp()
                      print("OnStatusUpdate: " .. tostring(OnStatusUpdate_time))
                      local diff = tonumber(OnStatusUpdate_time) - tonumber(OnSystemRequest_time)
                      print("Timeout: " .. diff .. " ms")
                      if diff >= 59500 and diff <= 60500 then
                        return true
                      else
                        return false, "Expected timeout '60000' ms, actual '" .. diff .. "' ms (tolerance = 500ms)"
                      end
                    end)
                  :Times(2)
                  :Timeout(63000)
                end)
              :Times(2)
              :Timeout(63000)
            end)
        end)
    end)
  self.mobileSession:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
  :Do(
    function()
      self.mobileSession:ExpectNotification("OnHMIStatus", { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
      self.mobileSession:ExpectNotification("OnPermissionsChange")
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test

