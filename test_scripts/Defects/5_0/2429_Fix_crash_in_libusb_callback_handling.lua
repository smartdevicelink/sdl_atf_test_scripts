---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2429
--
-- Description:
-- SDL must respond UNSUPPORTED_RESOURCE to mobile app in case SDL 4.0 feature is required to be ommited in implementation
-- Precondition:
-- SDLCore and HMI are started.
-- Start SDL with command ./smartDeviceLinkCore | grep -e '.eart.eat' to check heartbeat only
-- In case:
-- 1) Start application with "HeartBeat" is switched on
-- 2) Wait 30 minutes
-- Expected result:
-- 1) Application is registered
-- 2) Heartbeat is sent
-- 3) Connection is not closed by HB timeout reason.
-- 4) No core dumps
-- Actual result:
-- Connection is closed with core dump
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3

--[[ Local Functions ]]
local function heartbeatOn()
    commonFunctions:write_parameter_to_smart_device_link_ini("HeartBeatTimeout", 0)
end

local function wait30Minutes()
    commonTestCases:DelayedExp(1800000)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered",
    {appID = common.getHMIAppId(), unexpectedDisconnect = true}):Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("HeartBeat is switched on", heartbeatOn)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Wait 30 minutes", wait30Minutes)
runner.Step("Register App", common.activateApp)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
