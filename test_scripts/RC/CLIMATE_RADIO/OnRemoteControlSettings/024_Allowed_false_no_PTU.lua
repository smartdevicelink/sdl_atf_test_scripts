---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_requirements/issues/11
-- Use case: https://github.com/smartdevicelink/sdl_requirements/blob/master/detailed_docs/rc_enabling_disabling.md
-- Item: Use Case 1: Main Flow (updates https://github.com/smartdevicelink/sdl_core/issues/2173)
--
-- Requirement summary:
-- [SDL_RC] Resource allocation based on access mode
--
-- Description:
-- In case:
-- SDL received OnRemoteControlSettings (allowed:false) from HMI
--
-- SDL must:
-- 1) store RC state allowed:false internally
-- 2) assign HMILevel none to all registered applications with appHMIType REMOTE_CONTROL
-- 3) keep all applications with appHMIType REMOTE_CONTROL registered and in current HMI levels
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local mobile_session = require("mobile_session")

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application3.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Variables ]]
local hmiAppIds = { }

--[[ Local Functions ]]
local function register_app(pAppId, self)
  self["mobileSession" .. pAppId] = mobile_session.MobileSession(self, self.mobileConnection)
  self["mobileSession" .. pAppId]:StartService(7)
  :Do(function()
      local corId = self["mobileSession" .. pAppId]:SendRPC("RegisterAppInterface",
        config["application" .. pAppId].registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered",
        { application = { appName = config["application" .. pAppId].registerAppInterfaceParams.appName } })
      :Do(function(_, d1)
          hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID] = d1.params.application.appID
        end)
      self["mobileSession" .. pAppId]:ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
      :Do(function()
          self["mobileSession" .. pAppId]:ExpectNotification("OnHMIStatus",
            { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
          :Times(AtLeast(1)) -- issue with SDL --> notification is sent twice
          self["mobileSession" .. pAppId]:ExpectNotification("OnPermissionsChange")
        end)
    end)
end

local function activate_app(pAppId, self)
  local requestId = self.hmiConnection:SendRequest("SDL.ActivateApp",
    { appID = hmiAppIds[config["application" .. pAppId].registerAppInterfaceParams.appID] })
  EXPECT_HMIRESPONSE(requestId)

  self["mobileSession" .. pAppId]:ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" })
  commonTestCases:DelayedExp(commonRC.minTimeout)
end

local function disableRCFromHMI(self)
  commonRC.defineRAMode(false, nil, self)

  self.mobileSession1:ExpectNotification("OnHMIStatus")
  :Times(0)
  self.mobileSession2:ExpectNotification("OnHMIStatus")
  :Times(0)
  self.mobileSession3:ExpectNotification("OnHMIStatus")
  :Times(0)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered")
  :Times(0)
  commonTestCases:DelayedExp(commonRC.timeout)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)

for i = 1, 3 do
  runner.Step("RAI " .. i, register_app, { i })
  runner.Step("Activate App " .. i, activate_app, { i })
end

runner.Title("Test")
runner.Step("Disable RC from HMI", disableRCFromHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)
