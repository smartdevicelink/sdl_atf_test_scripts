-- Requirement summary:
-- [PTU-Proprietary] Respond to SDL.GetURLs request from HMI
--
-- Description:
-- In case
-- SDL is built with "DEXTENDED_POLICY: ON" "-DEXTENDED_POLICY: PROPRIETARY" flag or without this flag at all,
-- and SDL gets SDL.GetURLs (service: 7) from HMI
-- SDL must
-- respond SDL.GetURLs_response (SUCCESS, urls: array(<SDL-chosen appID> + <url from policy database for service 7>)) to HMI.
--
-- Performed steps
-- 1. Register new app -> PTU sequence started
-- 2. hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
--
-- Expected result:
-- respond SDL.GetURLs_response (SUCCESS, urls: array(<SDL-chosen appID> + <url from policy database for service 7>)) to HMI
---------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local mobileSession = require("mobile_session")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ General Settings for configuration ]]
Test = require("user_modules/connecttest_resumption")
require("user_modules/AppTypes")
config.defaultProtocolVersion = 2

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:ConnectMobile()
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    {
      deviceList = {
        {
          id = utils.getDeviceMAC(),
          name = utils.getDeviceName(),
          transportType = "WIFI"
        }
      }
    })
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(AtLeast(1))
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:RegisterApp()
  self.mobileSession = mobileSession.MobileSession(self, self.mobileConnection)
  self.mobileSession:StartService(7)
  :Do(function()
      local RequestIDRai1 = self.mobileSession:SendRPC("RegisterAppInterface", config.application1.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID = data.params.application.appID
        end)
      self.mobileSession:ExpectResponse(RequestIDRai1, { success = true, resultCode = "SUCCESS" })
      self.mobileSession:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function()
      local requestId = self.hmiConnection:SendRequest("SDL.GetURLS", { service = 7 })
      EXPECT_HMIRESPONSE(requestId)
      :ValidIf(function(_, d)
          local r_expected = commonFunctions.getURLs("0x07")[1]
          local r_actual = d.result.urls[1].url
          if r_expected ~= r_actual then
            local msg = table.concat({"\nExpected: ", r_expected, "\nActual: ", tostring(r_actual)})
            return false, msg
          end
          return true
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postconditions_StopSDL()
  StopSDL()
end

return Test
