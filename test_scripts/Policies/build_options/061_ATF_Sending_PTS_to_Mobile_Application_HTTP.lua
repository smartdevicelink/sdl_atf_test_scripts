---------------------------------------------------------------------------------------------
-- Requirements summary:
-- [PolicyTableUpdate] Sending PTS to mobile application
--
-- Description:
-- SDL must send PTS snapshot as a binary data via OnSystemRequest mobile API
-- from the system to backend. The "url" PTS will be forwarded to and "timeout"
-- must be taken from the Local Policy Table
-- 1. Used preconditions
-- SDL is built with "-DEXTENDED_POLICY: HTTP" flag
-- Application is registered.
-- PTU is requested.
-- SDL->HMI: SDL.OnStatusUpdate(UPDATE_NEEDED)
-- SDL->HMI:SDL.PolicyUpdate(file, timeout, retry[])
-- HMI -> SDL: SDL.GetURLs (<service>)
-- 2. Performed steps
-- HMI->SDL:BasicCommunication.OnSystemRequest ('url', requestType:HTTP, appID)
--
-- Expected result:
-- SDL->app: OnSystemRequest ('url', requestType:HTTP, fileType="JSON", appID)
---------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "HTTP" } } })

--[[ Required Shared libraries ]]
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local testCasesForPolicyTable = require('user_modules/shared_testcases/testCasesForPolicyTable')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_ConnectMobile.lua")
--TODO: Should be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_ConnectMobile')
require('cardinalities')
require('user_modules/AppTypes')
local mobile_session = require('mobile_session')

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Connect_device()
  self:connectMobile()
end

function Test:Precondition_StartSession()
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Sending_PTS_to_mobile_application()
  local endpoints_url
  local timeout = 0

  self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered", {application = { appName = config.application1.registerAppInterfaceParams.appName } })
  :Do(function()
      local endpoints_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select url from endpoint where service = '0x07' and application_id = 'default'")
      for _,v in pairs(endpoints_table) do
        endpoints_url = v
      end

      local timeout_table = commonFunctions:get_data_policy_sql(config.pathToSDL.."/storage/policy.sqlite", "select timeout_after_x_seconds from module_config")
      for _,v in pairs(timeout_table) do
        timeout = v
      end
    end)

  EXPECT_NOTIFICATION("OnSystemRequest"): Times(2)
  :ValidIf(function(e, d)
      print("OnSystemRequest: " .. e.occurences .. ": " .. d.payload.requestType)
      if (e.occurences == 1) then
        return true
      elseif (e.occurences == 2) and (d.payload.requestType == "HTTP") then
        print("OnSystemRequest(HTTP) is sent to App")
        if (d.payload.url ~= endpoints_url) then
          return false, "Expected URL: " .. endpoints_url .. ", actual: " .. tostring(d.payload.url)
        end
        if (tostring(d.payload.timeout) ~= timeout) then
          return false, "Expected Timeout: " .. timeout .. ", actual: " .. tostring(d.payload.timeout)
        end
      else
        return false, "OnSystemRequest(HTTP) was not sent to App"
      end
      return true
    end)


end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
testCasesForPolicyTable:Restore_preloaded_pt()
function Test.Postcondition_Stop_SDL()
  StopSDL()
end

return Test
