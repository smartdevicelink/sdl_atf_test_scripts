---------------------------------------------------------------------------------------------
-- Requirement summary:
-- [PolicyTableUpdate] PTU using consented device in case a user didn't consent the one which application required PTU
--
-- Description:
-- App that never received the updated policies registers from non-consented device and then the User does NOT consent this device
-- 1. Used preconditions:
-- Delete files and policy table from previous ignition cycle if any
-- Connect device1
-- Register and activate app1
-- Connect device2 and register app2
-- 2. Performed steps:
-- Register second app and don't consent second device
--
-- Expected result:
-- PoliciesManager must initiate the PT Update through the app from consented device,
-- second(non-consented) device should not be used e.i. no second query for user consent should be sent to HMI
---------------------------------------------------------------------------------------------------------------------
require('user_modules/script_runner').isTestApplicable({ { extendedPolicy = { "EXTERNAL_PROPRIETARY" } } })

--[[ General Settings for configuration ]]
Test = require('user_modules/connecttest_resumption')
require('cardinalities')
local mobile_session = require('mobile_session')
local mobile_adapter_controller = require("mobile_adapter/mobile_adapter_controller")
local file_connection = require('file_connection')
local mobile = require('mobile_connection')
local events = require('events')
local utils = require ('user_modules/utils')

--[[ General configuration parameters ]]
-- Create dummy connection
os.execute("ifconfig lo:1 1.0.0.1")

--[[ Required Shared libraries ]]
local commonFunctions = require ('user_modules/shared_testcases/commonFunctions')
local commonSteps = require('user_modules/shared_testcases/commonSteps')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')
require('user_modules/AppTypes')

--[[ General Precondition before ATF start ]]
commonFunctions:SDLForceStop()
commonSteps:DeleteLogsFileAndPolicyTable()

--[[ Local variables ]]
local mobileHost = "1.0.0.1"
local deviceMAC2 = "9cc72994ab9ca68c1daaf02834f7a94552e82aad3250778f2e12d14afee0a5c6"
local deviceName2 = mobileHost .. ":" .. config.mobilePort

--[[ Preconditions ]]
commonFunctions:newTestCasesGroup("Preconditions")

function Test:Precondition_Connect_device1()
  commonTestCases:DelayedExp(2000)
  self:connectMobile()
  if utils.getDeviceTransportType() == "WIFI" then
    EXPECT_HMICALL("BasicCommunication.UpdateDeviceList")
    :Do(function(_,data)
        self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
      end)
  end
end

function Test:Precondition_Register_app_1()
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

function Test:Precondition_Activate_app_1()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID})
  EXPECT_HMIRESPONSE(RequestId, {result = { code = 0, device = { id = utils.getDeviceMAC(), name = utils.getDeviceName() }, isSDLAllowed = false, method ="SDL.ActivateApp" }})
  :Do(function(_, _)
      local RequestIdGetMes = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetMes)
      :Do(function()
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = true, source = "GUI", device = {id = utils.getDeviceMAC(), name = utils.getDeviceName()}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_, data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          :Times(AtLeast(1))
        end)
    end)
  EXPECT_NOTIFICATION("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

function Test:Precondition_Connect_device_2()
  local mobileAdapter = self.getDefaultMobileAdapter(mobileHost, config.mobilePort)
  local fileConnection = file_connection.FileConnection("mobile.out", mobileAdapter)
  self.connection2 = mobile.MobileConnection(fileConnection)
  self.mobileSession2 = mobile_session.MobileSession(self, self.connection2)
  event_dispatcher:AddConnection(self.connection2)
  self.mobileSession2:ExpectEvent(events.connectedEvent, "Connection started")
  self.connection2:Connect()
  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList",
    {
      deviceList = {
        {
          id = deviceMAC2,
          name = deviceName2 ,
          transportType = utils.getDeviceTransportType()
        },
        {
          id = utils.getDeviceMAC(),
          name = utils.getDeviceName(),
          transportType = utils.getDeviceTransportType()
        },
        {
          transportType = "WEBENGINE_WEBSOCKET",
        }
      }
    }
    ):Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  :Times(AtLeast(1))
end

--[[ Test ]]
commonFunctions:newTestCasesGroup("Test")
function Test:Test_Register_app_2()
  self.mobileSession2:StartService(7)
  :Do(function()
      local RaiIdSecond = self.mobileSession2:SendRPC("RegisterAppInterface", config.application2.registerAppInterfaceParams)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_,data)
          self.HMIAppID2 = data.params.application.appID
        end)
      self.mobileSession2:ExpectResponse(RaiIdSecond, { success = true, resultCode = "SUCCESS"})
      self.mobileSession2:ExpectNotification("OnHMIStatus", {hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN"})
    end)
end

function Test:Teat_Activate_app_2()
  local RequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = self.HMIAppID2})
  EXPECT_HMIRESPONSE(RequestId, {result = { code = 0, device = { id = deviceMAC2, name = deviceName2 }, isSDLAllowed = false, method ="SDL.ActivateApp" }})
  :Do(function()
      local RequestIdGetMes = self.hmiConnection:SendRequest("SDL.GetUserFriendlyMessage", {language = "EN-US", messageCodes = {"DataConsent"}})
      EXPECT_HMIRESPONSE(RequestIdGetMes)
      :Do(function()
          self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality",
            {allowed = false, source = "GUI", device = {id = deviceMAC2, name = deviceName2}})
          EXPECT_HMICALL("BasicCommunication.ActivateApp")
          :Do(function(_, data)
              self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
            end)
          :Times(AtLeast(1))
        end)
    end)
end

function Test:Test_Start_PTU()
  EXPECT_HMICALL("BasicCommunication.PolicyUpdate")
  :Do(function()
      self.hmiConnection:SendNotification("BasicCommunication.OnSystemRequest",
        { requestType = "PROPRIETARY", fileName = "PolicyTableUpdate", appID = self.HMIAppID })
      self.mobileSession2:ExpectNotification("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Times(0)
      self.mobileSession:ExpectNotification("OnSystemRequest", {requestType = "PROPRIETARY"})
      :Do(function(_, data)
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
        end)
    end)
end

--[[ Postconditions ]]
commonFunctions:newTestCasesGroup("Postconditions")

function Test.Postcondition_SDLForceStop()
  StopSDL()
end
