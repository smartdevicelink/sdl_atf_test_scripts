-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/966

-- Preconditions:
-- SDL4.0 feature is enabled in .ini file,
-- SDL and HMI are started. App app_1 is registered
-- via 4th on first device,has already received
-- OnSystemRequest(Query_apps)and sent query json.

-- Steps to reproduce
-- Register app via 4th protocol on second device.

-- Expected result
-- After app is registered and sends to SDL OnHMIStatus(FULL)
-- SDL sends OnSystermRequest(Query_apps) notification to mobile
-- app on second device.

-- Actual result
-- SDL does not send OnSystermRequest(Query_apps) notification to mobile app on second device.

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

-- creation dummy connection for new device
os.execute("ifconfig lo:1 1.0.0.1")

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

config.defaultProtocolVersion = 4
config.application1.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

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

local function CreateFirstMobileConnectionCreateSession()
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

local function CreateSecondMobileConnectionCreateSession()
  local tcpConnection = tcp.Connection("1.0.0.1", config.mobilePort)
  local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
  test.mobileConnection2 = mobile.MobileConnection(fileConnection)
  test.mobileSession[2] = mobile_session.MobileSession(test, test.mobileConnection2)
  test.mobileSession[2].activateHeartbeat = false
  test.mobileSession[2].sendHeartbeatToSDL = false
  event_dispatcher:AddConnection(test.mobileConnection2)
  test.mobileSession[2]:ExpectEvent(events.connectedEvent, "Connection 2 started")
  test.mobileConnection2:Connect()
  test.mobileSession[2]:StartService(7)
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    {
      deviceList = {
        {
          name = "1.0.0.1" .. ":" .. config.mobilePort
        },
        {
          name = config.mobileHost .. ":" .. config.mobilePort
        }
      }
    })
  :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

local function RegisterAppWithOnSystemRequestQueryAppsOnFirstDevice()
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
            fileName = "correctJSON.json"
        },
        "files/jsons/QUERRY_jsons/correctJSON.json")
        common.getMobileSession(pAppId):ExpectResponse(CorIdSystemRequest, { success = true, resultCode = "SUCCESS"})
      end
    end)
end

local function RegisterAppWithOnSystemRequestQueryAppsOnSecondDevice()
  local pAppId = 2
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
            rpcCorrelationId = common.getMobileSession(pAppId).correlationId + 40,
            payload          = '{"hmiLevel":"FULL", "audioStreamingState":"NOT_AUDIBLE", "systemContext":"MAIN"}'
          }
          common.getMobileSession(pAppId):Send(msg)
        end)
    end)

  common.getMobileSession(pAppId):ExpectNotification("OnSystemRequest",
    {requestType = "LOCK_SCREEN_ICON_URL"},
    {requestType = "QUERY_APPS"})
  :Times(2)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, without Mobile", StartWithoutMobile)

-- [[ Test ]]
runner.Title("Test")
runner.Step("Create first mobile connection and session", CreateFirstMobileConnectionCreateSession)
runner.Step("Create second mobile connection and session", CreateSecondMobileConnectionCreateSession)
runner.Step("Register App with OnSystemRequest Query_Apps on First Device", RegisterAppWithOnSystemRequestQueryAppsOnFirstDevice)
runner.Step("Register App with OnSystemRequest Query_Apps on Second Device", RegisterAppWithOnSystemRequestQueryAppsOnSecondDevice)

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
