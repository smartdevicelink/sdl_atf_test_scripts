---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2429
--
-- Description:
-- Successful processing of Heartbeat messages during 5 minutes
-- In case:
-- 1) Application is registered
-- 2) "HeartBeat" is switched on
-- 3) Wait 5 minutes
-- SDL does:
-- a) send Heartbeat related messages
-- b) not close connection by HB timeout reason.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3
config.heartbeatTimeout = 100

--[[ Local Functions ]]
local function heartbeatOn()
  common.sdl.setSDLIniParameter("HeartBeatTimeout", 100)
end

local function wait5Minutes()
  common.getMobileSession():StopHeartbeat()
  utils.wait(30000)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
  { appID = common.getHMIAppId(), unexpectedDisconnect = true }):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("HeartBeat is switched on", heartbeatOn)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Wait 30 minutes", wait5Minutes)
runner.Step("Activate App", common.activateApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
