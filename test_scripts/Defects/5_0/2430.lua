---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/2430
--
-- Description:
-- Fix messages protocol version check
-- Precondition:
-- "MaxSupportedProtocolVersion" = 2 in .ini file
-- MalformedMessageFiltering = false in .ini file
-- Max protocol version of mobile app is v2
-- "HeartBeat" is default in .ini. file (5000 ms)
-- In case:
-- 1) Open SPT
-- 2) Register App with Maximum Protocol Version is 2
-- 3) Select "Malformed Message" in App's menu
-- 4) Set "Protocol": 03
-- 5) Press "Send" button
-- 6)     Press "Close" button
-- Expected result:
-- 1) SDL should consider such message as malformed message then disconnect connection with app
-- Actual result:
-- SDL does not consider such message as malformed message and connection with app still alive.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local test = require("user_modules/dummy_connecttest")
local mobile_session = require('mobile_session')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local utils = require("user_modules/utils")
local constants = require('protocol_handler/ford_protocol_constants')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Local Variables ]]

--[[ Local Functions ]]
local function updateINIFile()
    commonFunctions:write_parameter_to_smart_device_link_ini("MaxSupportedProtocolVersion", 2)
    commonFunctions:write_parameter_to_smart_device_link_ini("MalformedMessageFiltering", "false")
    commonFunctions:write_parameter_to_smart_device_link_ini("HeartBeatTimeout", 5000)
end

local function malformedMessage()
    common.getMobileSession():Send({
        frameType = constants.FRAME_TYPE.CONTROL_FRAME,
        serviceType = constants.SERVICE_TYPE.CONTROL,
        frameInfo = constants.FRAME_INFO.HEARTBEAT,
        varsion = 3
    })
    -- common.getMobileSession()
end

local function unregisteredApp()
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { appID = common.getHMIAppId(), unexpectedDisconnect = false })
    common.getMobileSession():ExpectNotification("OnAppInterfaceUnregistered", {{reason = "PROTOCOL_VIOLATION"}})
    -- test.mobileConnection:Close()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { updateINIFile() })
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("malformedMessage", malformedMessage)
runner.Step("unregisteredApp", unregisteredApp)
-- runner.Step("Register App", common.registerAppWOPTU)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)