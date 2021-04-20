---------------------------------------------------------------------------------------------------
-- https://github.com/smartdevicelink/sdl_core/issues/2430
--
-- 1) Update Core's ini with { MaxSupportedProtocolVersion = 2, MalformedMessageFiltering = false }
-- 2) Start SDL Core and connect a mobile app
-- 3) Activate mobile app
-- 4) Send an RPC using a protocol above 2
-- 5) App should be disconnected for protocol violation
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('user_modules/sequences/actions')
local runner = require('user_modules/script_runner')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local mobile_session = require('mobile_session')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Local Functions ]]
local function updateINIFile()
    commonFunctions:write_parameter_to_smart_device_link_ini("MaxSupportedProtocolVersion", 2)
    commonFunctions:write_parameter_to_smart_device_link_ini("MalformedMessageFiltering", "false")
end

local function sendMsgWithProtocolAboveMax()
    local msg = {
        version          = 3,
        serviceType      = 7,
        frameInfo        = 0,
        rpcType          = 0,
        rpcFunctionId    = 5,
        rpcCorrelationId = common.getMobileSession().correlationId + 1,					
        payload          = '{"cmdID":2,"vrCommands":["vrcmd2"],"menuParams":{"position":1000,"menuName":"cmd2"},"cmdIcon":{"value":"0xFF","imageType":"STATIC"}}'
    }
    common.getMobileSession():Send(msg)

    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { appID = common.getHMIAppId(), unexpectedDisconnect = false })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start, { updateINIFile() })
runner.Step("Register App", common.registerAppWOPTU)
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Send Message with protocol version above maximum", sendMsgWithProtocolAboveMax)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
