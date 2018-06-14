---------------------------------------------------------------------------------------------------------------------
-- User story: https://github.com/SmartDeviceLink/sdl_core/issues/1209
---------------------------------------------------------------------------------------------------------------------
-- Precondition:
-- SDL is built with EXTERNAL_PROPRIETARY flag
-- SDL and HMI are started. First ignition cycle
-- Connect device 1
-- Description:
-- Steps to reproduce:
-- 1) Register new application 1
-- 2) Activate application 1 with consent Device 1 (SDL functionality is allowed)
-- 3) Connect device 2
-- 4) Register new application 2
-- 5) Activate application 2 without consent Device 2 (SDL functionality is not allowed)
-- 6) Perform PTU
-- Expected:
-- 1) PoliciesManager must initiate the PT Update through the app from consented device.
---------------------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local actions = require("user_modules/sequences/actions")
local test = require("user_modules/dummy_connecttest")
local mobile_session = require("mobile_session")
local utils = require ('user_modules/utils')
local events = require('events')
local tcp = require('tcp_connection')
local file_connection = require('file_connection')
local mobile = require('mobile_connection')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
-- Create dummy connection
os.execute("ifconfig lo:1 1.0.0.1")

--[[ Local variables ]]
local mobileHost = "1.0.0.1"
local getDeviceName = mobileHost .. ":" .. config.mobilePort

local function getDeviceMACsecondDevice()
  local cmd = "echo -n " .. getDeviceName .. " | sha256sum | awk '{printf $1}'"
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

local function allow_device_1()
  test.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
end

local function connect_device_2()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    { deviceList = {
        {
          id = getDeviceMACsecondDevice(),
          name = getDeviceName,
          transportType = "WIFI"
        },
        {
          id = utils.getDeviceMAC(),
          name = utils.getDeviceName(),
          transportType = "WIFI"
        }
      }
    }
  ):Do(function(_, data)
    test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  local tcpConnection = tcp.Connection(mobileHost, config.mobilePort)
  local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
  test.connection2 = mobile.MobileConnection(fileConnection)
  test.mobileSession2 = mobile_session.MobileSession(test, test.connection2)
  event_dispatcher:AddConnection(test.connection2)
  test.mobileSession2:ExpectEvent(events.connectedEvent, "Connection started")
  test.connection2:Connect()
end

local function register_app_2()
  test.mobileSession2:StartService(7)
  :Do(function()
    local RaiIdSecond = test.mobileSession2:SendRPC("RegisterAppInterface",
      config.application2.registerAppInterfaceParams)
    EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
    :Do(function(_,data)
        test.HMIAppID2 = data.params.application.appID
      end)
    test.mobileSession2:ExpectResponse(RaiIdSecond, { success = true, resultCode = "SUCCESS"})
    test.mobileSession2:ExpectNotification("OnHMIStatus",
      {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
  end)
end

local function allow_device_2()
  test.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = getDeviceMACsecondDevice(),
      name = getDeviceName
    }
  })
end

local function start_PTU()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function()
    test.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
      { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate", appID = test.HMIAppID })
    actions.getMobileSession():ExpectNotification("OnSystemRequest", {requestType = "PROPRIETARY"})
    :Times(1)
    test.mobileSession2:ExpectNotification("OnSystemRequest", {requestType = "PROPRIETARY"})
    :Times(0)
    :Do(function(_, data)
        test.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end)
end

local function activate_app_2()
  local RequestId = test.hmiConnection:SendRequest("SDL.ActivateApp", { appID = test.HMIAppID2})
  EXPECT_HMIRESPONSE(RequestId)
  actions.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "BACKGROUND", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  test.mobileSession2:ExpectNotification("OnHMIStatus",
    {hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN"})
  start_PTU()
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", actions.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", actions.start)
runner.Step("Register app_1 from device_1", actions.registerAppWOPTU)
runner.Step("Allow device_1", allow_device_1)
runner.Step("Activate app1", actions.activateApp)

runner.Title("Test")
runner.Step("Connect device_2", connect_device_2)
runner.Step("Register app_2", register_app_2)
runner.Step("Allow device_2", allow_device_2)
runner.Step("Activate app_2,PTU", activate_app_2)

runner.Title("Postconditions")
runner.Step("Stop SDL", actions.postconditions)
