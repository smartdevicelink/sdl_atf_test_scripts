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

--[[ Conditions to skip test ]]
if config.defaultMobileAdapterType ~= "TCP" then
  runner.skipTest("Test is applicable only for TCP connection")
end

--[[ Local Variables ]]
local deviceBluetooth
local deviceBluetoothName = common.device.bluetooth.id..":"..common.device.bluetooth.port

--[[ Local Functions ]]
local function connectBluetoothDevice(self)
  deviceBluetooth = self:createIAP2Device(common.device.bluetooth.id,
    common.device.bluetooth.port, common.device.bluetooth.out)

  EXPECT_HMICALL("BasicCommunication.UpdateDeviceList", {
    deviceList = common.getUpdatedDeviceList({
      {
        id = config.deviceMAC,
        name = deviceBluetoothName,
        transportType = common.device.bluetooth.type
      }
    })
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
    end)

  self:connectMobile(deviceBluetooth)
  :Do(function()
      local sessionBluetooth = mobSession.MobileSession(self, deviceBluetooth, common.appParams)
      sessionBluetooth:Start()
      EXPECT_HMICALL("BasicCommunication.UpdateAppList")
      :Do(function(_, data)
          self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })
        end)
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
    deviceList = common.getUpdatedDeviceList({
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
    })
  },
  {
    deviceList = common.getUpdatedDeviceList({
      {
        id = config.deviceMAC,
        name = common.device.usb.uid,
        transportType = common.device.usb.type
      }
    })
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", { })

      if not is_switching_done then
        self:doTransportSwitch(deviceBluetooth)
        is_switching_done = true
      else
        local sessionUsb = mobSession.MobileSession(self, deviceUsb, common.appParams)
        sessionUsb:Start()
      end

      return true
    end)
  :Times(2)

  self:connectMobile(deviceUsb)

  self:waitForAllEvents(2000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI", common.start)

runner.Title("Test")
runner.Step("Connect Bluetooth Device", connectBluetoothDevice)
runner.Step("Connect USB Device", connectUSBDevice)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
