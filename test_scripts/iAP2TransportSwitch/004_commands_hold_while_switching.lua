---------------------------------------------------------------------------------------------------
--  Requirement summary:
--  TBD
--
--  Description:
--  iAP2 Bluetooth connection is switched to iAP2 USB connection automatically, application(s) remains registered
--
--  1. Used precondition
--  SDL is built with BUILD_TEST = ON to enable iAP2 BT/USB transport adapter emulation
--  SDL, HMI are running on system.
--
--  2. Performed steps
--  iAP2 Bluetooth mobile device connects to system
--  appID_1->RegisterAppInterface(params)
--  RAI response is SUCCESS
--
--  same iAP2 mobile device is connected over USB to system and re-registers within AppTransportChangeTimer timeout
--  appID_1->RegisterAppInterface(params)
--
--  Expected behavior:
--  1. SDL successfully registers application and notifies HMI and mobile
--     SDL->HMI: OnAppRegistered(params)
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--
--  2. SDL successfully registers application and notifies mobile only with RAI response
--     SDL->appID: SUCCESS, success:"true":RegisterAppInterface()
--     application remains registered internally
--     application does not send OnAppUnregistered notification to HMI
--     application does not send OnAppRegistered notification to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/iAP2TransportSwitch/common')
local mobSession = require("mobile_session")

--[[ Local Variables ]]
local deviceBluetooth
local sessionBluetooth
local sessionUsb
local hmiAppId
local hmiRequestId
local lastHashID

--[[ Local Functions ]]
local function connectBluetoothDevice(self)
  deviceBluetooth = self:createIAP2Device(common.device.bluetooth.id,
    common.device.bluetooth.port, common.device.bluetooth.out)

  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", {
    deviceList = {
      {
        id = config.deviceMAC,
        name = common.device.bluetooth.uid,
        transportType = common.device.bluetooth.type
      }
    }
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  self:connectMobile(deviceBluetooth)
  :Do(function()
      sessionBluetooth = mobSession.MobileSession(self, deviceBluetooth, common.appParams)
      sessionBluetooth:StartService(7)
      :Do(function()
          local cid = sessionBluetooth:SendRPC("RegisterAppInterface", common.appParams)
          sessionBluetooth:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
        end)
      EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered")
      :Do(function(_, data)
          hmiAppId = data.params.application.appID
        end)
    end)
end


local function addVehicleInfoSubscription(self)
  local cid = sessionBluetooth:SendRPC("SubscribeVehicleData", { odometer = true })
  EXPECT_HMICALL("VehicleInfo.SubscribeVehicleData")
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)
  sessionBluetooth:ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  sessionBluetooth:ExpectNotification("OnHashChange")
  :Do(function(_, data)
    lastHashID = data.payload.hashID
    print("Last hash "..lastHashID)
  end)
end

local function connectUSBDevice(self)
  local deviceUsb = self:createIAP2Device(common.device.usb.id,
    common.device.usb.port, common.device.usb.out)

  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered"):Times(0)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppRegistered"):Times(0)
  EXPECT_HMICALL("BasicCommunication.UpdateAppList"):Times(0)

  local is_switching_done = false

  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", {
    deviceList = {
      {
        id = config.deviceMAC,
        name = common.device.usb.uid,
        transportType = common.device.usb.type
      },
      {
        id = config.deviceMAC,
        name = common.device.bluetooth.uid,
        transportType = common.device.bluetooth.type
      }
    }
  },
  {
    deviceList = {
      {
        id = config.deviceMAC,
        name = common.device.usb.uid,
        transportType = common.device.usb.type
      }
    }
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

      if not is_switching_done then
        self:doTransportSwitch(deviceBluetooth)
        is_switching_done = true
      else
        sessionUsb = mobSession.MobileSession(self, deviceUsb, common.appParams)
      end

      return true
    end)
  :Times(2)

  self:connectMobile(deviceUsb)

  self:waitForAllEvents(1000)
end


local function sendRequestFromHMI(self)
  hmiRequestId = self.hmiConnection:SendRequest("SDL.ActivateApp", { appID = hmiAppId })
  EXPECT_HMIRESPONSE(hmiRequestId):Times(0)
  self:waitForAllEvents(1000)
end

local function sendNotificationFromHMI(self)
  self.hmiConnection:SendNotification("UI.OnDriverDistraction", { state = "DD_OFF" })
  sessionUsb:ExpectNotification("OnDriverDistraction"):Times(0)
  self:waitForAllEvents(1000)
end

local function sendResponseToHMI(self)
  local rpc_service_id = 7
  sessionUsb:StartService(rpc_service_id)
  :Do(function()
      common.appParams.hashID = lastHashID
      local correlationId = sessionUsb:SendRPC("RegisterAppInterface", common.appParams)
      sessionUsb:ExpectResponse(correlationId, { success = true, resultCode = "SUCCESS" })
    end)
  sessionUsb:ExpectNotification("OnDriverDistraction")
  EXPECT_HMIRESPONSE(hmiRequestId, { result = { code = 0, method = "SDL.ActivateApp" }})
  self:waitForAllEvents(1000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI", common.start)

runner.Title("Test")
runner.Step("Connect Bluetooth Device", connectBluetoothDevice)
runner.Step("Add VehicleInfoSubscription", addVehicleInfoSubscription)
runner.Step("Connect USB Device", connectUSBDevice)
runner.Step("Sending request from HMI, command hold expected", sendRequestFromHMI)
runner.Step("Sending notification from HMI, command hold expected", sendNotificationFromHMI)
runner.Step("Register app, response is sent to HMI", sendResponseToHMI)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
