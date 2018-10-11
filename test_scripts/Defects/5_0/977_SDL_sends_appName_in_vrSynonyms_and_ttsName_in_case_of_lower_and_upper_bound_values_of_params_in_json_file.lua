---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/977
-- Description:
-- SDL does not process required language struct in jsons for SDL4.0 feature
-- Precondition:
-- SDL4.0 feature is enabled in .ini file, SDL and HMI are started.
-- In case:
-- 1) Register app via 4th protocol.
-- 2) App sends via SystemRequest json file JSONWithLanguageDefaultVrTtsLowerBound.json
-- JSONWithLanguageDefaultVrTtsUpperBound.json
-- Expected result:
-- 1) SDL sends in BC.UpdateAppList values of vrSynonyms and ttsName from json file
-- Actual result:
-- 1) SDL sends in BC.UpdateAppList in vrSynonyms and ttsName value of appName
-- Notes: To reproduce defect using ATF extract attached files in 'ATF_build/'
-- folder and execute TtsNameVrSyn_lower_bound_language.lua.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local tcp = require('tcp_connection')
local file_connection  = require('file_connection')
local mobile_session = require('mobile_session')
local test = require("user_modules/dummy_connecttest")
local mobile = require('mobile_connection')
local events = require('events')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
config.defaultProtocolVersion = 4
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

local pFiles = {
    "JSONWithLanguageDefaultVrTtsLowerBound.json",
    "JSONWithLanguageDefaultVrTtsUpperBound.json"
}

--[[ Local Functions ]]
local function StartWithoutMobile()
    local event = events.Event()
    event.matches = function(e1, e2) return e1 == e2 end
    test:runSDL()
    commonFunctions:waitForSDLStart(test)
    :Do(function()
        test:initHMI()
        :Do(function()
            utils.cprint(35, "HMI initialized")
            test:initHMI_onReady()
            :Do(function()
                utils.cprint(35, "HMI is ready")
                common.getHMIConnection():RaiseEvent(event, "Start event")
                end)
            end)
        end)
    return common.getHMIConnection():ExpectEvent(event, "Start event")
end

local function CreateMobileConnectionCreateSession()
    local tcpConnection = tcp.Connection(config.mobileHost, config.mobilePort)
    local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
    test.mobileConnection = mobile.MobileConnection(fileConnection)
    test.mobileSession[1] = mobile_session.MobileSession(test, test.mobileConnection)
    test.mobileSession[1].activateHeartbeat = false
    event_dispatcher:AddConnection(test.mobileConnection)
    test.mobileSession[1]:ExpectEvent(events.connectedEvent, "Connection 1 started")
    test.mobileConnection:Connect()
    test.mobileSession[1]:StartService(7)
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
        {
        deviceList = {
            {
                name = config.mobileHost .. ":" .. config.mobilePort
            }
        }
    })
    :Do(function(_,data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

local function RegisterAppWithOnSystemRequestQueryApps(pParams)
    local pAppId = 1
    local corId = common.getMobileSession(pAppId):SendRPC("RegisterAppInterface", common.getConfigAppParams(pAppId))
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppRegistered",
        { application = { appName = common.getConfigAppParams(pAppId).appName } })
    common.getMobileSession(pAppId):ExpectResponse(corId, { success = true, resultCode = "SUCCESS" })
    :Do(function()
    common.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
        { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
        :Do(function()
            local msg = {
                serviceType      = 7,
                frameInfo        = 0,
                rpcType          = 2,
                rpcFunctionId    = 32768,
                rpcCorrelationId = common.getMobileSession(pAppId).correlationId + 30,
                payload          = '{"hmiLevel":"FULL", "audioStreamingState":"NOT_AUDIBLE", "systemContext":"MAIN"}'
            }
            common.getMobileSession(pAppId):Send(msg)
        end)
    end)
    common.getMobileSession(pAppId):ExpectNotification("OnSystemRequest",
        {requestType = "LOCK_SCREEN_ICON_URL"},
        {requestType = "QUERY_APPS"})
    :Times(2)
    :Do(function(_, data)
        if data.payload.requestType == "QUERY_APPS" then
            local CorIdSystemRequest = common.getMobileSession(pAppId):SendRPC("SystemRequest",{
                requestType = "QUERY_APPS",
                fileName = pParams
            },
            "files/jsons/JSON_Language_parameter/" .. tostring(pParams))
            common.getMobileSession(pAppId):ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
        end
    end)
    EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :Do(function(_,data)
        common.getHMIConnection():SendResponse(data.id, "BasicCommunication.UpdateAppList", "SUCCESS", {})
    end)
end

local function UnregisterApp()
    local CorId = common.getMobileSession():SendRPC("UnregisterAppInterface",{})
    common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", {unexpectedDisconnect = false})
    common.getMobileSession():ExpectResponse(CorId, { success = true, resultCode = "SUCCESS"})
    :Timeout(2000)
    EXPECT_HMICALL("BasicCommunication.UpdateAppList")
    :Do(function(_,data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)

end

--[[ Scenario ]]
for _, v in pairs(pFiles) do
    runner.Title("Preconditions")
    runner.Step("Clean environment", common.preconditions)
    runner.Step("Start SDL, HMI", StartWithoutMobile)
    runner.Step("Create mobile connection and session", CreateMobileConnectionCreateSession)

    runner.Title("Test")
    runner.Step("Register App with OnSystemRequest Query_Apps " .. _, RegisterAppWithOnSystemRequestQueryApps, {v})
    runner.Step("Mobile app unregistered", UnregisterApp)

    runner.Title("Postconditions")
    runner.Step("Stop SDL", common.postconditions)
end
