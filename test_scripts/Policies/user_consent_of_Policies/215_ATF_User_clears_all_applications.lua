---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [Policies] <device identifier>. User clears all these applications
--
-- Description:
-- All applications from new device are successfully registered AND the User clears all these applications from the list of registered applications
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Connect new device
-- Register App1
-- Register App2
-- Unregister App1
-- Unregister App2
--
-- 2. Performed steps:
-- Connect second device
--
-- Expected result:
-- Device must be still visible by SDL and must NOT be removed from HMI`s list of connected devices:
-- SDL->HMI: BC.UpdateDeviceList(device1, device2)
-- HMI->SDL: BC.UpdateDeviceList(SUCCESS)
--------------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local utils = require ('user_modules/utils')

--[[ General Precondition before ATF start ]]
commonSteps:DeleteLogsFileAndPolicyTable()
commonPreconditions:Connecttest_without_ExitBySDLDisconnect_WithoutOpenConnectionRegisterApp("connecttest_connect_device.lua")
--TODO(istoimenova): shall be removed when issue: "ATF does not stop HB timers by closing session and connection" is fixed
config.defaultProtocolVersion = 2

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_connect_device')
require('cardinalities')
require('user_modules/AppTypes')

local mobile_session = require('mobile_session')
local tcp = require('tcp_connection')
local file_connection = require('file_connection')
local mobile = require('mobile_connection')
local events = require('events')

--[[ Local variables ]]
local deviceMAC2 = "54286cb92365be544aa7008b92854b9648072cf8d8b17b372fd0786bef69d7a2"
local mobileHost = "1.0.0.1"

-- Creation dummy connection
os.execute("ifconfig lo:1 1.0.0.1")

function Test:Precondition_Connect_device1()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    {
      deviceList = {
        {
          id = utils.getDeviceMAC(),
          name = utils.getDeviceName(),
          transportType = "WIFI",
          isSDLAllowed = false
        }
      }
    }
    ):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

function Test:Precondition_Register_app1()
  commonTestCases:DelayedExp(3000)
  self.mobileSession = mobile_session.MobileSession(self, self.mobileConnection)
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
end

function Test:Precondition_Register_app2()
  commonTestCases:DelayedExp(3000)
  self.mobileSession2 = mobile_session.MobileSession(self, self.mobileConnection)
  self.mobileSession2:StartService(7)
  :Do(function()
      local RequestIDRai2 = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID2 = data.params.application.appID
        end)
      self.mobileSession2:ExpectResponse(RequestIDRai2, { success = true, resultCode = "SUCCESS" })
      self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
end

function Test:Precondition_Unregister_app1()
  local cid = self.mobileSession:SendRPC("UnregisterAppInterface",{})
  self.mobileSession:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"} )
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.HMIAppID, unexpectedDisconnect = false})
end

function Test:Precondition_Unregister_app2()
  local cid = self.mobileSession2:SendRPC("UnregisterAppInterface",{})
  self.mobileSession2:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"} )
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = self.HMIAppID2, unexpectedDisconnect = false})
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")

function Test:TestStep_Check_two_devices_visible_on_device2_connect()
  local tcpConnection = tcp.Connection(mobileHost, config.mobilePort)
  local fileConnection = file_connection.FileConnection("mobile.out", tcpConnection)
  local connection = mobile.MobileConnection(fileConnection)
  event_dispatcher:AddConnection(connection)
  connection:Connect()
  local session = mobile_session.MobileSession(self, connection)
  session:ExpectEvent(events.connectedEvent, "Connection started")

  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    {
      deviceList = {
        {
          id = utils.getDeviceMAC(),
          name = utils.getDeviceName(),
          transportType = "WIFI",
          isSDLAllowed = false
        },
        {
          id = deviceMAC2,
          name = mobileHost,
          transportType = "WIFI",
          isSDLAllowed = false
        },
    }})
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")
function Test.Postcondition_Stop()
  StopSDL()
end

return Test
